import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:google_fonts/google_fonts.dart';
import 'firebase_options.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Set up background message handler
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  runApp(
    const ProviderScope(
      child: CrossFitBoxApp(),
    ),
  );
}

class CrossFitBoxApp extends ConsumerStatefulWidget {
  const CrossFitBoxApp({super.key});

  @override
  ConsumerState<CrossFitBoxApp> createState() => _CrossFitBoxAppState();
}

class _CrossFitBoxAppState extends ConsumerState<CrossFitBoxApp> {
  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    // Wait for user to be authenticated, then initialize notifications
    Future.delayed(const Duration(seconds: 2), () {
      final currentUser = ref.read(currentUserProvider).value;
      if (currentUser != null) {
        ref.read(notificationServiceProvider).initialize(currentUser.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'CrossFit Box',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark, // Default to dark for yellow/black aesthetic
      routerConfig: router,
    );
  }
}
