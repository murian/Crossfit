import 'package:cloud_firestore/cloud_firestore.dart';

enum WorkoutType { forTime, amrap, emom, tabata, strength, chipper, custom }

class WorkoutModel {
  final String id;
  final String name;
  final String description;
  final WorkoutType type;
  final String? duration; // e.g., "20 minutes", "5 rounds"
  final List<String> movements; // e.g., ["Pull-ups", "Push-ups", "Air Squats"]
  final Map<String, dynamic>? scheme; // Reps, rounds, etc.
  final String? scaling; // Scaling options
  final DateTime createdAt;
  final String createdBy; // Admin user ID
  final bool isWOD; // Is this today's Workout of the Day?
  final DateTime? wodDate;

  WorkoutModel({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    this.duration,
    required this.movements,
    this.scheme,
    this.scaling,
    required this.createdAt,
    required this.createdBy,
    this.isWOD = false,
    this.wodDate,
  });

  factory WorkoutModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WorkoutModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      type: WorkoutType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => WorkoutType.custom,
      ),
      duration: data['duration'],
      movements: List<String>.from(data['movements'] ?? []),
      scheme: data['scheme'],
      scaling: data['scaling'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      createdBy: data['createdBy'] ?? '',
      isWOD: data['isWOD'] ?? false,
      wodDate: data['wodDate'] != null ? (data['wodDate'] as Timestamp).toDate() : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'type': type.name,
      'duration': duration,
      'movements': movements,
      'scheme': scheme,
      'scaling': scaling,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
      'isWOD': isWOD,
      'wodDate': wodDate != null ? Timestamp.fromDate(wodDate!) : null,
    };
  }
}

class WorkoutResultModel {
  final String id;
  final String userId;
  final String userName;
  final String? userPhotoUrl;
  final String workoutId;
  final String workoutName;
  final String? result; // Time, reps, weight, etc.
  final String? notes;
  final int? rxd; // 0 = scaled, 1 = RX'd
  final DateTime completedAt;
  final List<String> likes; // User IDs who liked
  final int commentCount;

  WorkoutResultModel({
    required this.id,
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
    required this.workoutId,
    required this.workoutName,
    this.result,
    this.notes,
    this.rxd,
    required this.completedAt,
    this.likes = const [],
    this.commentCount = 0,
  });

  factory WorkoutResultModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WorkoutResultModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userPhotoUrl: data['userPhotoUrl'],
      workoutId: data['workoutId'] ?? '',
      workoutName: data['workoutName'] ?? '',
      result: data['result'],
      notes: data['notes'],
      rxd: data['rxd'],
      completedAt: (data['completedAt'] as Timestamp).toDate(),
      likes: List<String>.from(data['likes'] ?? []),
      commentCount: data['commentCount'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'workoutId': workoutId,
      'workoutName': workoutName,
      'result': result,
      'notes': notes,
      'rxd': rxd,
      'completedAt': Timestamp.fromDate(completedAt),
      'likes': likes,
      'commentCount': commentCount,
    };
  }
}
