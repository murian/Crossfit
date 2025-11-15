# Quick Setup Guide

## 🚀 5-Minute Setup

### Step 1: Install Flutter
If you haven't already, install Flutter SDK from [flutter.dev](https://flutter.dev)

### Step 2: Install Dependencies
```bash
flutter pub get
```

### Step 3: Set Up Firebase

**Option A: Automatic (Recommended)**
```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure Firebase (this will prompt you to select/create a project)
flutterfire configure
```

**Option B: Manual**
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project
3. Add iOS, Android, and Web apps
4. Download config files:
   - iOS: `GoogleService-Info.plist` → `ios/Runner/`
   - Android: `google-services.json` → `android/app/`
   - Web: Copy config to `lib/firebase_options.dart`

### Step 4: Enable Firebase Services

In Firebase Console:
1. **Authentication** → Sign-in method → Enable "Email/Password"
2. **Firestore Database** → Create database → Start in production mode
3. **Storage** → Get started → Start in production mode

### Step 5: Add Firestore Rules

Copy these rules in Firestore → Rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

### Step 6: Run the App

```bash
# For web
flutter run -d chrome

# For iOS simulator
flutter run -d ios

# For Android emulator
flutter run -d android
```

### Step 7: Create Your Admin Account

1. Sign up in the app with your email
2. Go to Firebase Console → Firestore
3. Find your user document in the `users` collection
4. Edit the document and change `role` from `"member"` to `"admin"`

That's it! You now have admin access 🎉

## 🔧 Troubleshooting

### "Firebase not configured" error
- Make sure you ran `flutterfire configure`
- Check that `lib/firebase_options.dart` exists and has your config

### Build errors
```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter run
```

### iOS Pod errors
```bash
cd ios
rm -rf Pods Podfile.lock
pod install --repo-update
cd ..
flutter run
```

### Android build errors
- Ensure `minSdkVersion` is 21 or higher in `android/app/build.gradle`

## 📱 Platform-Specific Notes

### iOS
- Requires macOS with Xcode installed
- Run `pod install` in the `ios/` directory
- Minimum iOS version: 12.0

### Android
- Minimum SDK: 21 (Android 5.0)
- Target SDK: 33

### Web
- Works in any modern browser
- Best experience in Chrome

## 🎯 Next Steps

1. **Customize branding**: Update colors in `lib/core/theme/app_theme.dart`
2. **Add your logo**: Replace icon assets
3. **Create classes**: Use admin dashboard to add classes
4. **Create WODs**: Add workouts of the day
5. **Invite members**: Share sign-up link

## 📚 More Help

- Full documentation: [README.md](README.md)
- Flutter docs: [flutter.dev/docs](https://flutter.dev/docs)
- Firebase docs: [firebase.google.com/docs](https://firebase.google.com/docs)

Happy coding! 💪
