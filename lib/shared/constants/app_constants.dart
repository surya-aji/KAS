// Application-wide constants.
//
// Centralized place for magic values, default settings,
// and configuration constants used across the app.

class AppConstants {
  AppConstants._();

  /// Application name shown in UI.
  static const String appName = 'Kas Usaha';

  /// Application version (matches pubspec.yaml).
  static const String appVersion = '0.1.0';

  /// Default currency code.
  static const String defaultCurrencyCode = 'IDR';

  /// Default currency symbol.
  static const String defaultCurrencySymbol = 'Rp';

  /// Database file name.
  static const String databaseFileName = 'kas_usaha.db';
}
