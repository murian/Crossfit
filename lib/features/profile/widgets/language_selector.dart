import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/locale_service.dart';
import '../../../core/theme/app_theme.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class LanguageSelector extends ConsumerWidget {
  const LanguageSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeProvider);
    final currentUser = ref.watch(currentUserProvider).value;
    final l10n = AppLocalizations.of(context)!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.language, color: AppTheme.primaryYellow),
                const SizedBox(width: 12),
                Text(
                  l10n.language,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Language options
            _buildLanguageOption(
              context,
              ref,
              locale: const Locale('en'),
              label: 'English',
              flag: '🇬🇧',
              isSelected: currentLocale.languageCode == 'en',
              userId: currentUser?.id,
            ),
            const SizedBox(height: 12),
            _buildLanguageOption(
              context,
              ref,
              locale: const Locale('nl'),
              label: 'Nederlands',
              flag: '🇳🇱',
              isSelected: currentLocale.languageCode == 'nl',
              userId: currentUser?.id,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption(
    BuildContext context,
    WidgetRef ref, {
    required Locale locale,
    required String label,
    required String flag,
    required bool isSelected,
    String? userId,
  }) {
    final l10n = AppLocalizations.of(context)!;

    return InkWell(
      onTap: () async {
        await ref.read(localeProvider.notifier).setLocale(
              locale,
              userId: userId,
            );

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.languageChanged(label)),
              backgroundColor: AppTheme.successGreen,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryYellow.withOpacity(0.1)
              : AppTheme.surfaceBlack,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primaryYellow : AppTheme.borderGray,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(
              flag,
              style: const TextStyle(fontSize: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected
                          ? AppTheme.primaryYellow
                          : AppTheme.textPrimary,
                    ),
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppTheme.primaryYellow,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}
