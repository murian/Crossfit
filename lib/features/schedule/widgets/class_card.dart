import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/models/class_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/class_service.dart';

class ClassCard extends ConsumerWidget {
  final ClassModel classModel;

  const ClassCard({super.key, required this.classModel});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider).value;
    final isBooked = currentUser != null && classModel.participants.contains(currentUser.id);
    final isOnWaitlist = currentUser != null && classModel.waitlist.contains(currentUser.id);
    final waitlistPosition = isOnWaitlist
        ? classModel.waitlist.indexOf(currentUser!.id) + 1
        : 0;

    return Card(
      child: InkWell(
        onTap: () => _showClassDetails(context, ref),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Time and type
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 20,
                          color: AppTheme.primaryYellow,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat('h:mm a').format(classModel.startTime),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '•',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${classModel.endTime.difference(classModel.startTime).inMinutes} min',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                        ),
                      ],
                    ),
                  ),
                  if (isBooked)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.successGreen.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.check_circle,
                            size: 14,
                            color: AppTheme.successGreen,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Booked',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: AppTheme.successGreen,
                                ),
                          ),
                        ],
                      ),
                    ),
                  if (isOnWaitlist)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.warningOrange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.schedule, size: 12, color: AppTheme.warningOrange),
                          const SizedBox(width: 4),
                          Text(
                            'Waitlist #$waitlistPosition',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: AppTheme.warningOrange,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Class name
              Text(
                classModel.name,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              if (classModel.description != null) ...[
                const SizedBox(height: 4),
                Text(
                  classModel.description!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),

              // Coach and capacity
              Row(
                children: [
                  if (classModel.coachName != null) ...[
                    const Icon(
                      Icons.person_outline,
                      size: 16,
                      color: AppTheme.textTertiary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      classModel.coachName!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(width: 16),
                  ],
                  const Icon(
                    Icons.people_outline,
                    size: 16,
                    color: AppTheme.textTertiary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${classModel.participants.length}/${classModel.maxCapacity}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: classModel.isFull
                              ? AppTheme.errorRed
                              : AppTheme.textSecondary,
                        ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: classModel.participants.length / classModel.maxCapacity,
                      backgroundColor: AppTheme.borderGray,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        classModel.isFull ? AppTheme.errorRed : AppTheme.primaryYellow,
                      ),
                    ),
                  ),
                ],
              ),
              if (classModel.waitlist.isNotEmpty && !isOnWaitlist) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.people_outline,
                      size: 16,
                      color: AppTheme.warningOrange,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${classModel.waitlist.length} on waitlist',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.warningOrange,
                          ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showClassDetails(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => ClassDetailsSheet(
        classModel: classModel,
        onBook: () async {
          final currentUser = ref.read(currentUserProvider).value;
          if (currentUser == null) return;

          try {
            await ref.read(classServiceProvider).bookClass(classModel.id, currentUser.id);
            if (context.mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(classModel.isFull
                      ? 'Added to waitlist'
                      : 'Class booked successfully'),
                  backgroundColor: AppTheme.successGreen,
                ),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(e.toString()),
                  backgroundColor: AppTheme.errorRed,
                ),
              );
            }
          }
        },
        onCancel: () async {
          final currentUser = ref.read(currentUserProvider).value;
          if (currentUser == null) return;

          try {
            await ref.read(classServiceProvider).cancelBooking(classModel.id, currentUser.id);
            if (context.mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Booking cancelled'),
                  backgroundColor: AppTheme.successGreen,
                ),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(e.toString()),
                  backgroundColor: AppTheme.errorRed,
                ),
              );
            }
          }
        },
      ),
    );
  }
}

class ClassDetailsSheet extends ConsumerWidget {
  final ClassModel classModel;
  final VoidCallback onBook;
  final VoidCallback onCancel;

  const ClassDetailsSheet({
    super.key,
    required this.classModel,
    required this.onBook,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider).value;
    final isBooked = currentUser != null && classModel.participants.contains(currentUser.id);

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            classModel.name,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            DateFormat('EEEE, MMMM d • h:mm a').format(classModel.startTime),
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.primaryYellow,
                ),
          ),
          if (classModel.description != null) ...[
            const SizedBox(height: 16),
            Text(
              classModel.description!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  context,
                  icon: Icons.people,
                  label: 'Capacity',
                  value: '${classModel.participants.length}/${classModel.maxCapacity}',
                ),
              ),
              if (classModel.coachName != null)
                Expanded(
                  child: _buildInfoItem(
                    context,
                    icon: Icons.person,
                    label: 'Coach',
                    value: classModel.coachName!,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: isBooked
                ? OutlinedButton(
                    onPressed: onCancel,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.errorRed),
                      foregroundColor: AppTheme.errorRed,
                    ),
                    child: const Text('Cancel Booking'),
                  )
                : ElevatedButton(
                    onPressed: onBook,
                    child: Text(classModel.isFull ? 'Join Waitlist' : 'Book Class'),
                  ),
          ),
          SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
        ],
      ),
    );
  }

  Widget _buildInfoItem(BuildContext context,
      {required IconData icon, required String label, required String value}) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.primaryYellow),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textTertiary,
              ),
        ),
      ],
    );
  }
}
