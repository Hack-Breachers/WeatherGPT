import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Supported languages in WeatherGPT.
///
/// code       = language code sent to backend
/// nativeName = language name displayed to the user
/// label      = English/internal label
enum AppLanguage {
  english(
    code: 'en',
    nativeName: 'English',
    label: 'English',
  ),

  hindi(
    code: 'hi',
    nativeName: 'हिन्दी',
    label: 'Hindi',
  ),

  bengali(
    code: 'bn',
    nativeName: 'বাংলা',
    label: 'Bengali',
  );

  const AppLanguage({
    required this.code,
    required this.nativeName,
    required this.label,
  });

  final String code;
  final String nativeName;
  final String label;

  static AppLanguage fromCode(String? code) {
    switch (code) {
      case 'hi':
        return AppLanguage.hindi;

      case 'bn':
        return AppLanguage.bengali;

      case 'en':
      default:
        return AppLanguage.english;
    }
  }
}

/// Global language state for WeatherGPT.
///
/// Responsibilities:
/// - Stores the currently selected language.
/// - Notifies the UI when the language changes.
/// - Persists the user's language choice locally.
/// - Provides the language code for the backend.
class LanguageService extends ChangeNotifier {
  LanguageService({
    AppLanguage initialLanguage = AppLanguage.english,
  }) : _language = initialLanguage;

  static const String _storageKey = 'weathergpt_language';

  AppLanguage _language;

  AppLanguage get language => _language;

  /// Language code used by the backend.
  ///
  /// en = English
  /// hi = Hindi
  /// bn = Bengali
  String get code => _language.code;

  /// Load previously selected language from local storage.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    final savedCode = prefs.getString(_storageKey);

    if (savedCode != null) {
      _language = AppLanguage.fromCode(savedCode);
      notifyListeners();
    }
  }

  /// Change the current language and save it locally.
  Future<void> setLanguage(AppLanguage newLanguage) async {
    if (_language == newLanguage) {
      return;
    }

    _language = newLanguage;

    notifyListeners();

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      _storageKey,
      newLanguage.code,
    );
  }
}

/// Provides LanguageService to the entire WeatherGPT widget tree.
class LanguageScope extends InheritedNotifier<LanguageService> {
  const LanguageScope({
    super.key,
    required LanguageService notifier,
    required Widget child,
  }) : super(
          notifier: notifier,
          child: child,
        );

  /// Access the nearest LanguageScope.
  static LanguageScope of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<LanguageScope>();

    assert(
      scope != null,
      'LanguageScope is missing above this widget.',
    );

    return scope!;
  }

  /// Current selected language.
  AppLanguage get language {
    return notifier!.language;
  }

  /// Full language service.
  LanguageService get service {
    return notifier!;
  }

  /// Convenient language-change method.
  Future<void> setLanguage(AppLanguage language) {
    return notifier!.setLanguage(language);
  }
}