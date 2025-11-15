import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/gamification_service.dart';
import '../../../core/theme/app_theme.dart';

final leaderboardTypeProvider = StateProvider<LeaderboardType>((ref) => LeaderboardType.allTime);

final leaderboardProvider = FutureProvider.family<List<LeaderboardEntry>, LeaderboardType>((ref, type) async {
  return ref.watch(gamificationServiceProvider).getLeaderboard(type: type);
});

class LeaderboardPage extends ConsumerWidget {
  const LeaderboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedType = ref.watch(leaderboardTypeProvider);
    final leaderboardAsync = ref.watch(leaderboardProvider(selectedType));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboard'),
      ),
      body: Column(
        children: [
          // Type selector
          _buildTypeSelector(context, ref, selectedType),

          // Leaderboard list
          Expanded(
            child: leaderboardAsync.when(
              data: (entries) {
                if (entries.isEmpty) {
                  return const Center(
                    child: Text('No data available'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    return _buildLeaderboardItem(context, entry);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('Error: $error')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeSelector(BuildContext context, WidgetRef ref, LeaderboardType selected) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildTypeButton(
              context,
              ref,
              'All Time',
              LeaderboardType.allTime,
              selected == LeaderboardType.allTime,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildTypeButton(
              context,
              ref,
              'Monthly',
              LeaderboardType.monthly,
              selected == LeaderboardType.monthly,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildTypeButton(
              context,
              ref,
              'Weekly',
              LeaderboardType.weekly,
              selected == LeaderboardType.weekly,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeButton(
    BuildContext context,
    WidgetRef ref,
    String label,
    LeaderboardType type,
    bool isSelected,
  ) {
    return ElevatedButton(
      onPressed: () => ref.read(leaderboardTypeProvider.notifier).state = type,
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? AppTheme.primaryYellow : AppTheme.surfaceBlack,
        foregroundColor: isSelected ? AppTheme.deepBlack : AppTheme.textSecondary,
        padding: const EdgeInsets.symmetric(vertical: 12),
        elevation: 0,
      ),
      child: Text(label),
    );
  }

  Widget _buildLeaderboardItem(BuildContext context, LeaderboardEntry entry) {
    final isMedalist = entry.rank <= 3;
    Color? medalColor;
    IconData? medalIcon;

    if (entry.rank == 1) {
      medalColor = const Color(0xFFFFD700); // Gold
      medalIcon = Icons.looks_one;
    } else if (entry.rank == 2) {
      medalColor = const Color(0xFFC0C0C0); // Silver
      medalIcon = Icons.looks_two;
    } else if (entry.rank == 3) {
      medalColor = const Color(0xFFCD7F32); // Bronze
      medalIcon = Icons.looks_3;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isMedalist ? AppTheme.surfaceBlack : AppTheme.deepBlack,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isMedalist ? medalColor! : AppTheme.borderGray,
          width: isMedalist ? 2 : 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: SizedBox(
          width: 40,
          child: isMedalist
              ? Icon(medalIcon, color: medalColor, size: 32)
              : Center(
                  child: Text(
                    '#${entry.rank}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textTertiary,
                        ),
                  ),
                ),
        ),
        title: Text(
          entry.user.displayName,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        subtitle: Row(
          children: [
            const Icon(Icons.local_fire_department, size: 16, color: AppTheme.errorRed),
            const SizedBox(width: 4),
            Text('Level ${entry.user.level}'),
            const SizedBox(width: 12),
            const Icon(Icons.fitness_center, size: 16, color: AppTheme.primaryYellow),
            const SizedBox(width: 4),
            Text('${entry.user.totalWorkouts} workouts'),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${entry.user.xp}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryYellow,
                  ),
            ),
            Text(
              'XP',
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
