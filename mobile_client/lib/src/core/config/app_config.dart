/// Cấu hình toàn cục cho ứng dụng di động AudioBook.
///
/// Lớp này chứa các hằng số cấu hình liên quan đến môi trường chạy, địa chỉ API và các thiết lập khác.
class AppConfig {
  const AppConfig._();

  /// Địa chỉ API cơ sở (Base URL) được chỉ định đè thông qua tham số `--dart-define=API_BASE_URL=...` khi build.
  /// Mặc định trỏ đến địa chỉ ngrok.
  static const String _overrideBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://feline-prison-facing.ngrok-free.dev/api',
  );

  /// Cờ kiểm soát việc có sử dụng địa chỉ dành cho máy ảo Android (Emulator) hay không.
  /// Nếu `true`, ứng dụng sẽ trỏ tới IP máy chủ phát triển cục bộ qua máy ảo (10.0.2.2).
  static const bool _useAndroidEmulator = bool.fromEnvironment(
    'USE_ANDROID_EMULATOR',
    defaultValue: false,
  );

  /// Địa chỉ API cơ sở sử dụng cho thiết bị thật.
  static const String _deviceBaseUrl = String.fromEnvironment(
    'API_DEVICE_BASE_URL',
    defaultValue: 'https://feline-prison-facing.ngrok-free.dev/api',
  );

  /// Địa chỉ API cơ sở chính thức được sử dụng để giao tiếp với Backend.
  ///
  /// Được tự động quyết định dựa trên cài đặt của [_overrideBaseUrl], [_useAndroidEmulator] và [_deviceBaseUrl].
  static const String apiBaseUrl = _overrideBaseUrl == 'AUTO'
      ? (_useAndroidEmulator ? 'http://10.0.2.2:8080/api' : _deviceBaseUrl)
      : _overrideBaseUrl;
}
