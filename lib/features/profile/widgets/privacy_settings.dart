import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/gdpr_service.dart';
import '../../../core/theme/app_theme.dart';
import 'package:go_router/go_router.dart';

class PrivacySettings extends ConsumerStatefulWidget {
  const PrivacySettings({super.key});

  @override
  ConsumerState<PrivacySettings> createState() => _PrivacySettingsState();
}

class _PrivacySettingsState extends ConsumerState<PrivacySettings> {
  bool _isExporting = false;
  bool _isDeleting = false;

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider).value;

    if (currentUser == null) return const SizedBox();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.privacy_tip_outlined, color: AppTheme.primaryYellow),
                const SizedBox(width: 12),
                Text(
                  'Privacy & Data',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // GDPR Info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.infoBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.infoBlue.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 20, color: AppTheme.infoBlue),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Your data is protected under GDPR. You have the right to access, export, and delete your data.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Export Data Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isExporting ? null : () => _exportData(currentUser.id),
                icon: _isExporting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.download_outlined),
                label: Text(_isExporting ? 'Exporting...' : 'Export My Data'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryYellow,
                  side: const BorderSide(color: AppTheme.primaryYellow),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Download all your personal data in JSON format',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textTertiary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            const Divider(),
            const SizedBox(height: 20),

            // Delete Account Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isDeleting ? null : () => _showDeleteConfirmation(currentUser.id),
                icon: _isDeleting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.delete_forever_outlined),
                label: Text(_isDeleting ? 'Deleting...' : 'Delete Account'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.errorRed,
                  side: const BorderSide(color: AppTheme.errorRed),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Permanently delete your account and all data',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.errorRed,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // Privacy Policy Link
            Center(
              child: TextButton.icon(
                onPressed: () => _showPrivacyPolicy(context),
                icon: const Icon(Icons.article_outlined, size: 18),
                label: const Text('Privacy Policy'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportData(String userId) async {
    setState(() => _isExporting = true);

    try {
      final gdprService = ref.read(gdprServiceProvider);
      final userData = await gdprService.exportUserData(userId);
      final jsonData = gdprService.exportUserDataAsJson(userData);

      if (mounted) {
        // For web/mobile - show dialog with data
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Your Data Export'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your data has been exported successfully. Copy the JSON below:',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.containerBlack,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.borderGray),
                    ),
                    child: SelectableText(
                      jsonData,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data exported successfully'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error exporting data: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Future<void> _showDeleteConfirmation(String userId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppTheme.errorRed),
            SizedBox(width: 12),
            Text('Delete Account?'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This action is permanent and cannot be undone.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Text('All your data will be permanently deleted:'),
            SizedBox(height: 8),
            Text('• Profile information'),
            Text('• Workout results'),
            Text('• Social posts and comments'),
            Text('• Messages'),
            Text('• Class bookings'),
            SizedBox(height: 16),
            Text(
              'Are you absolutely sure you want to delete your account?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
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
            child: const Text('Delete Forever'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteAccount(userId);
    }
  }

  Future<void> _deleteAccount(String userId) async {
    setState(() => _isDeleting = true);

    try {
      final gdprService = ref.read(gdprServiceProvider);
      await gdprService.deleteUserAccount(userId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account deleted successfully'),
            backgroundColor: AppTheme.successGreen,
          ),
        );

        // Navigate to login
        context.go('/auth/login');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting account: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
  }

  void _showPrivacyPolicy(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CrossFit Box Privacy Policy',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              SizedBox(height: 16),
              Text(
                'Data We Collect:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Email address and name'),
              Text('• Workout results and progress'),
              Text('• Class bookings'),
              Text('• Social interactions (posts, comments)'),
              Text('• Messages with other users'),
              SizedBox(height: 16),
              Text(
                'How We Use Your Data:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Provide app functionality'),
              Text('• Track your fitness progress'),
              Text('• Enable social features'),
              Text('• Send class and waitlist notifications'),
              SizedBox(height: 16),
              Text(
                'Your Rights (GDPR):',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Right to access your data'),
              Text('• Right to export your data'),
              Text('• Right to delete your data'),
              Text('• Right to rectify incorrect data'),
              Text('• Right to withdraw consent'),
              SizedBox(height: 16),
              Text(
                'Data Security:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• All data encrypted in transit (TLS/SSL)'),
              Text('• Data encrypted at rest'),
              Text('• Passwords hashed with bcrypt'),
              Text('• Regular security audits'),
              SizedBox(height: 16),
              Text(
                'For questions, contact: privacy@crossfitbox.com',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
