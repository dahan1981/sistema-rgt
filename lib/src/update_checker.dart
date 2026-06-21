import 'dart:convert';
import 'dart:io';

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
  });

  final String currentVersion;
  final String latestVersion;
  final Uri downloadUri;
  final String notes;
  final bool mandatory;
}

class UpdateChecker {
  const UpdateChecker({http.Client? client}) : _client = client;

  final http.Client? _client;

  Future<UpdateInfo?> check() async {
    final manifestUrl = SupabaseConfig.updateManifestUrl.trim();
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
      if (latestVersion == null ||
          latestVersion.isEmpty ||
          downloadUrl == null ||
          downloadUrl.isEmpty) {
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
      );
    } catch (_) {
      return null;
    } finally {
      if (shouldCloseClient) {
        client.close();
      }
    }
  }

  Future<bool> openDownload(UpdateInfo update) {
    return launchUrl(update.downloadUri, mode: LaunchMode.externalApplication);
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
