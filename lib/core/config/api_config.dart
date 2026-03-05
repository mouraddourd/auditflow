/// Centralized API configuration for AuditFlow
/// Allows environment-specific configuration via dart-define
class ApiConfig {
  ApiConfig._();

  /// Base URL for the backend API
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000',
  );

  /// PowerSync WebSocket URL
  static const String powerSyncUrl = String.fromEnvironment(
    'POWERSYNC_URL',
    defaultValue: 'ws://localhost:8080',
  );

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
