import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/workout_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/badge_model.dart';
import '../widgets/notification_settings.dart';

final userWorkoutsProvider = StreamProvider((ref) {
  final currentUser = ref.watch(currentUserProvider).value;
  if (currentUser == null) return const Stream.empty();
  return ref.watch(workoutServiceProvider).getUserWorkoutResults(currentUser.id);
});

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final userWorkouts = ref.watch(userWorkoutsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              // TODO: Settings page
            },
          ),
        ],
      ),
      body: currentUser.when(
        data: (user) {
          if (user == null) return const Center(child: Text('Not logged in'));

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(currentUserProvider);
              ref.invalidate(userWorkoutsProvider);
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile header
                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: AppTheme.primaryYellow,
                          backgroundImage: user.photoUrl != null
                              ? NetworkImage(user.photoUrl!)
                              : null,
                          child: user.photoUrl == null
                              ? Text(
                                  user.displayName[0].toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 48,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.deepBlack,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          user.displayName,
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.email,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                        ),
                        if (user.isAdmin) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryYellow.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppTheme.primaryYellow),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.admin_panel_settings, size: 16, color: AppTheme.primaryYellow),
                                SizedBox(width: 6),
                                Text(
                                  'ADMIN',
                                  style: TextStyle(
                                    color: AppTheme.primaryYellow,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Stats grid
                  _buildStatsGrid(context, user),
                  const SizedBox(height: 32),

                  // Level progress
                  _buildLevelProgress(context, user),
                  const SizedBox(height: 32),

                  // Notification Settings
                  const NotificationSettings(),
                  const SizedBox(height: 32),

                  // Badges
                  Text(
                    'Achievements',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  _buildBadgesSection(context, user),
                  const SizedBox(height: 32),

                  // Recent workouts
                  Text(
                    'Recent Workouts',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  userWorkouts.when(
                    data: (workouts) {
                      if (workouts.isEmpty) {
                        return _buildEmptyWorkouts(context);
                      }
                      return Column(
                        children: workouts.take(5).map((workout) {
                          return _buildWorkoutItem(context, workout);
                        }).toList(),
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (_, __) => const Center(child: Text('Error loading workouts')),
                  ),
                  const SizedBox(height: 32),

                  // Logout button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await ref.read(authServiceProvider).signOut();
                        if (context.mounted) {
                          context.go('/auth/login');
                        }
                      },
                      icon: const Icon(Icons.logout),
                      label: const Text('Sign Out'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.errorRed,
                        side: const BorderSide(color: AppTheme.errorRed),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Error loading profile')),
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context, user) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          context,
          icon: Icons.local_fire_department,
          label: 'Streak',
          value: '${user.attendanceStreak}',
          subtitle: 'days',
          color: AppTheme.errorRed,
        ),
        _buildStatCard(
          context,
          icon: Icons.trending_up,
          label: 'Level',
          value: '${user.level}',
          subtitle: '${user.xp} XP',
          color: AppTheme.primaryYellow,
        ),
        _buildStatCard(
          context,
          icon: Icons.fitness_center,
          label: 'Workouts',
          value: '${user.totalWorkouts}',
          subtitle: 'completed',
          color: AppTheme.infoBlue,
        ),
        _buildStatCard(
          context,
          icon: Icons.emoji_events,
          label: 'Badges',
          value: '${user.badges.length}',
          subtitle: 'earned',
          color: AppTheme.successGreen,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required String subtitle,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const Spacer(),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textTertiary,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelProgress(BuildContext context, user) {
    // Calculate progress to next level
    final currentLevelXP = user.level * 100;
    final nextLevelXP = (user.level + 1) * 100;
    final progress = (user.xp - currentLevelXP) / (nextLevelXP - currentLevelXP);

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Level ${user.level}',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppTheme.deepBlack,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                'Level ${user.level + 1}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.deepBlack.withOpacity(0.7),
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 12,
              backgroundColor: AppTheme.deepBlack.withOpacity(0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.deepBlack),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${nextLevelXP - user.xp} XP to next level',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.deepBlack.withOpacity(0.8),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgesSection(BuildContext context, user) {
    if (user.badges.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.surfaceBlack,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderGray),
        ),
        child: Center(
          child: Text(
            'No badges earned yet. Keep training!',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textTertiary,
                ),
          ),
        ),
      );
    }

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: user.badges.map<Widget>((badgeName) {
        final badgeType = BadgeType.values.firstWhere(
          (b) => b.name == badgeName,
          orElse: () => BadgeType.firstWorkout,
        );
        final badge = BadgeModel.getBadge(badgeType);

        return Container(
          width: 80,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.surfaceBlack,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.primaryYellow),
          ),
          child: Column(
            children: [
              Text(
                badge?.iconPath ?? '🏆',
                style: const TextStyle(fontSize: 32),
              ),
              const SizedBox(height: 8),
              Text(
                badge?.name ?? 'Badge',
                style: Theme.of(context).textTheme.labelSmall,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildWorkoutItem(BuildContext context, workout) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceBlack,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderGray),
      ),
      child: Row(
        children: [
          const Icon(Icons.fitness_center, color: AppTheme.primaryYellow),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  workout.workoutName,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                if (workout.result != null)
                  Text(
                    workout.result!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWorkouts(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceBlack,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderGray),
      ),
      child: Center(
        child: Column(
          children: [
            const Icon(
              Icons.fitness_center,
              size: 48,
              color: AppTheme.textTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              'No workouts yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Complete your first WOD to get started!',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textTertiary,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
