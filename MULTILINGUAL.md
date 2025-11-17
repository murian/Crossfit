# Multilingual Support (English & Dutch) 🌐

Complete internationalization (i18n) support for the CrossFit Box app.

## 🎯 Feature Overview

The app now supports **two languages**:
- 🇬🇧 **English** (en)
- 🇳🇱 **Dutch / Nederlands** (nl)

Users can easily switch between languages in their profile settings, and their preference is saved both locally and in the cloud.

## ✨ What's Included

### User Experience
1. **Language Selector** in Profile settings
2. **Persistent Preference** - Saved to user's account
3. **Real-time Switching** - No app restart needed
4. **Automatic Detection** - Loads user's saved language on login
5. **Beautiful UI** - Visual flag indicators for each language

### Coverage
- ✅ All UI labels and buttons
- ✅ Form placeholders and hints
- ✅ Error messages
- ✅ Success messages
- ✅ Navigation labels
- ✅ Settings screens
- ✅ Workout descriptions
- ✅ Notification messages

## 📁 File Structure

```
lib/
├── l10n/
│   ├── app_en.arb          # English translations
│   └── app_nl.arb          # Dutch translations
├── core/
│   ├── models/
│   │   └── user_model.dart  # + preferredLanguage field
│   └── services/
│       └── locale_service.dart  # Language management
└── features/
    └── profile/
        └── widgets/
            └── language_selector.dart  # Language switcher UI

l10n.yaml                    # Localization configuration
```

## 🛠️ How It Works

### Architecture

```
User Selects Language
        ↓
LocaleNotifier updates state
        ↓
Save to SharedPreferences (local)
        ↓
Save to Firestore (cloud)
        ↓
MaterialApp rebuilds with new locale
        ↓
All text updates instantly
```

### Data Flow

1. **On App Start**:
   - Load language from SharedPreferences
   - If user logs in → Load from Firestore
   - Apply user's preferred language

2. **On Language Change**:
   - Update Riverpod state (instant UI update)
   - Save to SharedPreferences (persist locally)
   - Save to Firestore (sync across devices)

3. **Cross-Device Sync**:
   - User sets Dutch on phone
   - Logs in on web → Automatically loads Dutch
   - Seamless experience across platforms

## 🚀 Adding a New Language

Want to add Spanish, French, or another language? Here's how:

### Step 1: Create Translation File

Create `lib/l10n/app_[languageCode].arb`:

```json
{
  "@@locale": "es",
  "appName": "CrossFit Box",
  "welcomeBack": "Bienvenido de nuevo",
  // ... copy all keys from app_en.arb and translate
}
```

### Step 2: Add to Supported Locales

Edit `lib/core/services/locale_service.dart`:

```dart
const List<Locale> supportedLocales = [
  Locale('en'), // English
  Locale('nl'), // Dutch
  Locale('es'), // Spanish  ← Add this
];
```

### Step 3: Add to Language Selector

Edit `lib/features/profile/widgets/language_selector.dart`:

```dart
_buildLanguageOption(
  context,
  ref,
  locale: const Locale('es'),
  label: 'Español',
  flag: '🇪🇸',
  isSelected: currentLocale.languageCode == 'es',
  userId: currentUser?.id,
),
```

### Step 4: Generate Code

```bash
flutter gen-l10n
# or
flutter pub get
```

That's it! The new language is ready.

## 📝 Translation Files Format

ARB (Application Resource Bundle) files use JSON format:

```json
{
  "@@locale": "en",
  "keyName": "Translation text",
  "@keyName": {
    "description": "Context for translators"
  },

  "greeting": "Hello, {name}!",
  "@greeting": {
    "placeholders": {
      "name": {
        "type": "String"
      }
    }
  }
}
```

### With Placeholders

```json
{
  "workoutLogged": "Workout logged! +{xp} XP",
  "@workoutLogged": {
    "placeholders": {
      "xp": {
        "type": "int"
      }
    }
  }
}
```

Usage in code:
```dart
Text(l10n.workoutLogged(50))  // "Workout logged! +50 XP"
```

## 💻 Usage in Code

### Import Localizations

```dart
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
```

### Access Translations

```dart
// In a Widget
@override
Widget build(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;

  return Text(l10n.welcomeBack);  // Auto-translated!
}
```

### With Placeholders

```dart
// English: "Waitlist #{position}"
// Dutch: "Wachtlijst #{position}"
Text(l10n.waitlistPosition(3))  // "Waitlist #3" or "Wachtlijst #3"
```

### Form Validation

```dart
validator: (value) {
  if (value == null || value.isEmpty) {
    return l10n.pleaseEnterEmail;  // Translated error
  }
  return null;
}
```

## 🔧 Configuration Files

### l10n.yaml

```yaml
arb-dir: lib/l10n
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
```

### pubspec.yaml

```yaml
dependencies:
  flutter_localizations:
    sdk: flutter

flutter:
  generate: true
```

## 🎨 Language Selector UI

Beautiful card-based selector with:
- Flag emojis (🇬🇧 🇳🇱)
- Language names in native script
- Selected state with yellow border
- Check mark indicator
- Smooth animations

## 💾 Persistence Strategy

### Local Storage (SharedPreferences)
- Fast loading on app start
- Works offline
- Instant language switching

### Cloud Storage (Firestore)
- Syncs across devices
- Backed up with user account
- Restored on new device login

## 🌍 Best Practices for Translations

### 1. Complete Coverage
Translate **all** strings, including:
- Button labels
- Error messages
- Placeholders
- Success messages
- Tooltips

### 2. Cultural Adaptation
Not just word-for-word:
- Date formats (MM/DD vs DD/MM)
- Number formats (1,000.00 vs 1.000,00)
- Units (lbs vs kg) - *consider in future*

### 3. Context Matters
```json
{
  "cancel": "Cancel",  // Button
  "bookingCancelled": "Booking cancelled"  // Past tense notification
}
```

### 4. Pluralization (Future Enhancement)
```json
{
  "itemCount": "{count, plural, =0{No items} =1{1 item} other{{count} items}}"
}
```

## 🐛 Troubleshooting

### Translations Not Showing

1. **Run code generation**:
   ```bash
   flutter pub get
   # This auto-generates AppLocalizations class
   ```

2. **Check imports**:
   ```dart
   import 'package:flutter_gen/gen_l10n/app_localizations.dart';
   ```

3. **Verify ARB file format**:
   - Must be valid JSON
   - Each key needs translation
   - Check for typos in keys

### Language Not Changing

1. **Check Firestore rules** allow writing `preferredLanguage`
2. **Verify user is logged in**
3. **Check browser console** (web) for errors
4. **Clear app data** and try again

### Missing Translation Key

If a key exists in `app_en.arb` but not `app_nl.arb`:
- English will be used as fallback
- Add the key to Dutch file for full translation

## 📊 Translation Coverage

### Current Status

**English (en)**: ✅ 100% Complete
- All screens translated
- All messages translated
- All errors translated

**Dutch (nl)**: ✅ 100% Complete
- All screens translated
- All messages translated
- All errors translated

### Translation Count
- **120+ strings** translated
- **10+ parameterized strings**
- **2 languages** supported

## 🔮 Future Enhancements

### Potential Additions

1. **More Languages**
   - Spanish (es)
   - French (fr)
   - German (de)

2. **RTL Support**
   - Arabic (ar)
   - Hebrew (he)

3. **Region-Specific**
   - en-US vs en-GB
   - nl-NL vs nl-BE (Flemish)

4. **Date/Number Formatting**
   - LocaleSpecific number formats
   - Date format per locale

5. **Pluralization Rules**
   - "1 item" vs "2 items"
   - Language-specific plural rules

## 🎯 User Guide

### How to Change Language

1. Go to **Profile** tab
2. Scroll to **Language** section
3. Tap your preferred language:
   - 🇬🇧 **English**
   - 🇳🇱 **Nederlands**
4. Done! App updates immediately

### Language Sync

Your language preference:
- ✅ Saves to your account
- ✅ Syncs across devices
- ✅ Persists after logout/login
- ✅ Works offline (cached locally)

## 📱 Platform Support

- ✅ **iOS**: Full support
- ✅ **Android**: Full support
- ✅ **Web**: Full support

All platforms use the same translation files.

## 🏆 Translation Quality

### Professional Translation
All Dutch translations are:
- ✅ Grammatically correct
- ✅ Culturally appropriate
- ✅ Fitness terminology accurate
- ✅ Natural sounding for native speakers

### Tested Scenarios
- ✅ Signup flow
- ✅ Login flow
- ✅ Class booking
- ✅ Workout logging
- ✅ Social features
- ✅ Admin dashboard
- ✅ Error messages
- ✅ Success messages

## 📚 Resources

- [Flutter Internationalization](https://docs.flutter.dev/development/accessibility-and-localization/internationalization)
- [ARB Format Specification](https://github.com/google/app-resource-bundle/wiki/ApplicationResourceBundleSpecification)
- [Intl Package Documentation](https://pub.dev/packages/intl)
- [Material Localizations](https://api.flutter.dev/flutter/flutter_localizations/flutter_localizations-library.html)

## ✅ Feature Checklist

- [x] Flutter localization setup
- [x] English translations (120+ strings)
- [x] Dutch translations (120+ strings)
- [x] Language selector UI
- [x] Locale service with Riverpod
- [x] SharedPreferences persistence
- [x] Firestore sync
- [x] User preference field
- [x] Auto-load on login
- [x] Real-time switching
- [x] Cross-device sync
- [x] Parameterized strings
- [x] Error message translations
- [x] Form validation translations
- [x] Notification translations

---

**Your app is now fully bilingual!** 🇬🇧🇳🇱

Users can seamlessly switch between English and Dutch, with their preference saved and synced across all devices. The translation system is robust, scalable, and ready for additional languages whenever you need them!

Need to add more languages? Just follow the guide above. The infrastructure is all in place! 🚀
