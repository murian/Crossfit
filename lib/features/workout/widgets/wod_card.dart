import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/workout_model.dart';
import '../../../core/theme/app_theme.dart';
import '../pages/workout_detail_page.dart';

class WODCard extends ConsumerWidget {
  final WorkoutModel workout;

  const WODCard({super.key, required this.workout});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => WorkoutDetailPage(workout: workout),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryYellow.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.wb_sunny,
                          size: 16,
                          color: AppTheme.primaryYellow,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          workout.type.name.toUpperCase(),
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: AppTheme.primaryYellow,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                  ),
                  if (workout.duration != null) ...[
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.infoBlue.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.timer_outlined,
                            size: 16,
                            color: AppTheme.infoBlue,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            workout.duration!,
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: AppTheme.infoBlue,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),

              // Workout name
              Text(
                workout.name,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryYellow,
                    ),
              ),
              const SizedBox(height: 12),

              // Description
              Text(
                workout.description,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),

              // Movements
              if (workout.movements.isNotEmpty) ...[
                const Divider(),
                const SizedBox(height: 16),
                Text(
                  'Movements:',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppTheme.primaryYellow,
                      ),
                ),
                const SizedBox(height: 8),
                ...workout.movements.map((movement) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            size: 16,
                            color: AppTheme.successGreen,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              movement,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    )),
              ],

              // Action button
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => WorkoutDetailPage(workout: workout),
                      ),
                    );
                  },
                  icon: const Icon(Icons.fitness_center),
                  label: const Text('Log Workout'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
