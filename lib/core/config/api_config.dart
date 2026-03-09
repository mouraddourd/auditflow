import 'dart:io';

class ApiConfig {
  ApiConfig._();

  static String get baseUrl {
    const url = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://192.168.1.1:3000',
    );
    if (Platform.isAndroid && url.contains('localhost')) {
      return url.replaceAll('localhost', '10.0.2.2');
    }
    return url;
  }

  static String get login => '$baseUrl/auth/login';
  static String get register => '$baseUrl/auth/register';
  static String get me => '$baseUrl/auth/me';
  static String get organizations => '$baseUrl/organizations';
  static String get health => '$baseUrl/health';
}
