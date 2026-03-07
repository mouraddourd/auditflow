import 'dart:io';

/// Centralized API configuration for AuditFlow
/// Allows environment-specific configuration via dart-define
class ApiConfig {
  ApiConfig._();

  /// Base URL for the backend API
  /// For physical Android device: use your PC's WiFi IP (e.g., 192.168.1.xxx)
  /// For emulator: uses 10.0.2.2 automatically
  static String get baseUrl {
    const url = String.fromEnvironment(
      'API_BASE_URL',
      // CHANGE THIS to your PC's WiFi IP when testing on physical device
      defaultValue: 'http://192.168.1.1:3000',
    );
    // Android emulator: localhost refers to emulator itself, use 10.0.2.2
    if (Platform.isAndroid && url.contains('localhost')) {
      return url.replaceAll('localhost', '10.0.2.2');
    }
    return url;
  }

  /// PowerSync WebSocket URL
  /// For physical Android device: use your PC's WiFi IP (e.g., 192.168.1.xxx)
  /// For emulator: uses 10.0.2.2 automatically
  static String get powerSyncUrl {
    const url = String.fromEnvironment(
      'POWERSYNC_URL',
      // CHANGE THIS to your PC's WiFi IP when testing on physical device
      // Use HTTP not WS - PowerSync handles WebSocket internally
      defaultValue: 'http://192.168.1.1:8080',
    );
    // Android emulator: localhost refers to emulator itself, use 10.0.2.2
    if (Platform.isAndroid && url.contains('localhost')) {
      return url.replaceAll('localhost', '10.0.2.2');
    }
    return url;
  }

  // Auth endpoints
  static String get login => '$baseUrl/auth/login';
  static String get register => '$baseUrl/auth/register';
  static String get me => '$baseUrl/auth/me';

  // Organization endpoints
  static String get organizations => '$baseUrl/organizations';

  // PowerSync endpoints
  static String get powerSyncUpload => '$baseUrl/powersync/upload';

  // Health check
  static String get health => '$baseUrl/health';
}
