# CrossFit Box App 🏋️

A modern, full-featured CrossFit box management application built with Flutter and Firebase. This app runs on iOS, Android, and Web platforms.

## 🌟 Features

### User Features
- **Authentication**: Secure sign-up and login with email/password
- **Class Scheduling**: Browse and book classes with a beautiful calendar interface
- **Workout of the Day (WOD)**: View daily workouts and log your results
- **Social Feed**: Share workout results, achievements, and interact with other members
- **Gamification**: Earn XP, level up, unlock badges, and compete on leaderboards
- **Direct Messaging**: Chat with other box members
- **Profile & Progress**: Track your stats, streaks, PRs, and achievements
- **Waitlist Management**: Automatic waitlist for full classes

### Admin Features
- **Class Management**: Create, edit, and manage classes
- **WOD Creation**: Design and publish Workouts of the Day
- **Attendance Tracking**: View participant lists and capacity management
- **Configurable Limits**: Easily adjust class capacity (default: 16)

### Gamification System
- **XP & Levels**: Earn experience points and level up
- **Badges**: 15+ unique achievements to unlock
- **Leaderboards**: Weekly, monthly, and all-time rankings
- **Streaks**: Track consecutive workout days
- **Personal Records**: Log and track your PRs

## 🎨 Design

The app features a **modern 2025 design** with:
- **Color Scheme**: Bold yellow (#FFC107) and deep black (#0A0A0A)
- **Material Design 3**: Latest design system with glassmorphism effects
- **Dark Theme**: Eye-friendly dark mode by default
- **Responsive**: Optimized for all screen sizes
- **Animations**: Smooth transitions and engaging micro-interactions

## 🚀 Getting Started

### Prerequisites

- **Flutter SDK**: Version 3.2.0 or higher
- **Firebase Account**: For backend services
- **IDE**: VS Code or Android Studio

### Installation

1. **Clone the repository**
   ```bash
   git clone <your-repo-url>
   cd crossfit_box
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Set up Firebase**

   a. Install FlutterFire CLI:
   ```bash
   dart pub global activate flutterfire_cli
   ```

   b. Create a Firebase project at [Firebase Console](https://console.firebase.google.com/)

   c. Configure Firebase for your app:
   ```bash
   flutterfire configure
   ```

   This will automatically generate the `lib/firebase_options.dart` file with your Firebase configuration.

4. **Enable Firebase Services**

   In your Firebase Console, enable:
   - **Authentication** → Email/Password provider
   - **Firestore Database** → Start in production mode
   - **Storage** → Start in production mode
   - **Cloud Functions** (optional, for advanced features)

5. **Configure Firestore Security Rules**

   In Firestore, add these security rules:

   ```javascript
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       // Users collection
       match /users/{userId} {
         allow read: if request.auth != null;
         allow write: if request.auth.uid == userId;
       }

       // Classes collection
       match /classes/{classId} {
         allow read: if request.auth != null;
         allow create: if request.auth != null && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
         allow update, delete: if request.auth != null && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
       }

       // Workouts collection
       match /workouts/{workoutId} {
         allow read: if request.auth != null;
         allow write: if request.auth != null && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
       }

       // Workout Results
       match /workoutResults/{resultId} {
         allow read: if request.auth != null;
         allow create: if request.auth != null;
         allow update, delete: if request.auth.uid == resource.data.userId;
       }

       // Posts (Social)
       match /posts/{postId} {
         allow read: if request.auth != null;
         allow create: if request.auth != null;
         allow update, delete: if request.auth.uid == resource.data.userId;
       }

       // Comments
       match /comments/{commentId} {
         allow read: if request.auth != null;
         allow create: if request.auth != null;
         allow delete: if request.auth.uid == resource.data.userId;
       }

       // Messages
       match /messages/{messageId} {
         allow read: if request.auth != null && request.auth.uid in resource.data.participants;
         allow create: if request.auth != null;
       }

       // Conversations
       match /conversations/{conversationId} {
         allow read: if request.auth != null && request.auth.uid in resource.data.participants;
         allow create, update: if request.auth != null;
       }
     }
   }
   ```

6. **Create an Admin User**

   After creating your first account, manually update your user document in Firestore:
   - Go to Firestore Database → `users` collection
   - Find your user document
   - Change the `role` field from `member` to `admin`

7. **Run the app**

   For web:
   ```bash
   flutter run -d chrome
   ```

   For iOS:
   ```bash
   flutter run -d ios
   ```

   For Android:
   ```bash
   flutter run -d android
   ```

## 📱 Platform-Specific Setup

### iOS

1. Navigate to `ios/` directory and install pods:
   ```bash
   cd ios
   pod install
   cd ..
   ```

2. Set minimum iOS deployment target to 12.0 in `ios/Podfile`:
   ```ruby
   platform :ios, '12.0'
   ```

### Android

1. Update `android/app/build.gradle`:
   ```gradle
   minSdkVersion 21
   targetSdkVersion 33
   ```

### Web

1. Ensure you have enabled Firebase Hosting in your Firebase Console
2. Update `web/index.html` if needed for custom configuration

## 🏗️ Project Structure

```
lib/
├── core/
│   ├── models/          # Data models
│   ├── services/        # Firebase services
│   ├── router/          # Navigation
│   └── theme/           # App theming
├── features/
│   ├── auth/            # Authentication
│   ├── home/            # Home page
│   ├── schedule/        # Class scheduling
│   ├── workout/         # Workout details
│   ├── social/          # Social feed
│   ├── leaderboard/     # Rankings
│   ├── profile/         # User profile
│   ├── messaging/       # Direct messages
│   └── admin/           # Admin dashboard
└── main.dart            # App entry point
```

## 🎯 Key Technologies

- **Flutter**: Cross-platform framework
- **Firebase Auth**: User authentication
- **Cloud Firestore**: Real-time database
- **Firebase Storage**: File storage
- **Riverpod**: State management
- **GoRouter**: Navigation
- **Google Fonts**: Inter font family
- **Material Design 3**: Modern UI components

## 🔧 Configuration

### Adjusting Class Capacity

The default class capacity is 16 students. To change this:

1. **Default for new classes**: Edit `lib/core/models/class_model.dart`:
   ```dart
   this.maxCapacity = 16, // Change this number
   ```

2. **For existing classes**: Admins can update capacity in the Admin Dashboard

### Customizing Colors

Edit `lib/core/theme/app_theme.dart` to customize:
- Primary yellow color
- Background blacks
- Accent colors
- Typography

## 📊 Database Collections

### Firestore Structure

- **users**: User profiles, XP, levels, badges
- **classes**: Class schedules, participants, waitlists
- **workouts**: WOD definitions
- **workoutResults**: User workout submissions
- **posts**: Social feed posts
- **comments**: Comments on posts
- **messages**: Direct messages
- **conversations**: Message threads

## 🚀 Deployment

### Web

```bash
flutter build web
firebase deploy --only hosting
```

### iOS

```bash
flutter build ios --release
# Then use Xcode to upload to App Store
```

### Android

```bash
flutter build appbundle --release
# Upload to Google Play Console
```

## 🤝 Contributing

This is a custom CrossFit box application. For modifications or features:
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## 📝 License

This project is proprietary software for your CrossFit box.

## 🆘 Support

For issues or questions:
- Check Firebase Console for backend errors
- Review Flutter logs: `flutter logs`
- Ensure all Firebase services are enabled
- Verify Firestore security rules are configured

## 🎨 Customization Tips

1. **Add Your Logo**: Replace the fitness_center icon in login page with your logo
2. **Box Name**: Update app name in `pubspec.yaml` and various pages
3. **Colors**: Adjust yellow/black theme to match your brand
4. **Badges**: Add custom badges in `badge_model.dart`
5. **Workout Types**: Extend workout types in `workout_model.dart`

## 📱 Screenshots

*Add screenshots of your app here after running it*

## 🏆 Credits

Built with Flutter and Firebase for a modern CrossFit box experience.

---

**Version**: 1.0.0
**Last Updated**: 2025

Happy training! 💪
