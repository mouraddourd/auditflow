import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Service de mise à jour automatique de l'application
///
/// Ce service gère:
/// - La vérification des nouvelles versions
/// - Le téléchargement des APK
/// - L'installation avec préservation des données
///
/// Les données utilisateur (SharedPreferences, Hive, SQLite) sont
/// automatiquement préservées lors de la mise à jour car elles sont
/// stockées dans le répertoire interne de l'application.
class UpdateService {
  static const String _releasesUrl =
      'https://auditflow.duckdns.org/releases.json';
  static const String _apkBaseUrl = 'https://auditflow.duckdns.org';

  final Dio _dio;
  final SharedPreferences _prefs;

  UpdateService(this._dio, this._prefs);

  /// Informations sur une version disponible
  Future<VersionInfo?> checkForUpdate() async {
    try {
      final response = await _dio.get(_releasesUrl);
      final data = response.data as Map<String, dynamic>;

      // Récupérer la dernière version
      final latestData = data['latest'] as Map<String, dynamic>?;
      if (latestData == null) {
        return null;
      }

      final serverVersion = VersionInfo.fromJson(latestData);
      final currentVersion = await _getCurrentVersion();

      if (serverVersion.buildNumber > currentVersion.buildNumber) {
        return serverVersion;
      }

      return null;
    } catch (e) {
      debugPrint('Erreur lors de la vérification de mise à jour: $e');
      return null;
    }
  }

  /// Télécharge l'APK et retourne le chemin du fichier
  Future<String?> downloadApk(
    VersionInfo version, {
    required void Function(int received, int total) onProgress,
  }) async {
    try {
      // Vérifier les permissions de stockage
      if (!await _requestStoragePermission()) {
        throw Exception('Permission de stockage refusée');
      }

      // Créer le répertoire de téléchargement
      final appDir = await getApplicationDocumentsDirectory();
      final downloadsDir = Directory('${appDir.path}/updates');
      if (!await downloadsDir.exists()) {
        await downloadsDir.create(recursive: true);
      }

      // Chemin du fichier APK
      final fileName =
          'auditflow-${version.version}-${version.buildNumber}.apk';
      final filePath = '${downloadsDir.path}/$fileName';

      // Supprimer les anciens APK
      await for (final entity in downloadsDir.list()) {
        if (entity is File &&
            entity.path.endsWith('.apk') &&
            entity.path != filePath) {
          await entity.delete();
        }
      }

      // Télécharger le nouvel APK
      await _dio.download(
        '$_apkBaseUrl${version.androidUrl}',
        filePath,
        onReceiveProgress: onProgress,
      );

      // Sauvegarder les métadonnées de la mise à jour
      await _prefs.setString('pending_update_version', version.version);
      await _prefs.setInt('pending_update_build', version.buildNumber);
      await _prefs.setString('pending_update_path', filePath);

      return filePath;
    } catch (e) {
      debugPrint('Erreur lors du téléchargement: $e');
      return null;
    }
  }

  /// Installe l'APK téléchargé
  Future<bool> installApk(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('Fichier APK non trouvé');
      }

      // Vérifier la permission d'installation
      if (Platform.isAndroid) {
        final status = await Permission.requestInstallPackages.status;
        if (!status.isGranted) {
          final result = await Permission.requestInstallPackages.request();
          if (!result.isGranted) {
            throw Exception('Permission d\'installation refusée');
          }
        }
      }

      // Installer l'APK
      final result = await OpenFile.open(
        filePath,
        type: 'application/vnd.android.package-archive',
      );

      return result.type == ResultType.done;
    } catch (e) {
      debugPrint('Erreur lors de l\'installation: $e');
      return false;
    }
  }

  /// Vérifie s'il y a une mise à jour en attente d'installation
  Future<String?> getPendingUpdate() async {
    return _prefs.getString('pending_update_path');
  }

  /// Nettoie les fichiers de mise à jour téléchargés
  Future<void> cleanupUpdates() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final downloadsDir = Directory('${appDir.path}/updates');

      if (await downloadsDir.exists()) {
        await for (final entity in downloadsDir.list()) {
          if (entity is File) {
            await entity.delete();
          }
        }
      }

      await _prefs.remove('pending_update_version');
      await _prefs.remove('pending_update_build');
      await _prefs.remove('pending_update_path');
    } catch (e) {
      debugPrint('Erreur lors du nettoyage: $e');
    }
  }

  /// Récupère la version actuelle de l'application
  Future<VersionInfo> _getCurrentVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();

    return VersionInfo(
      version: packageInfo.version,
      buildNumber: int.tryParse(packageInfo.buildNumber) ?? 1,
      androidAvailable: true,
      androidSize: 0,
      androidUrl: '',
      iosAvailable: false,
      iosSize: 0,
      iosUrl: '',
      releaseDate: DateTime.now(),
      releaseNotes: '',
    );
  }

  /// Demande les permissions de stockage nécessaires
  Future<bool> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      // Android 13+ n'a plus besoin de permission de stockage pour les fichiers app-private
      final sdkInt = await _getAndroidSdkInt();
      if (sdkInt != null && sdkInt >= 33) {
        return true;
      }

      // Android < 13 nécessite la permission de stockage
      final status = await Permission.storage.status;
      if (status.isGranted) {
        return true;
      }

      final result = await Permission.storage.request();
      return result.isGranted;
    }

    return true;
  }

  /// Récupère le SDK Android version
  Future<int?> _getAndroidSdkInt() async {
    // Cette méthode nécessite un plugin natif
    // Pour simplifier, on retourne null et on gère le cas
    return null;
  }
}

/// Informations sur une version de l'application
class VersionInfo {
  final String version;
  final int buildNumber;
  final bool androidAvailable;
  final int androidSize;
  final String androidUrl;
  final bool iosAvailable;
  final int iosSize;
  final String iosUrl;
  final DateTime releaseDate;
  final String releaseNotes;

  VersionInfo({
    required this.version,
    required this.buildNumber,
    required this.androidAvailable,
    required this.androidSize,
    required this.androidUrl,
    required this.iosAvailable,
    required this.iosSize,
    required this.iosUrl,
    required this.releaseDate,
    required this.releaseNotes,
  });

  factory VersionInfo.fromJson(Map<String, dynamic> json) {
    return VersionInfo(
      version: json['version'] as String,
      buildNumber: json['buildNumber'] as int,
      androidAvailable: json['androidAvailable'] as bool,
      androidSize: json['androidSize'] as int,
      androidUrl: json['androidUrl'] as String,
      iosAvailable: json['iosAvailable'] as bool,
      iosSize: json['iosSize'] as int,
      iosUrl: json['iosUrl'] as String,
      releaseDate: DateTime.parse(json['releaseDate'] as String),
      releaseNotes: json['releaseNotes'] as String? ?? '',
    );
  }

  /// Taille formatée en Mo
  String get androidSizeFormatted =>
      '${(androidSize / 1024 / 1024).toStringAsFixed(1)} Mo';

  /// Version complète avec numéro de build
  String get fullVersion => '$version ($buildNumber)';
}
