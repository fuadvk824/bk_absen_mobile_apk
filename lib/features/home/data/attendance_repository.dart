import 'dart:io';

import 'package:bk_absen/core/network/dio_client.dart';
import 'package:bk_absen/core/storage/cache_service.dart';
import 'package:bk_absen/model/check_in_out_model.dart';
import 'package:bk_absen/model/user_model.dart';
import 'package:bk_absen/offline/models/offline_attendance_model.dart';
import 'package:bk_absen/offline/repository/offline_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class AttendanceRepository {
  final OfflineRepository offlineRepo = OfflineRepository();

  Future<void> saveOfflineCheckIn({
    required int employeeId,
     String? imagePath,
    required double lat,
    required double lng,
    required double distance,
    required String locationStatus,
    String? lateReason,
    String? lateProofPath,
  }) async {
    final data = OfflineAttendanceModel(
      type: "checkin",
      employeeId: employeeId,
      imagePath: imagePath,
      latitude: lat,
      longitude: lng,
      distance: distance,
      locationStatus: locationStatus,
      lateReason: lateReason,
      lateProofPath: lateProofPath,
      createdAt: DateTime.now(),
    );

    await offlineRepo.save(data);
  }

  Future<void> saveOfflineCheckOut({
    required int employeeId,
      String? imagePath,
    required double lat,
    required double lng,
    required double distance,
    required String locationStatus,
    String? earlyReason,
  }) async {
    final data = OfflineAttendanceModel(
      type: "checkout",
      employeeId: employeeId,
      imagePath: imagePath,
      latitude: lat,
      longitude: lng,
      distance: distance,
      locationStatus: locationStatus,
      earlyReason: earlyReason,
      createdAt: DateTime.now(),
    );

    await offlineRepo.save(data);
  }

  Future<UserModel?> getUser() async {
    try {
      final res = await DioClient.dio.get('/me');

      await CacheService.write(
        "home_user",
        Map<String, dynamic>.from(res.data),
      );

      return UserModel.fromJson(res.data);
    } catch (_) {
      final cache = CacheService.read("home_user");

      if (cache != null) {
        return UserModel.fromJson(cache);
      }

      return null;
    }
  }

  Future<CheckInOutModel?> getToday() async {
    final now = DateTime.now();

    final today =
        "${now.year.toString().padLeft(4, '0')}-"
        "${now.month.toString().padLeft(2, '0')}-"
        "${now.day.toString().padLeft(2, '0')}";

    try {
      final res = await DioClient.dio.get('/attendance');
      final data = Map<String, dynamic>.from(res.data['data'] ?? res.data);
      final attendance = CheckInOutModel.fromJson(data);
      final attendanceDate = attendance.tanggal.toString().split(' ').first;

      // Server mengembalikan attendance hari ini.
      if (attendanceDate == today) {
        await CacheService.write("attendance_today", {
          "tanggal": attendance.tanggal,
          "check_in": attendance.checkIn,
          "check_out": attendance.checkOut,
          "total_waktu": attendance.totalWaktu,
          "is_off": attendance.isOff,
          "is_leave": attendance.isLeave,
          "has_shift": attendance.hasShift,
          "limit_late": attendance.limitLate,
        });

        return attendance;
      }

      return CheckInOutModel(
        tanggal: today,
        checkIn: null,
        checkOut: null,
        totalWaktu: null,
        isOff: attendance.isOff,
        isLeave: attendance.isLeave,
        hasShift: attendance.hasShift,
        limitLate: attendance.limitLate,
      );
    } catch (e) {
      final cache = CacheService.read("attendance_today");

      if (cache == null) {
        return null;
      }

      final cacheMap = Map<String, dynamic>.from(cache);
      final cacheTanggal = cacheMap['tanggal']?.toString().split(' ').first;

      if (cacheTanggal != today) {
        return CheckInOutModel(
          tanggal: today,
          checkIn: null,
          checkOut: null,
          totalWaktu: null,
          isOff: false,
          isLeave: false,
          hasShift: cacheMap['has_shift'] ?? true,
          limitLate: null,
        );
      }

      return CheckInOutModel.fromJson(cacheMap);
    }
  }

  Future<File> compressImage(String path) async {
    final result = await FlutterImageCompress.compressAndGetFile(
      path,
      "${path}_compressed.jpg",
      quality: 60,
    );

    if (result == null) {
      throw Exception("Gagal compress image");
    }

    return File(result.path);
  }

  Future<MultipartFile?> _tryPrepareImage(String? path) async {
    if (path == null || path.trim().isEmpty) {
      return null;
    }

    try {
      final file = File(path);

      if (!await file.exists()) {
        debugPrint('Foto tidak ditemukan: $path');
        return null;
      }

      final compressed = await compressImage(path);

      if (!await compressed.exists()) {
        return null;
      }

      return await MultipartFile.fromFile(compressed.path);
    } catch (e) {
      debugPrint('Gagal menyiapkan foto, lanjut tanpa foto: $e');
      return null;
    }
  }

  Future<MultipartFile?> _tryPrepareProof(File? file) async {
    if (file == null) return null;

    try {
      if (!await file.exists()) {
        return null;
      }

      return await MultipartFile.fromFile(file.path);
    } catch (e) {
      debugPrint('Gagal menyiapkan bukti keterlambatan: $e');
      return null;
    }
  }

  Future<void> checkIn({
    required int employeeId,
    String? imagePath,
    required double lat,
    required double lng,
    required double distance,
    required String locationStatus,
    String? lateReason,
    File? lateProof,
    DateTime? checkinAt,
  }) async {
    final formDataMap = <String, dynamic>{
      "employee_id": employeeId,
      "latitude_checkin": lat,
      "longitude_checkin": lng,
      "distance_checkin": distance,
      "location_status": locationStatus,
    };

    // if (imagePath != null && imagePath.isNotEmpty) {
    //   final compressed = await compressImage(imagePath);
    //   formDataMap["gambar_checkin"] = await MultipartFile.fromFile(
    //     compressed.path,
    //   );
    // }
    final imagePart = await _tryPrepareImage(imagePath);

    if (imagePart != null) {
      formDataMap["gambar_checkin"] = imagePart;
    }
    //____________________________________________________________
    if (checkinAt != null) {
      formDataMap["checkin_at"] = checkinAt.toIso8601String();
    }

    if (lateReason != null) {
      formDataMap["late_reason"] = lateReason;
    }

    // if (lateProof != null) {
    //   formDataMap["late_proof"] = await MultipartFile.fromFile(lateProof.path);
    // }
    final proofPart = await _tryPrepareProof(lateProof);

    if (proofPart != null) {
      formDataMap["late_proof"] = proofPart;
    }
    //____________________________________________________________

    await DioClient.dio.post(
      '/checkin',
      data: FormData.fromMap(formDataMap),
      options: Options(contentType: 'multipart/form-data'),
    );
  }

  Future<void> checkOut({
    required int employeeId,
    String? imagePath,
    required double lat,
    required double lng,
    required double distance,
    required String locationStatus,
    String? earlyReason,
    DateTime? checkoutAt,
  }) async {
    final formDataMap = <String, dynamic>{
      "employee_id": employeeId,
      "latitude_checkout": lat,
      "longitude_checkout": lng,
      "distance_checkout": distance,
      "location_status": locationStatus,
    };

    // if (imagePath != null && imagePath.isNotEmpty) {
    //   final compressed = await compressImage(imagePath);
    //   formDataMap["gambar_checkout"] = await MultipartFile.fromFile(
    //     compressed.path,
    //   );
    // }
    final imagePart = await _tryPrepareImage(imagePath);

    if (imagePart != null) {
      formDataMap["gambar_checkout"] = imagePart;
    }
    //______________________________________________________

    if (checkoutAt != null) {
      formDataMap["checkout_at"] = checkoutAt.toIso8601String();
    }

    if (earlyReason != null) {
      formDataMap["early_reason"] = earlyReason;
    }

    await DioClient.dio.patch(
      '/checkout',
      data: FormData.fromMap(formDataMap),
      options: Options(contentType: 'multipart/form-data'),
    );
  }
}
