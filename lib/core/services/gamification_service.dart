import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../models/badge_model.dart';

final gamificationServiceProvider = Provider<GamificationService>((ref) => GamificationService());

class GamificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // XP calculation constants
  static const int xpPerWorkout = 50;
  static const int xpPerPost = 10;
  static const int xpPerComment = 5;
  static const int xpPerLike = 2;
  static const int xpPerLevel = 100; // XP needed to level up increases by this amount per level

  // Calculate level from XP
  int calculateLevel(int xp) {
    int level = 1;
    int xpNeeded = xpPerLevel;

    while (xp >= xpNeeded) {
      level++;
      xpNeeded += xpPerLevel * level;
    }

    return level;
  }

  // Calculate XP needed for next level
  int xpForNextLevel(int currentLevel) {
    int totalXp = 0;
    for (int i = 1; i <= currentLevel; i++) {
      totalXp += xpPerLevel * i;
    }
    return totalXp;
  }

  // Award XP to user
  Future<void> awardXP(String userId, int xp, {String? reason}) async {
    await _firestore.runTransaction((transaction) async {
      final userDoc = await transaction.get(_firestore.collection('users').doc(userId));

      if (!userDoc.exists) return;

      final userData = UserModel.fromFirestore(userDoc);
      final newXP = userData.xp + xp;
      final newLevel = calculateLevel(newXP);

      transaction.update(userDoc.reference, {
        'xp': newXP,
        'level': newLevel,
      });

      // Check if level up occurred
      if (newLevel > userData.level) {
        // Could trigger a celebration or notification here
        await _createLevelUpNotification(userId, newLevel);
      }
    });
  }

  // Check and award badge
  Future<void> checkAndAwardBadge(String userId, BadgeType badgeType) async {
    await _firestore.runTransaction((transaction) async {
      final userDoc = await transaction.get(_firestore.collection('users').doc(userId));

      if (!userDoc.exists) return;

      final userData = UserModel.fromFirestore(userDoc);

      // Check if user already has badge
      if (userData.badges.contains(badgeType.name)) return;

      final badge = BadgeModel.getBadge(badgeType);
      if (badge == null) return;

      // Award badge
      transaction.update(userDoc.reference, {
        'badges': FieldValue.arrayUnion([badgeType.name]),
        'xp': FieldValue.increment(badge.xpReward),
      });

      // Create badge notification
      await _createBadgeNotification(userId, badge);
    });
  }

  // Check workout-related achievements
  Future<void> checkWorkoutAchievements(String userId) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    if (!userDoc.exists) return;

    final userData = UserModel.fromFirestore(userDoc);

    // Check first workout
    if (userData.totalWorkouts == 1) {
      await checkAndAwardBadge(userId, BadgeType.firstWorkout);
    }

    // Check total workouts
    if (userData.totalWorkouts == 50) {
      await checkAndAwardBadge(userId, BadgeType.totalWorkouts50);
    } else if (userData.totalWorkouts == 100) {
      await checkAndAwardBadge(userId, BadgeType.totalWorkouts100);
    } else if (userData.totalWorkouts == 500) {
      await checkAndAwardBadge(userId, BadgeType.totalWorkouts500);
    }

    // Check streaks
    if (userData.attendanceStreak == 7) {
      await checkAndAwardBadge(userId, BadgeType.streak7);
    } else if (userData.attendanceStreak == 30) {
      await checkAndAwardBadge(userId, BadgeType.streak30);
    } else if (userData.attendanceStreak == 100) {
      await checkAndAwardBadge(userId, BadgeType.streak100);
    }
  }

  // Get leaderboard
  Future<List<LeaderboardEntry>> getLeaderboard({
    LeaderboardType type = LeaderboardType.allTime,
    int limit = 20,
  }) async {
    Query query = _firestore.collection('users');

    // Apply time filter if needed
    if (type == LeaderboardType.weekly) {
      final weekAgo = DateTime.now().subtract(const Duration(days: 7));
      query = query.where('lastActiveAt', isGreaterThanOrEqualTo: Timestamp.fromDate(weekAgo));
    } else if (type == LeaderboardType.monthly) {
      final monthAgo = DateTime.now().subtract(const Duration(days: 30));
      query = query.where('lastActiveAt', isGreaterThanOrEqualTo: Timestamp.fromDate(monthAgo));
    }

    final snapshot = await query.orderBy('xp', descending: true).limit(limit).get();

    return snapshot.docs.asMap().entries.map((entry) {
      final userData = UserModel.fromFirestore(entry.value);
      return LeaderboardEntry(
        rank: entry.key + 1,
        user: userData,
      );
    }).toList();
  }

  // Update workout streak
  Future<void> updateWorkoutStreak(String userId) async {
    await _firestore.runTransaction((transaction) async {
      final userDoc = await transaction.get(_firestore.collection('users').doc(userId));

      if (!userDoc.exists) return;

      final userData = UserModel.fromFirestore(userDoc);
      final now = DateTime.now();
      final lastActive = userData.lastActiveAt;

      int newStreak = userData.attendanceStreak;

      if (lastActive != null) {
        final daysSinceLastActive = now.difference(lastActive).inDays;

        if (daysSinceLastActive == 1) {
          // Consecutive day - increment streak
          newStreak++;
        } else if (daysSinceLastActive > 1) {
          // Streak broken
          newStreak = 1;
        }
        // Same day = no change
      } else {
        newStreak = 1;
      }

      transaction.update(userDoc.reference, {
        'attendanceStreak': newStreak,
        'totalWorkouts': FieldValue.increment(1),
        'lastActiveAt': FieldValue.serverTimestamp(),
      });
    });

    // Check for achievements
    await checkWorkoutAchievements(userId);
  }

  Future<void> _createLevelUpNotification(String userId, int newLevel) async {
    // Implementation for creating level-up notification
    // Could use Firebase Cloud Messaging or in-app notifications
  }

  Future<void> _createBadgeNotification(String userId, BadgeModel badge) async {
    // Implementation for creating badge notification
    // Could use Firebase Cloud Messaging or in-app notifications
  }
}

enum LeaderboardType { allTime, weekly, monthly }

class LeaderboardEntry {
  final int rank;
  final UserModel user;

  LeaderboardEntry({
    required this.rank,
    required this.user,
  });
}
