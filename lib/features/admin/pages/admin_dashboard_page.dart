import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/class_service.dart';
import '../../../core/services/workout_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/class_model.dart';
import '../../../core/models/workout_model.dart';

class AdminDashboardPage extends ConsumerWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider).value;

    if (currentUser?.isAdmin != true) {
      return Scaffold(
        appBar: AppBar(title: const Text('Admin')),
        body: const Center(
          child: Text('Access denied. Admin only.'),
        ),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Dashboard'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Classes', icon: Icon(Icons.calendar_today)),
              Tab(text: 'Workouts', icon: Icon(Icons.fitness_center)),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            ClassesTab(),
            WorkoutsTab(),
          ],
        ),
      ),
    );
  }
}

class ClassesTab extends ConsumerWidget {
  const ClassesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final upcomingClasses = ref.watch(upcomingClassesProvider);

    return Scaffold(
      body: upcomingClasses.when(
        data: (classes) {
          if (classes.isEmpty) {
            return const Center(child: Text('No upcoming classes'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: classes.length,
            itemBuilder: (context, index) {
              return _buildClassManagementCard(context, ref, classes[index]);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateClassDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add Class'),
      ),
    );
  }

  Widget _buildClassManagementCard(BuildContext context, WidgetRef ref, ClassModel classModel) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    classModel.name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: AppTheme.errorRed),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete Class'),
                        content: const Text('Are you sure you want to delete this class?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.errorRed,
                            ),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      await ref.read(classServiceProvider).deleteClass(classModel.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Class deleted')),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.people, size: 20, color: AppTheme.primaryYellow),
                const SizedBox(width: 8),
                Text(
                  '${classModel.participants.length}/${classModel.maxCapacity} participants',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            if (classModel.waitlist.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.schedule, size: 20, color: AppTheme.warningOrange),
                  const SizedBox(width: 8),
                  Text(
                    '${classModel.waitlist.length} on waitlist',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Text(
              'Participants: ${classModel.participants.length > 0 ? classModel.participants.join(", ") : "None"}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textTertiary,
                  ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateClassDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.now();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Class'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Class Name'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) {
                    selectedDate = date;
                  }
                },
                child: const Text('Select Date'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty) return;

              final startTime = DateTime(
                selectedDate.year,
                selectedDate.month,
                selectedDate.day,
                selectedTime.hour,
                selectedTime.minute,
              );

              final newClass = ClassModel(
                id: '',
                name: nameController.text,
                description: descriptionController.text,
                type: ClassType.crossfit,
                startTime: startTime,
                endTime: startTime.add(const Duration(hours: 1)),
              );

              await ref.read(classServiceProvider).createClass(newClass);

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Class created successfully')),
                );
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}

class WorkoutsTab extends ConsumerWidget {
  const WorkoutsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workoutsAsync = ref.watch(allWorkoutsProvider);

    return Scaffold(
      body: workoutsAsync.when(
        data: (workouts) {
          if (workouts.isEmpty) {
            return const Center(child: Text('No workouts created yet'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: workouts.length,
            itemBuilder: (context, index) {
              return _buildWorkoutCard(context, ref, workouts[index]);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateWorkoutDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add WOD'),
      ),
    );
  }

  Widget _buildWorkoutCard(BuildContext context, WidgetRef ref, WorkoutModel workout) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    workout.name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                if (workout.isWOD)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryYellow.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppTheme.primaryYellow),
                    ),
                    child: const Text(
                      'TODAY\'S WOD',
                      style: TextStyle(
                        color: AppTheme.primaryYellow,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              workout.description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (!workout.isWOD) ...[
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () async {
                  await ref.read(workoutServiceProvider).setAsWOD(workout.id, DateTime.now());
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Set as today\'s WOD')),
                    );
                  }
                },
                child: const Text('Set as Today\'s WOD'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showCreateWorkoutDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Workout'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Workout Name'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 5,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty) return;

              final currentUser = ref.read(currentUserProvider).value;
              if (currentUser == null) return;

              final workout = WorkoutModel(
                id: '',
                name: nameController.text,
                description: descriptionController.text,
                type: WorkoutType.custom,
                movements: [],
                createdAt: DateTime.now(),
                createdBy: currentUser.id,
              );

              await ref.read(workoutServiceProvider).createWorkout(workout);

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Workout created successfully')),
                );
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}

final allWorkoutsProvider = StreamProvider((ref) {
  return ref.watch(workoutServiceProvider).getAllWorkouts();
});

final upcomingClassesProvider = StreamProvider((ref) {
  return ref.watch(classServiceProvider).getUpcomingClasses();
});
