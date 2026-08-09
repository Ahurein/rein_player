import 'package:flutter/material.dart';

enum AppLanguage {
  english('en', 'English'),
  simplifiedChinese('zh_CN', '简体中文'),
  japanese('ja', '日本語'),
  korean('ko', '한국어'),
  french('fr', 'Français'),
  german('de', 'Deutsch'),
  spanish('es', 'Español'),
  russian('ru', 'Русский');

  const AppLanguage(this.code, this.displayName);

  final String code;
  final String displayName;

  Locale get locale {
    if (code.contains('_')) {
      final parts = code.split('_');
      return Locale(parts.first, parts.last);
    }
    return Locale(code);
  }

  static AppLanguage fromCode(String? code) {
    return AppLanguage.values.firstWhere(
      (language) => language.code == code,
      orElse: () => AppLanguage.english,
    );
  }

  /// Picks the closest supported language for the given device locale,
  /// falling back to English when nothing matches.
  static AppLanguage fromDeviceLocale(Locale? deviceLocale) {
    if (deviceLocale == null) return AppLanguage.english;
    for (final language in AppLanguage.values) {
      if (language.code == deviceLocale.languageCode) return language;
    }
    for (final language in AppLanguage.values) {
      if (language.code.split('_').first == deviceLocale.languageCode) {
        return language;
      }
    }
    return AppLanguage.english;
  }
}