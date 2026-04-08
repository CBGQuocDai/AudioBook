class AppConfig {
  const AppConfig._();

  // Highest priority override.
  // Example: --dart-define=API_BASE_URL=http://192.168.1.82:8080/api
  static const String _overrideBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'AUTO',
  );

  // Quick switch for Android emulator.
  // true  -> 10.0.2.2
  // false -> API_DEVICE_BASE_URL
  static const bool _useAndroidEmulator = bool.fromEnvironment(
    'USE_ANDROID_EMULATOR',
    defaultValue: true,
  );

  // Base URL when running on physical phone.
  static const String _deviceBaseUrl = String.fromEnvironment(
    'API_DEVICE_BASE_URL',
    defaultValue: 'http://192.168.52.107:8080/api',
  );

  static const String apiBaseUrl = _overrideBaseUrl == 'AUTO'
      ? (_useAndroidEmulator ? 'http://10.0.2.2:8080/api' : _deviceBaseUrl)
      : _overrideBaseUrl;
}
