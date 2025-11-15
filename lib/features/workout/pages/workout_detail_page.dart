import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/models/workout_model.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/workout_service.dart';
import '../../../core/services/gamification_service.dart';
import '../../../core/theme/app_theme.dart';

class WorkoutDetailPage extends ConsumerStatefulWidget {
  final WorkoutModel workout;

  const WorkoutDetailPage({super.key, required this.workout});

  @override
  ConsumerState<WorkoutDetailPage> createState() => _WorkoutDetailPageState();
}

class _WorkoutDetailPageState extends ConsumerState<WorkoutDetailPage> {
  final _resultController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isRx = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _resultController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitResult() async {
    if (_resultController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your result')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final currentUser = ref.read(currentUserProvider).value;
      if (currentUser == null) return;

      final result = WorkoutResultModel(
        id: '',
        userId: currentUser.id,
        userName: currentUser.displayName,
        userPhotoUrl: currentUser.photoUrl,
        workoutId: widget.workout.id,
        workoutName: widget.workout.name,
        result: _resultController.text,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        rxd: _isRx ? 1 : 0,
        completedAt: DateTime.now(),
      );

      await ref.read(workoutServiceProvider).submitWorkoutResult(result);

      // Award XP for completing workout
      await ref.read(gamificationServiceProvider).awardXP(
            currentUser.id,
            GamificationService.xpPerWorkout,
            reason: 'Completed workout: ${widget.workout.name}',
          );

      // Update workout streak
      await ref.read(gamificationServiceProvider).updateWorkoutStreak(currentUser.id);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Workout logged! +${GamificationService.xpPerWorkout} XP'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Workout header
            Container(
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
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.deepBlack.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          widget.workout.type.name.toUpperCase(),
                          style: const TextStyle(
                            color: AppTheme.deepBlack,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      if (widget.workout.duration != null) ...[
                        const SizedBox(width: 12),
                        const Icon(Icons.timer, size: 16, color: AppTheme.deepBlack),
                        const SizedBox(width: 6),
                        Text(
                          widget.workout.duration!,
                          style: const TextStyle(
                            color: AppTheme.deepBlack,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.workout.name,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: AppTheme.deepBlack,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Description
            Text(
              'Description',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.workout.description,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),

            // Movements
            if (widget.workout.movements.isNotEmpty) ...[
              Text(
                'Movements',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              ...widget.workout.movements.map((movement) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppTheme.primaryYellow,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            movement,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ),
                      ],
                    ),
                  )),
              const SizedBox(height: 24),
            ],

            // Scaling options
            if (widget.workout.scaling != null) ...[
              Text(
                'Scaling Options',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceBlack,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderGray),
                ),
                child: Text(
                  widget.workout.scaling!,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Log workout section
            const Divider(height: 32),
            Text(
              'Log Your Result',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),

            // Result input
            TextField(
              controller: _resultController,
              decoration: const InputDecoration(
                labelText: 'Result',
                hintText: 'e.g., 12:34, 150 reps, 225 lbs',
                prefixIcon: Icon(Icons.timer),
              ),
            ),
            const SizedBox(height: 16),

            // Notes input
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                hintText: 'How did it feel?',
                prefixIcon: Icon(Icons.notes),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // RX checkbox
            CheckboxListTile(
              value: _isRx,
              onChanged: (value) => setState(() => _isRx = value ?? false),
              title: const Text('RX\'d (as prescribed)'),
              contentPadding: EdgeInsets.zero,
              activeColor: AppTheme.primaryYellow,
            ),
            const SizedBox(height: 24),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitResult,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.deepBlack,
                        ),
                      )
                    : const Text('Submit Result'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
