import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

class ApiConfig {
  ApiConfig._();

  static String get baseUrl {
    const url = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://localhost:3000',
    );
    // Sur Android, localhost doit être remplacé par 10.0.2.2
    // Sur web, on garde localhost tel quel
    if (!kIsWeb) {
      try {
        if (Platform.isAndroid && url.contains('localhost')) {
          return url.replaceAll('localhost', '10.0.2.2');
        }
      } catch (_) {
        // Platform peut ne pas être disponible sur certaines plateformes
      }
    }
    return url;
  }

  static String get login => '$baseUrl/auth/login';
  static String get register => '$baseUrl/auth/register';
  static String get me => '$baseUrl/auth/me';
  static String get organizations => '$baseUrl/organizations';
  static String get health => '$baseUrl/health';
}
