import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/workout_service.dart';
import '../../../core/services/class_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/workout_model.dart';
import '../../../core/models/class_model.dart';
import '../../workout/widgets/wod_card.dart';
import '../../schedule/widgets/class_card.dart';

final todaysWODProvider = StreamProvider<WorkoutModel?>((ref) {
  return ref.watch(workoutServiceProvider).getTodaysWOD();
});

final upcomingClassesProvider = StreamProvider<List<ClassModel>>((ref) {
  return ref.watch(classServiceProvider).getUpcomingClasses();
});

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final todaysWOD = ref.watch(todaysWODProvider);
    final upcomingClasses = ref.watch(upcomingClassesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('CrossFit Box'),
            Text(
              DateFormat('EEEE, MMMM d').format(DateTime.now()),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.message_outlined),
            onPressed: () => context.go('/messages'),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: Implement notifications
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(todaysWODProvider);
          ref.invalidate(upcomingClassesProvider);
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome section
              currentUser.when(
                data: (user) {
                  if (user == null) return const SizedBox();
                  return _buildWelcomeSection(context, user.displayName);
                },
                loading: () => const SizedBox(),
                error: (_, __) => const SizedBox(),
              ),
              const SizedBox(height: 24),

              // Quick stats
              currentUser.when(
                data: (user) {
                  if (user == null) return const SizedBox();
                  return _buildQuickStats(context, user);
                },
                loading: () => const SizedBox(),
                error: (_, __) => const SizedBox(),
              ),
              const SizedBox(height: 32),

              // Today's WOD
              Text(
                'Today\'s WOD',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              todaysWOD.when(
                data: (wod) {
                  if (wod == null) {
                    return _buildNoWODCard(context);
                  }
                  return WODCard(workout: wod);
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const Center(child: Text('Error loading WOD')),
              ),
              const SizedBox(height: 32),

              // Upcoming Classes
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Upcoming Classes',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  TextButton(
                    onPressed: () => context.go('/schedule'),
                    child: const Text('View All'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              upcomingClasses.when(
                data: (classes) {
                  if (classes.isEmpty) {
                    return _buildNoClassesCard(context);
                  }
                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: classes.length > 3 ? 3 : classes.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      return ClassCard(classModel: classes[index]);
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const Center(child: Text('Error loading classes')),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: currentUser.when(
        data: (user) {
          if (user?.isAdmin == true) {
            return FloatingActionButton.extended(
              onPressed: () => context.go('/admin'),
              icon: const Icon(Icons.admin_panel_settings),
              label: const Text('Admin'),
            );
          }
          return null;
        },
        loading: () => null,
        error: (_, __) => null,
      ),
    );
  }

  Widget _buildWelcomeSection(BuildContext context, String name) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryYellow, AppTheme.darkYellow],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back,',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppTheme.deepBlack,
                      ),
                ),
                Text(
                  name,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: AppTheme.deepBlack,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Ready to crush today\'s WOD?',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.deepBlack.withOpacity(0.8),
                      ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.fitness_center,
            size: 60,
            color: AppTheme.deepBlack,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context, user) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            context,
            icon: Icons.local_fire_department,
            label: 'Streak',
            value: '${user.attendanceStreak}',
            color: AppTheme.errorRed,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            context,
            icon: Icons.trending_up,
            label: 'Level',
            value: '${user.level}',
            color: AppTheme.primaryYellow,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            context,
            icon: Icons.emoji_events,
            label: 'Workouts',
            value: '${user.totalWorkouts}',
            color: AppTheme.infoBlue,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceBlack,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderGray),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildNoWODCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceBlack,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderGray),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.calendar_today_outlined,
            size: 48,
            color: AppTheme.textTertiary,
          ),
          const SizedBox(height: 16),
          Text(
            'No WOD scheduled for today',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Check back later or contact your coach',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textTertiary,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoClassesCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceBlack,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderGray),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.event_busy_outlined,
            size: 48,
            color: AppTheme.textTertiary,
          ),
          const SizedBox(height: 16),
          Text(
            'No upcoming classes',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}
