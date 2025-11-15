import 'package:cloud_firestore/cloud_firestore.dart';

enum ClassType { crossfit, weightlifting, gymnastics, endurance, openGym }

class ClassModel {
  final String id;
  final String name;
  final String? description;
  final ClassType type;
  final DateTime startTime;
  final DateTime endTime;
  final int maxCapacity;
  final String? coachId;
  final String? coachName;
  final List<String> participants; // User IDs
  final List<String> waitlist; // User IDs
  final bool isRecurring;
  final String? recurringPattern; // e.g., "weekly", "daily"
  final String? wodId; // Workout of the Day reference
  final bool isCancelled;

  ClassModel({
    required this.id,
    required this.name,
    this.description,
    required this.type,
    required this.startTime,
    required this.endTime,
    this.maxCapacity = 16,
    this.coachId,
    this.coachName,
    this.participants = const [],
    this.waitlist = const [],
    this.isRecurring = false,
    this.recurringPattern,
    this.wodId,
    this.isCancelled = false,
  });

  factory ClassModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ClassModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'],
      type: ClassType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => ClassType.crossfit,
      ),
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: (data['endTime'] as Timestamp).toDate(),
      maxCapacity: data['maxCapacity'] ?? 16,
      coachId: data['coachId'],
      coachName: data['coachName'],
      participants: List<String>.from(data['participants'] ?? []),
      waitlist: List<String>.from(data['waitlist'] ?? []),
      isRecurring: data['isRecurring'] ?? false,
      recurringPattern: data['recurringPattern'],
      wodId: data['wodId'],
      isCancelled: data['isCancelled'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'type': type.name,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'maxCapacity': maxCapacity,
      'coachId': coachId,
      'coachName': coachName,
      'participants': participants,
      'waitlist': waitlist,
      'isRecurring': isRecurring,
      'recurringPattern': recurringPattern,
      'wodId': wodId,
      'isCancelled': isCancelled,
    };
  }

  bool get isFull => participants.length >= maxCapacity;
  bool get hasWaitlist => waitlist.isNotEmpty;
  int get availableSpots => maxCapacity - participants.length;
}
