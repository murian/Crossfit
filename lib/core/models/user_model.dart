import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { admin, member }

class UserModel {
  final String id;
  final String email;
  final String displayName;
  final String? photoUrl;
  final UserRole role;
  final int xp;
  final int level;
  final List<String> badges;
  final DateTime createdAt;
  final DateTime? lastActiveAt;
  final Map<String, dynamic>? personalRecords; // PR tracking
  final int totalWorkouts;
  final int attendanceStreak;
  final String? fcmToken; // Firebase Cloud Messaging token for push notifications
  final bool notificationsEnabled;
  final String? preferredLanguage; // 'en' or 'nl'

  UserModel({
    required this.id,
    required this.email,
    required this.displayName,
    this.photoUrl,
    this.role = UserRole.member,
    this.xp = 0,
    this.level = 1,
    this.badges = const [],
    required this.createdAt,
    this.lastActiveAt,
    this.personalRecords,
    this.totalWorkouts = 0,
    this.attendanceStreak = 0,
    this.fcmToken,
    this.notificationsEnabled = true,
    this.preferredLanguage,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      photoUrl: data['photoUrl'],
      role: UserRole.values.firstWhere(
        (e) => e.name == data['role'],
        orElse: () => UserRole.member,
      ),
      xp: data['xp'] ?? 0,
      level: data['level'] ?? 1,
      badges: List<String>.from(data['badges'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lastActiveAt: data['lastActiveAt'] != null
          ? (data['lastActiveAt'] as Timestamp).toDate()
          : null,
      personalRecords: data['personalRecords'],
      totalWorkouts: data['totalWorkouts'] ?? 0,
      attendanceStreak: data['attendanceStreak'] ?? 0,
      fcmToken: data['fcmToken'],
      notificationsEnabled: data['notificationsEnabled'] ?? true,
      preferredLanguage: data['preferredLanguage'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'role': role.name,
      'xp': xp,
      'level': level,
      'badges': badges,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastActiveAt': lastActiveAt != null ? Timestamp.fromDate(lastActiveAt!) : null,
      'personalRecords': personalRecords,
      'totalWorkouts': totalWorkouts,
      'attendanceStreak': attendanceStreak,
      'fcmToken': fcmToken,
      'notificationsEnabled': notificationsEnabled,
      'preferredLanguage': preferredLanguage,
    };
  }

  UserModel copyWith({
    String? displayName,
    String? photoUrl,
    UserRole? role,
    int? xp,
    int? level,
    List<String>? badges,
    DateTime? lastActiveAt,
    Map<String, dynamic>? personalRecords,
    int? totalWorkouts,
    int? attendanceStreak,
    String? fcmToken,
    bool? notificationsEnabled,
    String? preferredLanguage,
  }) {
    return UserModel(
      id: id,
      email: email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      xp: xp ?? this.xp,
      level: level ?? this.level,
      badges: badges ?? this.badges,
      createdAt: createdAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      personalRecords: personalRecords ?? this.personalRecords,
      totalWorkouts: totalWorkouts ?? this.totalWorkouts,
      attendanceStreak: attendanceStreak ?? this.attendanceStreak,
      fcmToken: fcmToken ?? this.fcmToken,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
    );
  }

  bool get isAdmin => role == UserRole.admin;
}
