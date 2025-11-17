import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider for the current locale
final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier();
});

/// Notifier to manage app locale
class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(const Locale('en')) {
    _loadLocale();
  }

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Load locale from SharedPreferences
  Future<void> _loadLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final languageCode = prefs.getString('language_code');
      if (languageCode != null) {
        state = Locale(languageCode);
      }
    } catch (e) {
      // If there's an error, keep default locale
    }
  }

  /// Change locale and save to preferences and Firestore
  Future<void> setLocale(Locale locale, {String? userId}) async {
    state = locale;

    // Save to SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('language_code', locale.languageCode);
    } catch (e) {
      // Handle error silently
    }

    // Save to Firestore if user is logged in
    if (userId != null) {
      try {
        await _firestore.collection('users').doc(userId).update({
          'preferredLanguage': locale.languageCode,
        });
      } catch (e) {
        // Handle error silently
      }
    }
  }

  /// Load user's preferred language from Firestore
  Future<void> loadUserLanguage(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final preferredLanguage = data['preferredLanguage'] as String?;
        if (preferredLanguage != null) {
          state = Locale(preferredLanguage);
          // Also save to local preferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('language_code', preferredLanguage);
        }
      }
    } catch (e) {
      // Handle error silently
    }
  }
}

/// Supported locales
const List<Locale> supportedLocales = [
  Locale('en'), // English
  Locale('nl'), // Dutch
];
