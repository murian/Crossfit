/**
 * Firebase Cloud Functions for CrossFit Box App
 *
 * This handles server-side logic including:
 * - Sending push notifications for waitlist updates
 * - Background tasks and triggers
 */

const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

/**
 * Send push notification when a pending notification is created
 *
 * Triggered when a document is added to the 'pendingNotifications' collection
 * This allows the client app to queue notifications without needing server credentials
 */
exports.sendWaitlistNotification = functions.firestore
  .document('pendingNotifications/{notificationId}')
  .onCreate(async (snap, context) => {
    const notification = snap.data();
    const { userId, className, classTime, classId, type } = notification;

    if (type !== 'waitlist_spot_available') {
      console.log('Unknown notification type:', type);
      return null;
    }

    try {
      // Get user's FCM token and notification preferences
      const userDoc = await admin.firestore().collection('users').doc(userId).get();

      if (!userDoc.exists) {
        console.error('User not found:', userId);
        return null;
      }

      const userData = userDoc.data();
      const fcmToken = userData.fcmToken;
      const notificationsEnabled = userData.notificationsEnabled !== false; // Default to true

      if (!notificationsEnabled) {
        console.log('Notifications disabled for user:', userId);
        await snap.ref.delete(); // Clean up the pending notification
        return null;
      }

      if (!fcmToken) {
        console.error('No FCM token for user:', userId);
        await snap.ref.delete();
        return null;
      }

      // Prepare the notification message
      const message = {
        notification: {
          title: '🎉 Spot Available!',
          body: `A spot opened up for ${className} on ${classTime}. You've been moved from the waitlist!`,
        },
        data: {
          type: 'waitlist_spot_available',
          classId: classId,
          className: className,
          classTime: classTime,
          click_action: 'FLUTTER_NOTIFICATION_CLICK',
        },
        token: fcmToken,
        android: {
          notification: {
            channelId: 'waitlist',
            priority: 'high',
            sound: 'default',
            color: '#FFC107', // Yellow color from app theme
          },
        },
        apns: {
          payload: {
            aps: {
              sound: 'default',
              badge: 1,
            },
          },
        },
      };

      // Send the notification
      const response = await admin.messaging().send(message);
      console.log('Successfully sent notification:', response);

      // Delete the pending notification after sending
      await snap.ref.delete();

      // Log the notification in user's history (optional)
      await admin.firestore().collection('users').doc(userId).collection('notifications').add({
        type: 'waitlist_spot_available',
        className: className,
        classTime: classTime,
        classId: classId,
        sentAt: admin.firestore.FieldValue.serverTimestamp(),
        read: false,
      });

      return response;
    } catch (error) {
      console.error('Error sending notification:', error);

      // Mark as failed instead of deleting so we can debug
      await snap.ref.update({
        failed: true,
        error: error.message,
        failedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      return null;
    }
  });

/**
 * Clean up old pending notifications (older than 24 hours)
 * Runs every day at midnight
 */
exports.cleanupOldNotifications = functions.pubsub
  .schedule('0 0 * * *')
  .timeZone('America/New_York') // Adjust to your timezone
  .onRun(async (context) => {
    const cutoff = admin.firestore.Timestamp.fromDate(
      new Date(Date.now() - 24 * 60 * 60 * 1000)
    );

    const oldNotifications = await admin
      .firestore()
      .collection('pendingNotifications')
      .where('timestamp', '<', cutoff)
      .get();

    const batch = admin.firestore().batch();
    oldNotifications.docs.forEach((doc) => {
      batch.delete(doc.ref);
    });

    await batch.commit();
    console.log(`Cleaned up ${oldNotifications.size} old notifications`);
    return null;
  });

/**
 * Update user's notification badge count
 * Triggered when a class booking or waitlist status changes
 */
exports.updateNotificationBadge = functions.firestore
  .document('classes/{classId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();

    // Check if participants or waitlist changed
    const participantsChanged =
      JSON.stringify(before.participants) !== JSON.stringify(after.participants);
    const waitlistChanged =
      JSON.stringify(before.waitlist) !== JSON.stringify(after.waitlist);

    if (!participantsChanged && !waitlistChanged) {
      return null;
    }

    // Find users who were added to participants from waitlist
    const newParticipants = after.participants.filter(
      (id) => !before.participants.includes(id) && before.waitlist.includes(id)
    );

    // Update badge count for each new participant
    const promises = newParticipants.map(async (userId) => {
      const userRef = admin.firestore().collection('users').doc(userId);
      const userDoc = await userRef.get();

      if (!userDoc.exists) return;

      const fcmToken = userDoc.data().fcmToken;
      if (!fcmToken) return;

      // Send a silent notification to update badge
      return admin.messaging().send({
        token: fcmToken,
        apns: {
          payload: {
            aps: {
              'content-available': 1,
              badge: 1,
            },
          },
        },
      });
    });

    await Promise.all(promises);
    return null;
  });
