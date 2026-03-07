import 'dart:io';
import 'package:flutter/foundation.dart';

/// Centralized API configuration for AuditFlow
/// Allows environment-specific configuration via dart-define
class ApiConfig {
  ApiConfig._();

  /// Detects the local network IP address automatically
  /// Returns null if no suitable network interface is found
  static Future<String?> _getLocalIpAddress() async {
    try {
      final interfaces = await NetworkInterface.list();

      // Prioritize Ethernet, then WiFi interfaces
      for (final interface in interfaces) {
        // Skip virtual interfaces (WSL, Docker, etc.)
        if (interface.name.toLowerCase().contains('vethernet') ||
            interface.name.toLowerCase().contains('wsl') ||
            interface.name.toLowerCase().contains('docker') ||
            interface.name.toLowerCase().contains('hyper-v')) {
          continue;
        }

        for (final addr in interface.addresses) {
          // Look for IPv4 addresses in private ranges (192.168.x.x, 10.x.x.x, 172.16-31.x.x)
          if (addr.type == InternetAddressType.IPv4) {
            final ip = addr.address;
            if (ip.startsWith('192.168.') ||
                ip.startsWith('10.') ||
                ip.startsWith('172.')) {
              return ip;
            }
          }
        }
      }
    } catch (e) {
      // Fallback: return null, will use default
    }
    return null;
  }

  /// Cached local IP for performance
  static String? _cachedLocalIp;

  /// Gets the local IP, caching the result
  static Future<String> _getCachedLocalIp() async {
    if (_cachedLocalIp != null) return _cachedLocalIp!;
    _cachedLocalIp = await _getLocalIpAddress() ?? 'localhost';
    return _cachedLocalIp!;
  }

  /// Base URL for the backend API
  /// Automatically detects local IP for physical devices
  static Future<String> getBaseUrl() async {
    const url = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: '',
    );

    // If explicitly set via environment, use it
    if (url.isNotEmpty) return url;

    // Web platform: use localhost
    if (kIsWeb) return 'http://localhost:3000';

    // Android: detect if emulator or physical device
    if (Platform.isAndroid) {
      // Check if running on emulator (no real network interfaces)
      final localIp = await _getCachedLocalIp();

      // If localhost or 127.0.0.1, it's likely an emulator
      if (localIp == 'localhost' || localIp.startsWith('127.')) {
        return 'http://10.0.2.2:3000'; // Emulator
      }

      // Physical device: use detected local IP
      return 'http://$localIp:3000';
    }

    // iOS/Desktop: use localhost
    return 'http://localhost:3000';
  }

  /// PowerSync WebSocket URL
  /// Automatically detects local IP for physical devices
  static Future<String> getPowerSyncUrl() async {
    const url = String.fromEnvironment(
      'POWERSYNC_URL',
      defaultValue: '',
    );

    // If explicitly set via environment, use it
    if (url.isNotEmpty) return url;

    // Web platform: use localhost
    if (kIsWeb) return 'ws://localhost:8080';

    // Android: detect if emulator or physical device
    if (Platform.isAndroid) {
      final localIp = await _getCachedLocalIp();

      if (localIp == 'localhost' || localIp.startsWith('127.')) {
        return 'ws://10.0.2.2:8080'; // Emulator
      }

      return 'ws://$localIp:8080';
    }

    // iOS/Desktop: use localhost
    return 'ws://localhost:8080';
  }

  // Synchronous getters for backward compatibility (use localhost as fallback)
  static String get baseUrl => 'http://localhost:3000';
  static String get powerSyncUrl => 'ws://localhost:8080';

  // Async endpoint getters that use auto-detected IP
  static Future<String> getLoginUrl() async =>
      '${await getBaseUrl()}/auth/login';
  static Future<String> getRegisterUrl() async =>
      '${await getBaseUrl()}/auth/register';
  static Future<String> getMeUrl() async => '${await getBaseUrl()}/auth/me';
  static Future<String> getOrganizationsUrl() async =>
      '${await getBaseUrl()}/organizations';
  static Future<String> getPowerSyncUploadUrl() async =>
      '${await getBaseUrl()}/powersync/upload';
  static Future<String> getHealthUrl() async => '${await getBaseUrl()}/health';

  // Sync getters (deprecated - use async versions for Android physical devices)
  static String get login => '$baseUrl/auth/login';
  static String get register => '$baseUrl/auth/register';
  static String get me => '$baseUrl/auth/me';
  static String get organizations => '$baseUrl/organizations';
  static String get powerSyncUpload => '$baseUrl/powersync/upload';
  static String get health => '$baseUrl/health';
}
