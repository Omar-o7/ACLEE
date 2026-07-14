/// Levels & badges — ported from the web app's gamification.ts
class LevelDef {
  final String id, name, emoji;
  final int min, max;
  const LevelDef(this.id, this.name, this.emoji, this.min, this.max);
}

const levels = <LevelDef>[
  LevelDef('beginner', 'Beginner', '🥉', 0, 499),
  LevelDef('explorer', 'Explorer', '🥈', 500, 1499),
  LevelDef('achiever', 'Achiever', '🥇', 1500, 3999),
  LevelDef('elite', 'Elite', '💎', 4000, 9999),
  LevelDef('legend', 'Legend', '👑', 10000, 1 << 31),
];

LevelDef levelForPoints(int points) =>
    levels.lastWhere((l) => points >= l.min, orElse: () => levels.first);

class BadgeDef {
  final String id, emoji, name, description, category;
  final int? progressTotal;
  const BadgeDef(this.id, this.emoji, this.name, this.description, this.category, [this.progressTotal]);
}

const badges = <BadgeDef>[
  BadgeDef('on_fire', '🔥', 'On Fire', 'Reach a 3-day streak', 'streak', 3),
  BadgeDef('week_warrior', '⚡', 'Week Warrior', 'Reach a 7-day streak', 'streak', 7),
  BadgeDef('consistency_king', '🌟', 'Consistency King', 'Reach a 30-day streak', 'streak', 30),
  BadgeDef('unstoppable', '💫', 'Unstoppable', 'Reach a 60-day streak', 'streak', 60),
  BadgeDef('first_snap', '📸', 'First Snap', 'Log your very first meal', 'logging'),
  BadgeDef('full_day', '🍽️', 'Full Day', 'Log breakfast, lunch and dinner in one day', 'logging'),
  BadgeDef('century', '💯', 'Century', 'Log 100 meals total', 'logging', 100),
  BadgeDef('dedicated', '🎯', 'Dedicated', 'Log 500 meals total', 'logging', 500),
  BadgeDef('goal_crusher', '✅', 'Goal Crusher', 'Hit your daily goal 7 times', 'goal', 7),
  BadgeDef('perfect_week', '🏆', 'Perfect Week', 'Hit your goal every day for 7 days', 'goal', 7),
  BadgeDef('ai_curious', '🤖', 'AI Curious', 'Chat with the AI coach for the first time', 'ai'),
  BadgeDef('early_bird', '🌅', 'Early Bird', 'Log breakfast before 8am, 5 times', 'special', 5),
  BadgeDef('night_owl', '🌙', 'Night Owl', 'Log a meal after 10pm, 5 times', 'special', 5),
];
