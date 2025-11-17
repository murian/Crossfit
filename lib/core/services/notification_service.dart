import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer' as developer;

final notificationServiceProvider = Provider<NotificationService>((ref) => NotificationService());

/// Service to handle push notifications using Firebase Cloud Messaging
class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Initialize notifications and request permissions
  Future<void> initialize(String userId) async {
    try {
      // Request permission for notifications
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        developer.log('User granted notification permission');

        // Get the FCM token
        String? token = await _messaging.getToken();

        if (token != null) {
          developer.log('FCM Token: $token');
          // Save token to user document
          await saveFCMToken(userId, token);

          // Listen for token refresh
          _messaging.onTokenRefresh.listen((newToken) {
            developer.log('FCM Token refreshed: $newToken');
            saveFCMToken(userId, newToken);
          });

          // Handle foreground messages
          FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
        }
      } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
        developer.log('User granted provisional notification permission');
      } else {
        developer.log('User declined or has not accepted notification permission');
      }
    } catch (e) {
      developer.log('Error initializing notifications: $e');
    }
  }

  /// Save FCM token to user document in Firestore
  Future<void> saveFCMToken(String userId, String token) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'fcmToken': token,
        'lastTokenUpdate': FieldValue.serverTimestamp(),
      });
      developer.log('FCM token saved for user: $userId');
    } catch (e) {
      developer.log('Error saving FCM token: $e');
    }
  }

  /// Handle messages when app is in foreground
  void _handleForegroundMessage(RemoteMessage message) {
    developer.log('Received foreground message: ${message.notification?.title}');
    // You can show a local notification here or update UI
    // For now, we'll just log it
  }

  /// Send notification to specific user (requires server-side implementation)
  /// This method documents what data should be sent to your Cloud Function
  Future<void> sendWaitlistNotification({
    required String userId,
    required String className,
    required String classTime,
    required String classId,
  }) async {
    // This will be called by the Cloud Function
    // Documenting the notification payload structure
    final notificationData = {
      'userId': userId,
      'className': className,
      'classTime': classTime,
      'classId': classId,
      'type': 'waitlist_spot_available',
      'timestamp': FieldValue.serverTimestamp(),
    };

    // Create a notification record in Firestore that Cloud Function can pick up
    await _firestore.collection('pendingNotifications').add(notificationData);
    developer.log('Notification queued for user: $userId');
  }

  /// Enable notifications for user
  Future<void> enableNotifications(String userId) async {
    await _firestore.collection('users').doc(userId).update({
      'notificationsEnabled': true,
    });
  }

  /// Disable notifications for user
  Future<void> disableNotifications(String userId) async {
    await _firestore.collection('users').doc(userId).update({
      'notificationsEnabled': false,
    });
  }

  /// Clear FCM token when user logs out
  Future<void> clearToken(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'fcmToken': FieldValue.delete(),
      });
      await _messaging.deleteToken();
      developer.log('FCM token cleared for user: $userId');
    } catch (e) {
      developer.log('Error clearing FCM token: $e');
    }
  }

  /// Setup background message handler (must be top-level function)
  static Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    developer.log('Handling background message: ${message.messageId}');
    // Handle the message
  }
}

/// Background message handler - must be a top-level function
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  developer.log('Handling a background message: ${message.messageId}');
  developer.log('Notification title: ${message.notification?.title}');
  developer.log('Notification body: ${message.notification?.body}');
}
