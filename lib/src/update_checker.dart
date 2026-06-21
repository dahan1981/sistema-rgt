import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'supabase_config.dart';

class UpdateInfo {
  const UpdateInfo({
    required this.currentVersion,
    required this.latestVersion,
    required this.downloadUri,
    required this.notes,
    required this.mandatory,
    required this.sha256Hash,
  });

  final String currentVersion;
  final String latestVersion;
  final Uri downloadUri;
  final String notes;
  final bool mandatory;
  final String sha256Hash;
}

class UpdateChecker {
  const UpdateChecker({http.Client? client, String? manifestUrl})
      : _client = client,
        _manifestUrl = manifestUrl;

  final http.Client? _client;
  final String? _manifestUrl;

  Future<UpdateInfo?> check() async {
    final manifestUrl =
        (_manifestUrl ?? SupabaseConfig.updateManifestUrl).trim();
    if (manifestUrl.isEmpty) {
      return null;
    }

    final manifestUri = Uri.tryParse(manifestUrl);
    if (manifestUri == null || !manifestUri.hasScheme) {
      return null;
    }

    final client = _client ?? http.Client();
    final shouldCloseClient = _client == null;

    try {
      final response =
          await client.get(manifestUri).timeout(const Duration(seconds: 8));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }

      final manifest = jsonDecode(response.body) as Map<String, dynamic>;
      final latestVersion = (manifest['version'] as String?)?.trim();
      final downloadUrl = _downloadUrlForPlatform(manifest);
      final sha256Hash = (manifest['sha256'] as String?)?.trim().toLowerCase();
      if (latestVersion == null ||
          latestVersion.isEmpty ||
          downloadUrl == null ||
          downloadUrl.isEmpty ||
          sha256Hash == null ||
          !RegExp(r'^[a-f0-9]{64}$').hasMatch(sha256Hash)) {
        return null;
      }

      final downloadUri = Uri.tryParse(downloadUrl);
      if (downloadUri == null || !downloadUri.hasScheme) {
        return null;
      }

      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      if (!_isRemoteVersionNewer(currentVersion, latestVersion)) {
        return null;
      }

      return UpdateInfo(
        currentVersion: currentVersion,
        latestVersion: latestVersion,
        downloadUri: downloadUri,
        notes: (manifest['notes'] as String?)?.trim() ?? '',
        mandatory: manifest['mandatory'] == true,
        sha256Hash: sha256Hash,
      );
    } catch (_) {
      return null;
    } finally {
      if (shouldCloseClient) {
        client.close();
      }
    }
  }

  Future<bool> downloadAndInstall(UpdateInfo update) async {
    if (!Platform.isWindows) {
      return launchUrl(
        update.downloadUri,
        mode: LaunchMode.externalApplication,
      );
    }

    final client = _client ?? http.Client();
    final shouldCloseClient = _client == null;
    try {
      final response = await client
          .get(update.downloadUri)
          .timeout(const Duration(minutes: 5));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return false;
      }

      final actualHash = sha256.convert(response.bodyBytes).toString();
      if (actualHash != update.sha256Hash) {
        return false;
      }

      final safeVersion = update.latestVersion.replaceAll(
        RegExp(r'[^0-9A-Za-z._-]'),
        '_',
      );
      final installer = File(
        '${Directory.systemTemp.path}${Platform.pathSeparator}'
        'SistemaRGT-Setup-$safeVersion.exe',
      );
      await installer.writeAsBytes(response.bodyBytes, flush: true);
      await Process.start(
        installer.path,
        const [],
        mode: ProcessStartMode.detached,
      );
      return true;
    } catch (_) {
      return false;
    } finally {
      if (shouldCloseClient) {
        client.close();
      }
    }
  }

  String? _downloadUrlForPlatform(Map<String, dynamic> manifest) {
    if (Platform.isWindows) {
      return manifest['windows_url'] as String?;
    }
    if (Platform.isAndroid) {
      return manifest['android_url'] as String?;
    }
    if (Platform.isIOS) {
      return manifest['ios_url'] as String?;
    }
    if (Platform.isMacOS) {
      return manifest['macos_url'] as String?;
    }
    if (Platform.isLinux) {
      return manifest['linux_url'] as String?;
    }
    return null;
  }

  bool _isRemoteVersionNewer(String current, String remote) {
    final currentParts = _versionParts(current);
    final remoteParts = _versionParts(remote);

    for (var index = 0; index < 3; index++) {
      if (remoteParts[index] > currentParts[index]) {
        return true;
      }
      if (remoteParts[index] < currentParts[index]) {
        return false;
      }
    }

    return false;
  }

  List<int> _versionParts(String version) {
    final cleanVersion = version.split('+').first.split('-').first;
    final parts = cleanVersion.split('.');
    return List<int>.generate(3, (index) {
      if (index >= parts.length) {
        return 0;
      }
      return int.tryParse(parts[index]) ?? 0;
    });
  }
}
