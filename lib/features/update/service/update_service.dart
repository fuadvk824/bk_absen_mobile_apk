import 'dart:io';

import 'package:bk_absen/model/app_version_model.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

import '../data/version_repository.dart';

class UpdateService {
  final VersionRepository repo = VersionRepository();

  Future<String> getCurrentVersion() async {
    final info = await PackageInfo.fromPlatform();

    return info.version;
  }

  Future<AppVersionModel> getLatestVersion() async {
    return repo.checkVersion();
  }

  bool isNewerVersion(String latestVersion, String currentVersion) {
    return _compareVersion(latestVersion, currentVersion) > 0;
  }

  int _compareVersion(String a, String b) {
    final aParts = _parseVersion(a);
    final bParts = _parseVersion(b);

    final maxLength = aParts.length > bParts.length
        ? aParts.length
        : bParts.length;

    for (int i = 0; i < maxLength; i++) {
      final aValue = i < aParts.length ? aParts[i] : 0;
      final bValue = i < bParts.length ? bParts[i] : 0;

      if (aValue > bValue) {
        return 1;
      }

      if (aValue < bValue) {
        return -1;
      }
    }

    return 0;
  }

  List<int> _parseVersion(String version) {
    return version
        .trim()
        .replaceFirst(RegExp(r'^[vV]'), '')
        .split('.')
        .map((part) => int.tryParse(part) ?? 0)
        .toList();
  }

  Future<void> downloadAndInstall(
    String apkUrl, {
    required Function(double progress) onProgress,
  }) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/bk_pos_update.apk');

    try {
      // ==========================================
      // 1. Hapus APK update sebelumnya
      // ==========================================

      if (await file.exists()) {
        await file.delete();
      }

      // ==========================================
      // 2. Download APK terbaru
      // ==========================================

      await Dio().download(
        apkUrl,
        file.path,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            onProgress(received / total);
          }
        },
      );

      // ==========================================
      // 3. Pastikan APK berhasil didownload
      // ==========================================

      if (!await file.exists()) {
        throw Exception('File APK tidak ditemukan');
      }

      final fileSize = await file.length();

      if (fileSize <= 0) {
        throw Exception('File APK kosong');
      }

      debugPrint('APK downloaded: ${file.path}');

      debugPrint('APK size: $fileSize bytes');

      // ==========================================
      // 4. Buka Android Installer
      // ==========================================

      final result = await OpenFilex.open(file.path);

      debugPrint('Installer result: ${result.type}');

      debugPrint('Installer message: ${result.message}');

      if (result.type != ResultType.done) {
        throw Exception('Gagal membuka installer: ${result.message}');
      }

      // ==========================================
      // 5. Cleanup APK temporary
      // ==========================================

      Future.delayed(const Duration(seconds: 15), () async {
        try {
          if (await file.exists()) {
            await file.delete();

            debugPrint('APK update temporary berhasil dihapus');
          }
        } catch (e) {
          debugPrint('Cleanup APK gagal: $e');
        }
      });
    } catch (e) {
      // Kalau download gagal,
      // hapus file APK yang mungkin setengah terdownload.

      try {
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {}

      rethrow;
    }
  }
   
}
