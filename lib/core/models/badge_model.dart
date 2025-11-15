enum BadgeType {
  firstWorkout,
  streak7,
  streak30,
  streak100,
  totalWorkouts50,
  totalWorkouts100,
  totalWorkouts500,
  prStrength,
  prEndurance,
  socialButterfly,
  earlyBird,
  nightOwl,
  weekendWarrior,
  monthlyChampion,
  leaderboardTop3,
}

class BadgeModel {
  final BadgeType type;
  final String name;
  final String description;
  final String iconPath;
  final int xpReward;

  const BadgeModel({
    required this.type,
    required this.name,
    required this.description,
    required this.iconPath,
    required this.xpReward,
  });

  static const Map<BadgeType, BadgeModel> badges = {
    BadgeType.firstWorkout: BadgeModel(
      type: BadgeType.firstWorkout,
      name: 'First Step',
      description: 'Complete your first workout',
      iconPath: '🎯',
      xpReward: 50,
    ),
    BadgeType.streak7: BadgeModel(
      type: BadgeType.streak7,
      name: 'Week Warrior',
      description: 'Complete workouts 7 days in a row',
      iconPath: '🔥',
      xpReward: 100,
    ),
    BadgeType.streak30: BadgeModel(
      type: BadgeType.streak30,
      name: 'Month Master',
      description: 'Complete workouts 30 days in a row',
      iconPath: '💪',
      xpReward: 500,
    ),
    BadgeType.streak100: BadgeModel(
      type: BadgeType.streak100,
      name: 'Century Legend',
      description: 'Complete workouts 100 days in a row',
      iconPath: '👑',
      xpReward: 2000,
    ),
    BadgeType.totalWorkouts50: BadgeModel(
      type: BadgeType.totalWorkouts50,
      name: 'Half Century',
      description: 'Complete 50 total workouts',
      iconPath: '⭐',
      xpReward: 200,
    ),
    BadgeType.totalWorkouts100: BadgeModel(
      type: BadgeType.totalWorkouts100,
      name: 'Centurion',
      description: 'Complete 100 total workouts',
      iconPath: '🏆',
      xpReward: 500,
    ),
    BadgeType.totalWorkouts500: BadgeModel(
      type: BadgeType.totalWorkouts500,
      name: 'Elite Athlete',
      description: 'Complete 500 total workouts',
      iconPath: '💎',
      xpReward: 3000,
    ),
    BadgeType.prStrength: BadgeModel(
      type: BadgeType.prStrength,
      name: 'Strength Beast',
      description: 'Set a new personal record in strength',
      iconPath: '🦾',
      xpReward: 150,
    ),
    BadgeType.prEndurance: BadgeModel(
      type: BadgeType.prEndurance,
      name: 'Endurance King',
      description: 'Set a new personal record in endurance',
      iconPath: '🏃',
      xpReward: 150,
    ),
    BadgeType.socialButterfly: BadgeModel(
      type: BadgeType.socialButterfly,
      name: 'Social Butterfly',
      description: 'Get 50 likes on your posts',
      iconPath: '🦋',
      xpReward: 100,
    ),
    BadgeType.earlyBird: BadgeModel(
      type: BadgeType.earlyBird,
      name: 'Early Bird',
      description: 'Attend 10 morning classes (before 8am)',
      iconPath: '🌅',
      xpReward: 200,
    ),
    BadgeType.nightOwl: BadgeModel(
      type: BadgeType.nightOwl,
      name: 'Night Owl',
      description: 'Attend 10 evening classes (after 7pm)',
      iconPath: '🌙',
      xpReward: 200,
    ),
    BadgeType.weekendWarrior: BadgeModel(
      type: BadgeType.weekendWarrior,
      name: 'Weekend Warrior',
      description: 'Attend weekend classes for 4 weeks straight',
      iconPath: '⚔️',
      xpReward: 250,
    ),
    BadgeType.monthlyChampion: BadgeModel(
      type: BadgeType.monthlyChampion,
      name: 'Monthly Champion',
      description: 'Finish in top 3 on monthly leaderboard',
      iconPath: '🥇',
      xpReward: 1000,
    ),
    BadgeType.leaderboardTop3: BadgeModel(
      type: BadgeType.leaderboardTop3,
      name: 'Leaderboard Elite',
      description: 'Reach top 3 on any leaderboard',
      iconPath: '📊',
      xpReward: 300,
    ),
  };

  static BadgeModel? getBadge(BadgeType type) => badges[type];
}
