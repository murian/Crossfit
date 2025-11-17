# Waitlist Notifications Feature 🔔

Complete push notification system for waitlist management in the CrossFit Box app.

## 🎯 Feature Overview

When a class is full and a user joins the waitlist, they will receive a **push notification** when:
- Someone cancels their booking
- A spot opens up
- They are automatically moved from waitlist to the class

## ✨ What's Included

### User Experience
1. **Join Waitlist**: When a class is full, tap "Join Waitlist"
2. **See Position**: Users see their position (e.g., "Waitlist #3")
3. **Get Notified**: Receive push notification when spot opens
4. **Auto-Book**: Automatically moved to the class (no action needed!)
5. **Manage Settings**: Toggle notifications on/off in profile

### Admin Experience
- View waitlist counts for each class
- See who's on waitlist
- Automatic waitlist management (no manual work!)

## 📱 Setup Instructions

### Step 1: Enable Firebase Cloud Messaging

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Go to **Project Settings** → **Cloud Messaging**
4. Enable **Firebase Cloud Messaging API (V1)**

### Step 2: Configure Android

1. In `android/app/build.gradle`, add:
   ```gradle
   android {
       ...
       defaultConfig {
           ...
           minSdkVersion 21  // FCM requires minimum SDK 21
       }
   }
   ```

2. Create `android/app/src/main/res/values/colors.xml`:
   ```xml
   <?xml version="1.0" encoding="utf-8"?>
   <resources>
       <color name="notification_color">#FFC107</color>
   </resources>
   ```

3. In `android/app/src/main/AndroidManifest.xml`, add:
   ```xml
   <manifest ...>
       <uses-permission android:name="android.permission.INTERNET"/>
       <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
       <uses-permission android:name="android.permission.VIBRATE" />

       <application ...>
           <!-- FCM default notification channel -->
           <meta-data
               android:name="com.google.firebase.messaging.default_notification_channel_id"
               android:value="waitlist" />

           <!-- FCM default notification color -->
           <meta-data
               android:name="com.google.firebase.messaging.default_notification_color"
               android:resource="@color/notification_color" />
       </application>
   </manifest>
   ```

### Step 3: Configure iOS

1. In Xcode, open `ios/Runner.xcworkspace`

2. Enable Push Notifications:
   - Select **Runner** target
   - Go to **Signing & Capabilities**
   - Click **+ Capability**
   - Add **Push Notifications**
   - Add **Background Modes**
   - Check **Remote notifications**

3. Get your APNs key:
   - Go to [Apple Developer](https://developer.apple.com/)
   - Certificates, Identifiers & Profiles → Keys
   - Create a new key with **Apple Push Notifications service (APNs)**
   - Download the `.p8` file

4. Upload APNs key to Firebase:
   - Firebase Console → Project Settings → Cloud Messaging
   - iOS app configuration → APNs Authentication Key
   - Upload your `.p8` file
   - Enter Key ID and Team ID

### Step 4: Configure Web

1. In Firebase Console → Project Settings → Cloud Messaging
2. Under **Web configuration**, copy your **Web Push certificate**

3. Create `web/firebase-messaging-sw.js`:
   ```javascript
   importScripts('https://www.gstatic.com/firebasejs/9.0.0/firebase-app-compat.js');
   importScripts('https://www.gstatic.com/firebasejs/9.0.0/firebase-messaging-compat.js');

   firebase.initializeApp({
     apiKey: "YOUR_API_KEY",
     authDomain: "YOUR_PROJECT_ID.firebaseapp.com",
     projectId: "YOUR_PROJECT_ID",
     storageBucket: "YOUR_PROJECT_ID.appspot.com",
     messagingSenderId: "YOUR_SENDER_ID",
     appId: "YOUR_APP_ID"
   });

   const messaging = firebase.messaging();

   messaging.onBackgroundMessage((payload) => {
     console.log('Received background message ', payload);
     const notificationTitle = payload.notification.title;
     const notificationOptions = {
       body: payload.notification.body,
       icon: '/icons/Icon-192.png'
     };

     self.registration.showNotification(notificationTitle, notificationOptions);
   });
   ```

### Step 5: Deploy Cloud Functions

1. Install Firebase CLI:
   ```bash
   npm install -g firebase-tools
   ```

2. Login to Firebase:
   ```bash
   firebase login
   ```

3. Initialize Functions (if not done):
   ```bash
   firebase init functions
   # Select JavaScript
   # Select your project
   # Install dependencies
   ```

4. Deploy the functions:
   ```bash
   cd functions
   npm install
   cd ..
   firebase deploy --only functions
   ```

5. Verify deployment:
   - Go to Firebase Console → Functions
   - You should see:
     - `sendWaitlistNotification`
     - `cleanupOldNotifications`
     - `updateNotificationBadge`

### Step 6: Test the Feature

1. **As User A**:
   - Find a class
   - Book the class (or fill it to capacity)

2. **As User B**:
   - Try to book the same class
   - You'll be added to waitlist
   - Note your position (e.g., "Waitlist #1")

3. **As User A**:
   - Cancel your booking

4. **As User B**:
   - You should receive a push notification!
   - Message: "🎉 Spot Available! A spot opened up for [Class Name]..."
   - You're automatically moved to the class

## 🔧 Configuration

### Notification Settings

Users can manage notifications in their **Profile** page:
- Toggle: "Waitlist Notifications"
- When disabled: No push notifications sent
- When enabled: Notifications request permission automatically

### Customizing Notification Text

Edit `functions/index.js`:

```javascript
const message = {
  notification: {
    title: '🎉 Spot Available!',  // Change this
    body: `A spot opened up for ${className}...`,  // Change this
  },
  // ... rest of config
};
```

### Adjusting Class Capacity

In admin dashboard or `class_model.dart`:
```dart
this.maxCapacity = 16, // Change default capacity
```

## 📊 How It Works

### Architecture

```
User Cancels Booking
        ↓
ClassService.cancelBooking()
        ↓
Move first waitlist user to participants
        ↓
Create pendingNotification in Firestore
        ↓
Cloud Function triggered
        ↓
Fetch user's FCM token
        ↓
Send push notification via FCM
        ↓
User receives notification
```

### Data Flow

1. **Client Side** (`class_service.dart`):
   - Detects someone from waitlist should be notified
   - Calls `_sendWaitlistNotification()`
   - Creates document in `pendingNotifications` collection

2. **Server Side** (Cloud Function):
   - Firestore trigger on `pendingNotifications` onCreate
   - Fetches user's FCM token from `users` collection
   - Sends notification via FCM API
   - Deletes pending notification
   - Logs notification in user's history

3. **Client Receives**:
   - App in foreground: `FirebaseMessaging.onMessage`
   - App in background: System notification
   - App terminated: System notification with data payload

## 🔐 Security Rules

Add to Firestore rules:

```javascript
match /pendingNotifications/{notificationId} {
  allow create: if request.auth != null;
  allow read, delete: if false; // Only Cloud Functions can read/delete
}

match /users/{userId}/notifications/{notificationId} {
  allow read: if request.auth.uid == userId;
  allow create, delete: if false; // Only Cloud Functions can write
}
```

## 🐛 Troubleshooting

### Notifications Not Received

1. **Check FCM token saved**:
   - Go to Firestore → users → [your user]
   - Verify `fcmToken` field exists

2. **Check notification settings**:
   - Profile → Notifications → Ensure enabled
   - Device settings → App → Notifications → Allowed

3. **Check Cloud Function logs**:
   ```bash
   firebase functions:log
   ```

4. **Test manually**:
   - Firebase Console → Cloud Messaging → Send test message
   - Enter your FCM token

### iOS Not Working

1. **Verify APNs certificate uploaded** (Firebase Console)
2. **Check Xcode capabilities** (Push Notifications enabled)
3. **Test on real device** (not simulator)
4. **Check provisioning profile** includes Push Notifications

### Android Not Working

1. **Verify `google-services.json`** in `android/app/`
2. **Check permissions** in AndroidManifest.xml
3. **Minimum SDK 21 or higher**
4. **Test on real device** for best results

### Cloud Function Errors

```bash
# View logs
firebase functions:log --only sendWaitlistNotification

# Common issues:
# - Missing FCM token → User didn't grant permission
# - Invalid token → Token expired, user needs to re-login
# - Authentication error → Check service account permissions
```

## 📈 Monitoring

### View Notification Stats

1. **Firebase Console** → **Cloud Messaging**
   - Total sends
   - Delivery rate
   - Open rate

2. **Cloud Function Logs**
   ```bash
   firebase functions:log --only sendWaitlistNotification
   ```

3. **Firestore Collections**
   - `pendingNotifications`: Queue (should be mostly empty)
   - `users/{userId}/notifications`: History per user

## 🎨 Customization Ideas

### Add More Notification Types

1. **Class Reminder** (24h before):
   ```javascript
   exports.sendClassReminders = functions.pubsub
     .schedule('0 9 * * *')
     .onRun(async (context) => {
       // Find classes 24h from now
       // Send reminders to participants
     });
   ```

2. **New WOD Posted**:
   ```javascript
   exports.notifyNewWOD = functions.firestore
     .document('workouts/{workoutId}')
     .onCreate(async (snap, context) => {
       if (snap.data().isWOD) {
         // Notify all users
       }
     });
   ```

3. **Achievement Unlocked**:
   - Add to `gamification_service.dart`
   - Send notification when badge earned

### Notification Channels (Android)

Create different channels for different priorities:

```javascript
android: {
  notification: {
    channelId: 'high_priority', // or 'low_priority'
    priority: 'high',
  },
}
```

## 💡 Best Practices

1. **Don't spam**: Only send important notifications
2. **Allow opt-out**: Users can disable in settings
3. **Clear messages**: Include class name and time
4. **Test thoroughly**: On all platforms before release
5. **Monitor failures**: Check logs regularly
6. **Handle tokens**: Update when they refresh
7. **Respect permissions**: Don't ask repeatedly if denied

## 📚 Resources

- [Firebase Cloud Messaging Docs](https://firebase.google.com/docs/cloud-messaging)
- [Flutter Firebase Messaging](https://firebase.flutter.dev/docs/messaging/overview)
- [iOS Push Notifications Guide](https://developer.apple.com/notifications/)
- [Android Notification Channels](https://developer.android.com/develop/ui/views/notifications/channels)

## ✅ Feature Checklist

- [x] FCM token storage in user model
- [x] Notification service implementation
- [x] Permission handling
- [x] Waitlist logic with notifications
- [x] Cloud Functions for sending
- [x] UI for notification settings
- [x] Waitlist position display
- [x] Background message handler
- [x] Foreground message handler
- [x] Notification history tracking
- [x] Auto-cleanup old notifications
- [x] Error handling and logging

---

**Your waitlist notification system is ready!** 🎉

Users will love getting notified when spots open up, and you'll love the automatic management. No more manual work tracking waitlists!

Need help? Check the troubleshooting section or Firebase logs.
