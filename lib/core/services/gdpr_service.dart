import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import 'dart:developer' as developer;

final gdprServiceProvider = Provider<GDPRService>((ref) => GDPRService());

/// Service to handle GDPR compliance requirements
/// Including data export, deletion, and user privacy rights
class GDPRService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Export all user data as JSON (GDPR Right to Data Portability)
  Future<Map<String, dynamic>> exportUserData(String userId) async {
    try {
      final userData = <String, dynamic>{};

      // 1. User Profile
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        userData['profile'] = _sanitizeForExport(userDoc.data()!);
      }

      // 2. Workout Results
      final workoutResults = await _firestore
          .collection('workoutResults')
          .where('userId', isEqualTo: userId)
          .get();
      userData['workoutResults'] = workoutResults.docs
          .map((doc) => _sanitizeForExport(doc.data()))
          .toList();

      // 3. Social Posts
      final posts = await _firestore
          .collection('posts')
          .where('userId', isEqualTo: userId)
          .get();
      userData['posts'] = posts.docs
          .map((doc) => _sanitizeForExport(doc.data()))
          .toList();

      // 4. Comments
      final comments = await _firestore
          .collection('comments')
          .where('userId', isEqualTo: userId)
          .get();
      userData['comments'] = comments.docs
          .map((doc) => _sanitizeForExport(doc.data()))
          .toList();

      // 5. Messages
      final conversations = await _firestore
          .collection('conversations')
          .where('participants', arrayContains: userId)
          .get();

      final conversationIds = conversations.docs.map((doc) => doc.id).toList();
      final messages = <Map<String, dynamic>>[];

      for (final convId in conversationIds) {
        final convMessages = await _firestore
            .collection('messages')
            .where('conversationId', isEqualTo: convId)
            .where('senderId', isEqualTo: userId)
            .get();
        messages.addAll(
          convMessages.docs.map((doc) => _sanitizeForExport(doc.data()))
        );
      }
      userData['messages'] = messages;

      // 6. Class Bookings
      final bookings = await _firestore
          .collection('classes')
          .where('participants', arrayContains: userId)
          .get();
      userData['classBookings'] = bookings.docs
          .map((doc) => {
                'classId': doc.id,
                'className': doc.data()['name'],
                'startTime': doc.data()['startTime'],
              })
          .toList();

      // 7. Notifications History
      final notifications = await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .get();
      userData['notifications'] = notifications.docs
          .map((doc) => _sanitizeForExport(doc.data()))
          .toList();

      // Add metadata
      userData['exportedAt'] = DateTime.now().toIso8601String();
      userData['dataProtectionNotice'] =
          'This data export is provided in compliance with GDPR Article 20 (Right to Data Portability).';

      developer.log('User data exported for: $userId');
      return userData;
    } catch (e) {
      developer.log('Error exporting user data: $e');
      rethrow;
    }
  }

  /// Sanitize data for export (remove internal fields, convert timestamps)
  Map<String, dynamic> _sanitizeForExport(Map<String, dynamic> data) {
    final sanitized = Map<String, dynamic>.from(data);

    // Convert Timestamps to ISO strings
    sanitized.forEach((key, value) {
      if (value is Timestamp) {
        sanitized[key] = value.toDate().toIso8601String();
      }
    });

    // Remove internal Firebase fields
    sanitized.remove('_id');
    sanitized.remove('_ref');

    return sanitized;
  }

  /// Download user data as JSON file
  String exportUserDataAsJson(Map<String, dynamic> userData) {
    return JsonEncoder.withIndent('  ').convert(userData);
  }

  /// Anonymize user data instead of deletion (GDPR compliant alternative)
  Future<void> anonymizeUserData(String userId) async {
    try {
      final batch = _firestore.batch();

      // Anonymize user profile
      final userRef = _firestore.collection('users').doc(userId);
      batch.update(userRef, {
        'email': 'deleted_user_${DateTime.now().millisecondsSinceEpoch}@anonymized.local',
        'displayName': 'Deleted User',
        'photoUrl': null,
        'fcmToken': null,
        'preferredLanguage': null,
        'anonymizedAt': FieldValue.serverTimestamp(),
        'gdprAnonymized': true,
      });

      // Anonymize posts
      final posts = await _firestore
          .collection('posts')
          .where('userId', isEqualTo: userId)
          .get();

      for (var doc in posts.docs) {
        batch.update(doc.reference, {
          'userName': 'Deleted User',
          'userPhotoUrl': null,
          'anonymized': true,
        });
      }

      // Anonymize comments
      final comments = await _firestore
          .collection('comments')
          .where('userId', isEqualTo: userId)
          .get();

      for (var doc in comments.docs) {
        batch.update(doc.reference, {
          'userName': 'Deleted User',
          'userPhotoUrl': null,
          'anonymized': true,
        });
      }

      // Anonymize workout results
      final workoutResults = await _firestore
          .collection('workoutResults')
          .where('userId', isEqualTo: userId)
          .get();

      for (var doc in workoutResults.docs) {
        batch.update(doc.reference, {
          'userName': 'Deleted User',
          'userPhotoUrl': null,
          'anonymized': true,
        });
      }

      await batch.commit();
      developer.log('User data anonymized: $userId');
    } catch (e) {
      developer.log('Error anonymizing user data: $e');
      rethrow;
    }
  }

  /// Complete account deletion (GDPR Right to Erasure)
  Future<void> deleteUserAccount(String userId) async {
    try {
      // 1. Delete user's messages
      final conversations = await _firestore
          .collection('conversations')
          .where('participants', arrayContains: userId)
          .get();

      for (var conv in conversations.docs) {
        // Delete messages in this conversation from this user
        final messages = await _firestore
            .collection('messages')
            .where('conversationId', isEqualTo: conv.id)
            .where('senderId', isEqualTo: userId)
            .get();

        for (var msg in messages.docs) {
          await msg.reference.delete();
        }

        // Remove user from conversation participants
        final participants = List<String>.from(conv.data()['participants']);
        participants.remove(userId);

        if (participants.isEmpty) {
          // Delete conversation if no participants left
          await conv.reference.delete();
        } else {
          // Update conversation
          await conv.reference.update({'participants': participants});
        }
      }

      // 2. Delete social posts
      final posts = await _firestore
          .collection('posts')
          .where('userId', isEqualTo: userId)
          .get();

      for (var post in posts.docs) {
        // Delete associated comments
        final comments = await _firestore
            .collection('comments')
            .where('postId', isEqualTo: post.id)
            .get();

        for (var comment in comments.docs) {
          await comment.reference.delete();
        }

        await post.reference.delete();
      }

      // 3. Delete user's comments on other posts
      final userComments = await _firestore
          .collection('comments')
          .where('userId', isEqualTo: userId)
          .get();

      for (var comment in userComments.docs) {
        await comment.reference.delete();
      }

      // 4. Delete workout results
      final workoutResults = await _firestore
          .collection('workoutResults')
          .where('userId', isEqualTo: userId)
          .get();

      for (var result in workoutResults.docs) {
        await result.reference.delete();
      }

      // 5. Remove from class bookings
      final classes = await _firestore
          .collection('classes')
          .where('participants', arrayContains: userId)
          .get();

      for (var classDoc in classes.docs) {
        final participants = List<String>.from(classDoc.data()['participants']);
        participants.remove(userId);
        await classDoc.reference.update({'participants': participants});
      }

      // Remove from waitlists
      final waitlistClasses = await _firestore
          .collection('classes')
          .where('waitlist', arrayContains: userId)
          .get();

      for (var classDoc in waitlistClasses.docs) {
        final waitlist = List<String>.from(classDoc.data()['waitlist']);
        waitlist.remove(userId);
        await classDoc.reference.update({'waitlist': waitlist});
      }

      // 6. Delete notification history
      final notifications = await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .get();

      for (var notif in notifications.docs) {
        await notif.reference.delete();
      }

      // 7. Delete pending notifications
      final pendingNotifications = await _firestore
          .collection('pendingNotifications')
          .where('userId', isEqualTo: userId)
          .get();

      for (var notif in pendingNotifications.docs) {
        await notif.reference.delete();
      }

      // 8. Delete user profile photos from Storage
      try {
        final photoRef = _storage.ref().child('user_photos/$userId');
        await photoRef.delete();
      } catch (e) {
        // Photo might not exist, continue
        developer.log('No user photo to delete or error: $e');
      }

      // 9. Delete user document
      await _firestore.collection('users').doc(userId).delete();

      // 10. Delete Firebase Auth account
      final currentUser = _auth.currentUser;
      if (currentUser != null && currentUser.uid == userId) {
        await currentUser.delete();
      }

      developer.log('User account completely deleted: $userId');
    } catch (e) {
      developer.log('Error deleting user account: $e');
      rethrow;
    }
  }

  /// Update user consent preferences
  Future<void> updateConsent({
    required String userId,
    required bool analyticsConsent,
    required bool marketingConsent,
    required bool thirdPartyConsent,
  }) async {
    await _firestore.collection('users').doc(userId).update({
      'consent': {
        'analytics': analyticsConsent,
        'marketing': marketingConsent,
        'thirdParty': thirdPartyConsent,
        'updatedAt': FieldValue.serverTimestamp(),
      },
    });
  }

  /// Get data retention policy
  String getDataRetentionPolicy() {
    return '''
Data Retention Policy:

1. User Profile Data: Retained while account is active
2. Workout Results: Retained for 5 years after account deletion
3. Messages: Deleted immediately upon account deletion
4. Posts & Comments: Anonymized upon account deletion
5. Class Bookings: Retained for 2 years for business records
6. Analytics Data: Aggregated and anonymized after 90 days

You have the right to:
- Request data export (GDPR Article 20)
- Request data deletion (GDPR Article 17)
- Request data rectification (GDPR Article 16)
- Withdraw consent at any time (GDPR Article 7)
''';
  }

  /// Check if user has given required consents
  Future<bool> hasRequiredConsents(String userId) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    if (!userDoc.exists) return false;

    final data = userDoc.data() as Map<String, dynamic>;
    final consent = data['consent'] as Map<String, dynamic>?;

    // At minimum, user must consent to essential data processing
    // Analytics and marketing are optional
    return consent != null;
  }
}
