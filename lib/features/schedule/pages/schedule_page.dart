import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/services/class_service.dart';
import '../../../core/theme/app_theme.dart';
import '../widgets/class_card.dart';

final selectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

final classesForDateProvider = StreamProvider.family<List, DateTime>((ref, date) {
  return ref.watch(classServiceProvider).getClassesForDate(date);
});

class SchedulePage extends ConsumerWidget {
  const SchedulePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedDateProvider);
    final classesAsync = ref.watch(classesForDateProvider(selectedDate));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule'),
      ),
      body: Column(
        children: [
          // Date selector
          _buildDateSelector(context, ref, selectedDate),

          // Classes list
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(classesForDateProvider(selectedDate));
              },
              child: classesAsync.when(
                data: (classes) {
                  if (classes.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.calendar_today_outlined,
                            size: 64,
                            color: AppTheme.textTertiary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No classes scheduled',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Try selecting a different date',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.textTertiary,
                                ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: classes.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      return ClassCard(classModel: classes[index]);
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(child: Text('Error: $error')),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector(BuildContext context, WidgetRef ref, DateTime selectedDate) {
    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 14, // Show 2 weeks
        itemBuilder: (context, index) {
          final date = DateTime.now().add(Duration(days: index));
          final isSelected = DateFormat('yyyy-MM-dd').format(date) ==
              DateFormat('yyyy-MM-dd').format(selectedDate);

          return GestureDetector(
            onTap: () => ref.read(selectedDateProvider.notifier).state = date,
            child: Container(
              width: 70,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryYellow : AppTheme.surfaceBlack,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppTheme.primaryYellow : AppTheme.borderGray,
                  width: 2,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('EEE').format(date),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isSelected ? AppTheme.deepBlack : AppTheme.textSecondary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('d').format(date),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: isSelected ? AppTheme.deepBlack : AppTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
