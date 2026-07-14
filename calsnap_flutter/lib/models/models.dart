/// Data models matching the Supabase schema (profiles, food_logs, user_stats).
class Profile {
  final String id;
  final String? name;
  final String? email;
  final int dailyCalorieGoal;

  Profile({required this.id, this.name, this.email, this.dailyCalorieGoal = 2000});

  factory Profile.fromJson(Map<String, dynamic> j) => Profile(
        id: j['id'] as String,
        name: j['name'] as String?,
        email: j['email'] as String?,
        dailyCalorieGoal: (j['daily_calorie_goal'] as num?)?.toInt() ?? 2000,
      );
}

class FoodLog {
  final String id;
  final String foodName;
  final String mealType;
  final DateTime loggedAt;
  final int calories;
  final double proteinG, carbsG, fatG, fiberG;
  final String? servingSize;
  final double? confidenceScore;
  final String? imageUrl;

  FoodLog({
    required this.id,
    required this.foodName,
    required this.mealType,
    required this.loggedAt,
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.fiberG,
    this.servingSize,
    this.confidenceScore,
    this.imageUrl,
  });

  factory FoodLog.fromJson(Map<String, dynamic> j) => FoodLog(
        id: j['id'] as String,
        foodName: j['food_name'] as String? ?? 'Food',
        mealType: j['meal_type'] as String? ?? 'snack',
        loggedAt: DateTime.parse(j['logged_at'] as String).toLocal(),
        calories: (j['calories'] as num?)?.toInt() ?? 0,
        proteinG: (j['protein_g'] as num?)?.toDouble() ?? 0,
        carbsG: (j['carbs_g'] as num?)?.toDouble() ?? 0,
        fatG: (j['fat_g'] as num?)?.toDouble() ?? 0,
        fiberG: (j['fiber_g'] as num?)?.toDouble() ?? 0,
        servingSize: j['serving_size'] as String?,
        confidenceScore: (j['confidence_score'] as num?)?.toDouble(),
        imageUrl: j['image_url'] as String?,
      );
}

class UserStats {
  final int totalPoints;
  final String currentLevel;
  final int currentStreak;
  final int longestStreak;
  final List<String> badges;
  final DateTime? lastLogDate;

  UserStats({
    this.totalPoints = 0,
    this.currentLevel = 'beginner',
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.badges = const [],
    this.lastLogDate,
  });

  factory UserStats.fromJson(Map<String, dynamic> j) => UserStats(
        totalPoints: (j['total_points'] as num?)?.toInt() ?? 0,
        currentLevel: j['current_level'] as String? ?? 'beginner',
        currentStreak: (j['current_streak'] as num?)?.toInt() ?? 0,
        longestStreak: (j['longest_streak'] as num?)?.toInt() ?? 0,
        badges: (j['badges'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        lastLogDate: j['last_log_date'] != null ? DateTime.tryParse(j['last_log_date'] as String) : null,
      );
}

/// Result returned by the analyze-food Edge Function.
class NutritionResult {
  String foodName;
  String servingSize;
  int calories;
  double proteinG, carbsG, fatG, fiberG;
  double confidenceScore;
  String notes;

  NutritionResult({
    required this.foodName,
    required this.servingSize,
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.fiberG,
    required this.confidenceScore,
    this.notes = '',
  });

  factory NutritionResult.fromJson(Map<String, dynamic> j) => NutritionResult(
        foodName: j['food_name'] as String? ?? 'Unknown food',
        servingSize: j['serving_size'] as String? ?? '',
        calories: (j['calories'] as num?)?.round() ?? 0,
        proteinG: (j['protein_g'] as num?)?.toDouble() ?? 0,
        carbsG: (j['carbs_g'] as num?)?.toDouble() ?? 0,
        fatG: (j['fat_g'] as num?)?.toDouble() ?? 0,
        fiberG: (j['fiber_g'] as num?)?.toDouble() ?? 0,
        confidenceScore: (j['confidence_score'] as num?)?.toDouble() ?? 0.5,
        notes: j['notes'] as String? ?? '',
      );
}
