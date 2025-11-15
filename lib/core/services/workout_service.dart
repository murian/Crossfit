import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/workout_model.dart';

final workoutServiceProvider = Provider<WorkoutService>((ref) => WorkoutService());

class WorkoutService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get today's WOD
  Stream<WorkoutModel?> getTodaysWOD() {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);

    return _firestore
        .collection('workouts')
        .where('isWOD', isEqualTo: true)
        .where('wodDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('wodDate', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      return WorkoutModel.fromFirestore(snapshot.docs.first);
    });
  }

  // Get all workouts
  Stream<List<WorkoutModel>> getAllWorkouts() {
    return _firestore
        .collection('workouts')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => WorkoutModel.fromFirestore(doc))
            .toList());
  }

  // Create workout
  Future<String> createWorkout(WorkoutModel workout) async {
    final docRef = await _firestore.collection('workouts').add(workout.toFirestore());
    return docRef.id;
  }

  // Set as WOD
  Future<void> setAsWOD(String workoutId, DateTime date) async {
    // First, unset any existing WOD for this date
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    final existingWODs = await _firestore
        .collection('workouts')
        .where('isWOD', isEqualTo: true)
        .where('wodDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('wodDate', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .get();

    for (var doc in existingWODs.docs) {
      await doc.reference.update({'isWOD': false, 'wodDate': null});
    }

    // Set the new WOD
    await _firestore.collection('workouts').doc(workoutId).update({
      'isWOD': true,
      'wodDate': Timestamp.fromDate(date),
    });
  }

  // Submit workout result
  Future<String> submitWorkoutResult(WorkoutResultModel result) async {
    final docRef = await _firestore.collection('workoutResults').add(result.toFirestore());
    return docRef.id;
  }

  // Get workout results for a specific workout
  Stream<List<WorkoutResultModel>> getWorkoutResults(String workoutId) {
    return _firestore
        .collection('workoutResults')
        .where('workoutId', isEqualTo: workoutId)
        .orderBy('completedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => WorkoutResultModel.fromFirestore(doc))
            .toList());
  }

  // Get user's workout results
  Stream<List<WorkoutResultModel>> getUserWorkoutResults(String userId) {
    return _firestore
        .collection('workoutResults')
        .where('userId', isEqualTo: userId)
        .orderBy('completedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => WorkoutResultModel.fromFirestore(doc))
            .toList());
  }

  // Like a workout result
  Future<void> likeWorkoutResult(String resultId, String userId) async {
    await _firestore.collection('workoutResults').doc(resultId).update({
      'likes': FieldValue.arrayUnion([userId]),
    });
  }

  // Unlike a workout result
  Future<void> unlikeWorkoutResult(String resultId, String userId) async {
    await _firestore.collection('workoutResults').doc(resultId).update({
      'likes': FieldValue.arrayRemove([userId]),
    });
  }

  // Get leaderboard for a specific workout
  Future<List<WorkoutResultModel>> getWorkoutLeaderboard(String workoutId, {int limit = 10}) async {
    final snapshot = await _firestore
        .collection('workoutResults')
        .where('workoutId', isEqualTo: workoutId)
        .orderBy('completedAt')
        .limit(limit)
        .get();

    return snapshot.docs.map((doc) => WorkoutResultModel.fromFirestore(doc)).toList();
  }
}
