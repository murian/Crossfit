import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/class_model.dart';
import 'notification_service.dart';

final classServiceProvider = Provider<ClassService>((ref) => ClassService());

class ClassService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

  // Get upcoming classes stream
  Stream<List<ClassModel>> getUpcomingClasses() {
    final now = DateTime.now();
    return _firestore
        .collection('classes')
        .where('startTime', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
        .where('isCancelled', isEqualTo: false)
        .orderBy('startTime')
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ClassModel.fromFirestore(doc))
            .toList());
  }

  // Get classes for a specific date
  Stream<List<ClassModel>> getClassesForDate(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    return _firestore
        .collection('classes')
        .where('startTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('startTime', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .orderBy('startTime')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ClassModel.fromFirestore(doc))
            .toList());
  }

  // Create a new class
  Future<String> createClass(ClassModel classModel) async {
    final docRef = await _firestore.collection('classes').add(classModel.toFirestore());
    return docRef.id;
  }

  // Update class
  Future<void> updateClass(String classId, Map<String, dynamic> updates) async {
    await _firestore.collection('classes').doc(classId).update(updates);
  }

  // Book a spot in a class
  Future<void> bookClass(String classId, String userId) async {
    final docRef = _firestore.collection('classes').doc(classId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) throw Exception('Class not found');

      final classData = ClassModel.fromFirestore(snapshot);

      // Check if already booked
      if (classData.participants.contains(userId)) {
        throw Exception('Already booked');
      }

      // Check if class is full
      if (classData.isFull) {
        // Add to waitlist
        final updatedWaitlist = [...classData.waitlist, userId];
        transaction.update(docRef, {'waitlist': updatedWaitlist});
      } else {
        // Add to participants
        final updatedParticipants = [...classData.participants, userId];
        transaction.update(docRef, {'participants': updatedParticipants});
      }
    });
  }

  // Cancel a booking
  Future<void> cancelBooking(String classId, String userId) async {
    final docRef = _firestore.collection('classes').doc(classId);
    String? notifyUserId;
    ClassModel? classData;

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) throw Exception('Class not found');

      classData = ClassModel.fromFirestore(snapshot);

      // Remove from participants
      final updatedParticipants = classData!.participants.where((id) => id != userId).toList();

      // If there's a waitlist, move first person to participants
      final updatedWaitlist = List<String>.from(classData!.waitlist);
      if (updatedWaitlist.isNotEmpty && updatedParticipants.length < classData!.maxCapacity) {
        notifyUserId = updatedWaitlist.removeAt(0);
        updatedParticipants.add(notifyUserId!);
      }

      transaction.update(docRef, {
        'participants': updatedParticipants,
        'waitlist': updatedWaitlist,
      });
    });

    // Send notification to the user who got off the waitlist
    if (notifyUserId != null && classData != null) {
      await _sendWaitlistNotification(
        userId: notifyUserId!,
        classModel: classData!,
      );
    }
  }

  /// Send push notification to user when they get off the waitlist
  Future<void> _sendWaitlistNotification({
    required String userId,
    required ClassModel classModel,
  }) async {
    try {
      // Get user's notification preferences
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return;

      final userData = userDoc.data() as Map<String, dynamic>;
      final notificationsEnabled = userData['notificationsEnabled'] ?? true;

      if (!notificationsEnabled) return;

      // Format class time
      final formattedTime = DateFormat('EEEE, MMM d @ h:mm a').format(classModel.startTime);

      // Send notification via notification service
      await _notificationService.sendWaitlistNotification(
        userId: userId,
        className: classModel.name,
        classTime: formattedTime,
        classId: classModel.id,
      );
    } catch (e) {
      // Log error but don't throw - notification failure shouldn't stop the booking
      print('Error sending waitlist notification: $e');
    }
  }

  // Remove from waitlist
  Future<void> removeFromWaitlist(String classId, String userId) async {
    final docRef = _firestore.collection('classes').doc(classId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) throw Exception('Class not found');

      final classData = ClassModel.fromFirestore(snapshot);
      final updatedWaitlist = classData.waitlist.where((id) => id != userId).toList();

      transaction.update(docRef, {'waitlist': updatedWaitlist});
    });
  }

  // Get user's upcoming reservations
  Stream<List<ClassModel>> getUserReservations(String userId) {
    final now = DateTime.now();
    return _firestore
        .collection('classes')
        .where('participants', arrayContains: userId)
        .where('startTime', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
        .orderBy('startTime')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ClassModel.fromFirestore(doc))
            .toList());
  }

  // Delete class (admin only)
  Future<void> deleteClass(String classId) async {
    await _firestore.collection('classes').doc(classId).delete();
  }

  // Cancel class (admin only)
  Future<void> cancelClass(String classId) async {
    await _firestore.collection('classes').doc(classId).update({'isCancelled': true});
  }
}
