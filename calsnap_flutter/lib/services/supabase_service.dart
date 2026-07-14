import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import '../core/constants/gamification.dart';

/// In-memory data used by [SupabaseService] when [SupabaseService.demoMode]
/// is on, so the app can be explored without any real Supabase project.
class _DemoStore {
  final profile = Profile(
      id: 'demo-user', name: 'ضيف', email: 'demo@calsnap.app', dailyCalorieGoal: 2200);

  final logs = <FoodLog>[
    FoodLog(
      id: 'demo-1',
      foodName: 'شوفان بالتوت',
      mealType: 'breakfast',
      loggedAt: DateTime.now().subtract(const Duration(hours: 5)),
      calories: 320,
      proteinG: 12,
      carbsG: 54,
      fatG: 6,
      fiberG: 8,
      servingSize: 'وعاء واحد',
    ),
    FoodLog(
      id: 'demo-2',
      foodName: 'سلطة دجاج مشوي',
      mealType: 'lunch',
      loggedAt: DateTime.now().subtract(const Duration(hours: 2)),
      calories: 480,
      proteinG: 38,
      carbsG: 22,
      fatG: 20,
      fiberG: 6,
      servingSize: 'طبق واحد',
    ),
    FoodLog(
      id: 'demo-3',
      foodName: 'سلمون مع أرز',
      mealType: 'dinner',
      loggedAt: DateTime.now().subtract(const Duration(days: 1, hours: 3)),
      calories: 610,
      proteinG: 42,
      carbsG: 55,
      fatG: 18,
      fiberG: 4,
      servingSize: 'طبق واحد',
    ),
  ];

  int waterMl = 500;

  var stats = UserStats(
    totalPoints: 120,
    currentLevel: 'beginner',
    currentStreak: 3,
    longestStreak: 5,
    badges: const ['first_snap', 'on_fire'],
    lastLogDate: DateTime.now().subtract(const Duration(days: 1)),
  );

  final coachMsgs = <Map<String, dynamic>>[];
}

const _demoFoods = [
  (name: 'طبق فول بالخبز', serving: 'طبق واحد', cal: 380, p: 16.0, c: 48.0, f: 12.0, fi: 9.0),
  (name: 'برجر لحم مع بطاطا', serving: 'وجبة واحدة', cal: 720, p: 32.0, c: 60.0, f: 36.0, fi: 4.0),
  (name: 'طبق كينوا بالخضار', serving: 'طبق واحد', cal: 340, p: 11.0, c: 52.0, f: 9.0, fi: 8.0),
  (name: 'موز وتفاح', serving: 'حبتان', cal: 190, p: 1.5, c: 48.0, f: 0.6, fi: 6.0),
];

/// Central data layer — mirrors the web app's foodClient + server functions,
/// but AI calls go through Supabase Edge Functions (analyze-food / coach).
class SupabaseService {
  SupabaseService._();
  static final SupabaseService instance = SupabaseService._();

  /// When true, every method below returns/updates in-memory mock data
  /// instead of talking to Supabase. Set once at startup in main().
  static bool demoMode = false;
  static final _demo = _DemoStore();

  SupabaseClient get _c => Supabase.instance.client;
  User? get user => _c.auth.currentUser;
  String get _uid => user!.id;

  // ── Auth ──────────────────────────────────────────────
  Future<void> signIn(String email, String password) {
    if (demoMode) return Future.value();
    return _c.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signUp(String name, String email, String password) {
    if (demoMode) return Future.value();
    return _c.auth.signUp(email: email, password: password, data: {'name': name});
  }

  Future<void> signOut() {
    if (demoMode) return Future.value();
    return _c.auth.signOut();
  }

  // ── Profile ───────────────────────────────────────────
  Future<Profile?> getProfile() async {
    if (demoMode) return _demo.profile;
    final data = await _c.from('profiles').select().eq('id', _uid).maybeSingle();
    return data == null ? null : Profile.fromJson(data);
  }

  Future<void> updateProfile({String? name, int? dailyCalorieGoal}) async {
    if (demoMode) return;
    final patch = <String, dynamic>{};
    if (name != null) patch['name'] = name;
    if (dailyCalorieGoal != null) patch['daily_calorie_goal'] = dailyCalorieGoal;
    if (patch.isEmpty) return;
    await _c.from('profiles').update(patch).eq('id', _uid);
  }

  // ── Food logs ─────────────────────────────────────────
  Future<List<FoodLog>> logsBetween(DateTime start, DateTime end) async {
    if (demoMode) {
      return _demo.logs
          .where((l) => !l.loggedAt.isBefore(start) && l.loggedAt.isBefore(end))
          .toList()
        ..sort((a, b) => b.loggedAt.compareTo(a.loggedAt));
    }
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

  Future<void> deleteLog(String id) async {
    if (demoMode) {
      _demo.logs.removeWhere((l) => l.id == id);
      return;
    }
    await _c.from('food_logs').delete().eq('id', id);
  }

  Future<String?> uploadFoodImage(Uint8List bytes, String ext) async {
    if (demoMode) return null; // لا حفظ صور حقيقياً في الوضع التجريبي
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
    if (demoMode) {
      _demo.logs.insert(
        0,
        FoodLog(
          id: 'demo-${DateTime.now().millisecondsSinceEpoch}',
          foodName: n.foodName,
          mealType: mealType,
          loggedAt: DateTime.now(),
          calories: n.calories,
          proteinG: n.proteinG,
          carbsG: n.carbsG,
          fatG: n.fatG,
          fiberG: n.fiberG,
          servingSize: n.servingSize,
          confidenceScore: n.confidenceScore,
          imageUrl: imageUrl,
        ),
      );
      return;
    }
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
    if (demoMode) return _demo.waterMl;
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final data = await _c.from('water_logs').select('amount_ml').eq('date', today);
    return (data as List).fold<int>(0, (s, r) => s + ((r['amount_ml'] as num?)?.toInt() ?? 0));
  }

  Future<void> addWater(int ml) async {
    if (demoMode) {
      _demo.waterMl += ml;
      return;
    }
    await _c.from('water_logs').insert({'user_id': _uid, 'amount_ml': ml});
  }

  Future<void> undoLastWater() async {
    if (demoMode) {
      _demo.waterMl = max(0, _demo.waterMl - 250);
      return;
    }
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
    if (demoMode) return _demo.stats;
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

    if (demoMode) {
      _demo.stats = UserStats(
        totalPoints: newTotal,
        currentLevel: newLevel.id,
        currentStreak: streak,
        longestStreak: streak > stats.longestStreak ? streak : stats.longestStreak,
        lastLogDate: todayDate,
        badges: newBadges,
      );
    } else {
      await _c.from('user_stats').upsert({
        'user_id': _uid,
        'total_points': newTotal,
        'current_level': newLevel.id,
        'current_streak': streak,
        'longest_streak': streak > stats.longestStreak ? streak : stats.longestStreak,
        'last_log_date': todayDate.toIso8601String().substring(0, 10),
        'badges': newBadges,
      });
    }

    return (
      pointsEarned: earned,
      leveledUp: newLevel.id != oldLevel.id,
      levelName: '${newLevel.emoji} ${newLevel.name}',
    );
  }

  // ── AI: analyze food image (Edge Function) ────────────
  Future<NutritionResult> analyzeFood(Uint8List imageBytes, String mimeType) async {
    if (demoMode) {
      await Future.delayed(const Duration(milliseconds: 1400));
      final f = _demoFoods[Random().nextInt(_demoFoods.length)];
      return NutritionResult(
        foodName: f.name,
        servingSize: f.serving,
        calories: f.cal,
        proteinG: f.p,
        carbsG: f.c,
        fatG: f.f,
        fiberG: f.fi,
        confidenceScore: 0.9,
        notes: 'نتيجة تجريبية (Demo Mode) — ضع مفتاح Supabase الحقيقي للتحليل الفعلي بالذكاء الاصطناعي.',
      );
    }
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
    if (demoMode) return List<Map<String, dynamic>>.from(_demo.coachMsgs);
    final data = await _c
        .from('coach_messages')
        .select()
        .order('created_at', ascending: true)
        .limit(100);
    return List<Map<String, dynamic>>.from(data as List);
  }

  Future<String> sendCoachMessage(String message, List<Map<String, String>> history) async {
    if (demoMode) {
      _demo.coachMsgs.add({'role': 'user', 'content': message});
      await Future.delayed(const Duration(milliseconds: 900));
      const reply = 'هذا رد تجريبي من المدرب أليكس (Demo Mode). ضع مفتاح '
          'Supabase الحقيقي في lib/main.dart لتفعيل الرد الفعلي بالذكاء الاصطناعي.';
      _demo.coachMsgs.add({'role': 'assistant', 'content': reply});
      return reply;
    }
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

  Future<void> clearCoachChat() async {
    if (demoMode) {
      _demo.coachMsgs.clear();
      return;
    }
    await _c.from('coach_messages').delete().eq('user_id', _uid);
  }
}
