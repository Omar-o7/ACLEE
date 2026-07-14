import 'dart:convert';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import '../core/constants/gamification.dart';

/// Central data layer — mirrors the web app's foodClient + server functions,
/// but AI calls go through Supabase Edge Functions (analyze-food / coach).
class SupabaseService {
  SupabaseService._();
  static final SupabaseService instance = SupabaseService._();

  SupabaseClient get _c => Supabase.instance.client;
  User? get user => _c.auth.currentUser;
  String get _uid => user!.id;

  // ── Auth ──────────────────────────────────────────────
  Future<void> signIn(String email, String password) =>
      _c.auth.signInWithPassword(email: email, password: password);

  Future<void> signUp(String name, String email, String password) =>
      _c.auth.signUp(email: email, password: password, data: {'name': name});

  Future<void> signOut() => _c.auth.signOut();

  // ── Profile ───────────────────────────────────────────
  Future<Profile?> getProfile() async {
    final data = await _c.from('profiles').select().eq('id', _uid).maybeSingle();
    return data == null ? null : Profile.fromJson(data);
  }

  Future<void> updateProfile({String? name, int? dailyCalorieGoal}) async {
    final patch = <String, dynamic>{};
    if (name != null) patch['name'] = name;
    if (dailyCalorieGoal != null) patch['daily_calorie_goal'] = dailyCalorieGoal;
    if (patch.isEmpty) return;
    await _c.from('profiles').update(patch).eq('id', _uid);
  }

  // ── Food logs ─────────────────────────────────────────
  Future<List<FoodLog>> logsBetween(DateTime start, DateTime end) async {
    final data = await _c
        .from('food_logs')
        .select()
        .gte('logged_at', start.toUtc().toIso8601String())
        .lt('logged_at', end.toUtc().toIso8601String())
        .order('logged_at', ascending: false);
    return (data as List).map((e) => FoodLog.fromJson(e)).toList();
  }

  Future<List<FoodLog>> todayLogs() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    return logsBetween(start, start.add(const Duration(days: 1)));
  }

  Future<void> deleteLog(String id) => _c.from('food_logs').delete().eq('id', id);

  Future<String?> uploadFoodImage(Uint8List bytes, String ext) async {
    try {
      final path = '$_uid/${DateTime.now().millisecondsSinceEpoch}.$ext';
      await _c.storage.from('food-images').uploadBinary(path, bytes,
          fileOptions: FileOptions(contentType: 'image/$ext', upsert: true));
      return _c.storage.from('food-images').getPublicUrl(path);
    } catch (_) {
      return null; // image is optional — never block logging on upload failure
    }
  }

  Future<void> logFood({
    required NutritionResult n,
    required String mealType,
    String? imageUrl,
  }) async {
    await _c.from('food_logs').insert({
      'user_id': _uid,
      'meal_type': mealType,
      'food_name': n.foodName,
      'calories': n.calories,
      'protein_g': n.proteinG,
      'carbs_g': n.carbsG,
      'fat_g': n.fatG,
      'fiber_g': n.fiberG,
      'serving_size': n.servingSize,
      'confidence_score': n.confidenceScore,
      'image_url': imageUrl,
    });
  }

  // ── Water ─────────────────────────────────────────────
  Future<int> todayWaterMl() async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final data = await _c.from('water_logs').select('amount_ml').eq('date', today);
    return (data as List).fold<int>(0, (s, r) => s + ((r['amount_ml'] as num?)?.toInt() ?? 0));
  }

  Future<void> addWater(int ml) async {
    await _c.from('water_logs').insert({'user_id': _uid, 'amount_ml': ml});
  }

  Future<void> undoLastWater() async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final last = await _c
        .from('water_logs')
        .select('id')
        .eq('date', today)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();
    if (last != null) await _c.from('water_logs').delete().eq('id', last['id']);
  }

  // ── Stats / gamification ──────────────────────────────
  Future<UserStats> getStats() async {
    final data = await _c.from('user_stats').select().eq('user_id', _uid).maybeSingle();
    if (data == null) {
      await _c.from('user_stats').upsert({'user_id': _uid});
      return UserStats();
    }
    return UserStats.fromJson(data);
  }

  /// Award points for a logged meal + update streak + level.
  /// Ported (simplified) from the server-side awardPoints function.
  Future<({int pointsEarned, bool leveledUp, String levelName})> awardMealPoints() async {
    final stats = await getStats();
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    int streak = stats.currentStreak;
    final last = stats.lastLogDate;
    if (last == null) {
      streak = 1;
    } else {
      final lastDate = DateTime(last.year, last.month, last.day);
      final diff = todayDate.difference(lastDate).inDays;
      if (diff == 1) streak += 1;
      if (diff > 1) streak = 1;
      if (diff == 0 && streak == 0) streak = 1;
    }

    const basePoints = 10;
    final streakBonus = streak >= 7 ? 10 : (streak >= 3 ? 5 : 0);
    final earned = basePoints + streakBonus;
    final newTotal = stats.totalPoints + earned;

    final oldLevel = levelForPoints(stats.totalPoints);
    final newLevel = levelForPoints(newTotal);

    final newBadges = List<String>.from(stats.badges);
    void unlock(String id) {
      if (!newBadges.contains(id)) newBadges.add(id);
    }

    unlock('first_snap');
    if (streak >= 3) unlock('on_fire');
    if (streak >= 7) unlock('week_warrior');
    if (streak >= 30) unlock('consistency_king');
    if (streak >= 60) unlock('unstoppable');

    await _c.from('user_stats').upsert({
      'user_id': _uid,
      'total_points': newTotal,
      'current_level': newLevel.id,
      'current_streak': streak,
      'longest_streak': streak > stats.longestStreak ? streak : stats.longestStreak,
      'last_log_date': todayDate.toIso8601String().substring(0, 10),
      'badges': newBadges,
    });

    return (
      pointsEarned: earned,
      leveledUp: newLevel.id != oldLevel.id,
      levelName: '${newLevel.emoji} ${newLevel.name}',
    );
  }

  // ── AI: analyze food image (Edge Function) ────────────
  Future<NutritionResult> analyzeFood(Uint8List imageBytes, String mimeType) async {
    final res = await _c.functions.invoke('analyze-food', body: {
      'imageBase64': base64Encode(imageBytes),
      'mimeType': mimeType,
    });
    final data = res.data is String ? jsonDecode(res.data as String) : res.data;
    if (data is Map && data['error'] != null) {
      throw Exception(data['error']);
    }
    return NutritionResult.fromJson(
        Map<String, dynamic>.from(data['nutrition'] as Map));
  }

  // ── AI: coach chat (Edge Function) ────────────────────
  Future<List<Map<String, dynamic>>> coachHistory() async {
    final data = await _c
        .from('coach_messages')
        .select()
        .order('created_at', ascending: true)
        .limit(100);
    return List<Map<String, dynamic>>.from(data as List);
  }

  Future<String> sendCoachMessage(String message, List<Map<String, String>> history) async {
    await _c.from('coach_messages').insert({'user_id': _uid, 'role': 'user', 'content': message});
    final res = await _c.functions.invoke('coach', body: {
      'message': message,
      'history': history,
    });
    final data = res.data is String ? jsonDecode(res.data as String) : res.data;
    if (data is Map && data['error'] != null) throw Exception(data['error']);
    final reply = (data['reply'] as String?) ?? '...';
    await _c.from('coach_messages').insert({'user_id': _uid, 'role': 'assistant', 'content': reply});
    return reply;
  }

  Future<void> clearCoachChat() =>
      _c.from('coach_messages').delete().eq('user_id', _uid);
}
