import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';
import '../../features/auth/pages/login_page.dart';
import '../../features/auth/pages/signup_page.dart';
import '../../features/home/pages/home_page.dart';
import '../../features/schedule/pages/schedule_page.dart';
import '../../features/social/pages/social_feed_page.dart';
import '../../features/profile/pages/profile_page.dart';
import '../../features/leaderboard/pages/leaderboard_page.dart';
import '../../features/messaging/pages/conversations_page.dart';
import '../../features/admin/pages/admin_dashboard_page.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isAuthenticated = authState.value != null;
      final isAuthRoute = state.matchedLocation.startsWith('/auth');

      if (!isAuthenticated && !isAuthRoute) {
        return '/auth/login';
      }

      if (isAuthenticated && isAuthRoute) {
        return '/';
      }

      return null;
    },
    routes: [
      // Auth routes
      GoRoute(
        path: '/auth/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/auth/signup',
        builder: (context, state) => const SignupPage(),
      ),

      // Main app routes
      ShellRoute(
        builder: (context, state, child) {
          return MainScaffold(child: child);
        },
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const HomePage(),
          ),
          GoRoute(
            path: '/schedule',
            builder: (context, state) => const SchedulePage(),
          ),
          GoRoute(
            path: '/social',
            builder: (context, state) => const SocialFeedPage(),
          ),
          GoRoute(
            path: '/leaderboard',
            builder: (context, state) => const LeaderboardPage(),
          ),
          GoRoute(
            path: '/messages',
            builder: (context, state) => const ConversationsPage(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfilePage(),
          ),
          GoRoute(
            path: '/admin',
            builder: (context, state) => const AdminDashboardPage(),
          ),
        ],
      ),
    ],
  );
});

// Main scaffold with bottom navigation
class MainScaffold extends ConsumerWidget {
  final Widget child;

  const MainScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: child,
      bottomNavigationBar: const MainBottomNav(),
    );
  }
}

class MainBottomNav extends ConsumerWidget {
  const MainBottomNav({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocation = GoRouterState.of(context).matchedLocation;

    return NavigationBar(
      selectedIndex: _calculateSelectedIndex(currentLocation),
      onDestinationSelected: (index) => _onItemTapped(index, context),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.calendar_today_outlined),
          selectedIcon: Icon(Icons.calendar_today),
          label: 'Schedule',
        ),
        NavigationDestination(
          icon: Icon(Icons.people_outline),
          selectedIcon: Icon(Icons.people),
          label: 'Social',
        ),
        NavigationDestination(
          icon: Icon(Icons.leaderboard_outlined),
          selectedIcon: Icon(Icons.leaderboard),
          label: 'Leaderboard',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }

  int _calculateSelectedIndex(String location) {
    if (location == '/') return 0;
    if (location.startsWith('/schedule')) return 1;
    if (location.startsWith('/social')) return 2;
    if (location.startsWith('/leaderboard')) return 3;
    if (location.startsWith('/profile')) return 4;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/schedule');
        break;
      case 2:
        context.go('/social');
        break;
      case 3:
        context.go('/leaderboard');
        break;
      case 4:
        context.go('/profile');
        break;
    }
  }
}
