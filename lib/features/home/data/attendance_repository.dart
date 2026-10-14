import 'dart:io';

import 'package:bk_absen/core/network/dio_client.dart';
import 'package:bk_absen/core/storage/cache_service.dart';
import 'package:bk_absen/model/check_in_out_model.dart';
import 'package:bk_absen/model/user_model.dart';
import 'package:bk_absen/offline/models/offline_attendance_model.dart';
import 'package:bk_absen/offline/repository/offline_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class AttendanceRepository {
  final OfflineRepository offlineRepo = OfflineRepository();

  Future<void> saveOfflineCheckIn({
    required int employeeId,
    required String imagePath,
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
    required String imagePath,
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
          "has_shift": attendance.hasShift,
          "limit_late": attendance.limitLate,
        });

        return attendance;
      }

      // Server mengembalikan attendance kemarin.
      // Jangan masukkan data tersebut sebagai attendance hari ini.
      return CheckInOutModel(
        tanggal: today,
        checkIn: null,
        checkOut: null,
        totalWaktu: null,
        isOff: attendance.isOff,
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

      // Cache bukan hari ini.
      if (cacheTanggal != today) {
        return CheckInOutModel(
          tanggal: today,
          checkIn: null,
          checkOut: null,
          totalWaktu: null,
          isOff: false,
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

  Future<void> checkIn({
    required int employeeId,
    required String imagePath,
    required double lat,
    required double lng,
    required double distance,
    required String locationStatus,

    String? lateReason,
    File? lateProof,
    DateTime? checkinAt,
  }) async {
    final compressed = await compressImage(imagePath);

    final formDataMap = {
      "employee_id": employeeId,
      "latitude_checkin": lat,
      "longitude_checkin": lng,
      "distance_checkin": distance,
      "location_status": locationStatus,
      "gambar_checkin": await MultipartFile.fromFile(compressed.path),
    };

    if (checkinAt != null) {
      formDataMap["checkin_at"] = checkinAt.toIso8601String();
    }
    if (lateReason != null) {
      formDataMap["late_reason"] = lateReason;
    }
    if (lateProof != null) {
      formDataMap["late_proof"] = await MultipartFile.fromFile(lateProof.path);
    }

    final formData = FormData.fromMap(formDataMap);

    await DioClient.dio.post(
      '/checkin',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
  }

  Future<void> checkOut({
    required int employeeId,
    required String imagePath,
    required double lat,
    required double lng,
    required double distance,
    required String locationStatus,
    String? earlyReason,
    DateTime? checkoutAt,
  }) async {
    final compressed = await compressImage(imagePath);
    final formDataMap = {
      "employee_id": employeeId,
      "latitude_checkout": lat,
      "longitude_checkout": lng,
      "distance_checkout": distance,
      "location_status": locationStatus,
      "gambar_checkout": await MultipartFile.fromFile(compressed.path),
    };
    if (checkoutAt != null) {
      formDataMap["checkout_at"] = checkoutAt.toIso8601String();
    }
    if (earlyReason != null) {
      formDataMap["early_reason"] = earlyReason;
    }

    final formData = FormData.fromMap(formDataMap);

    await DioClient.dio.patch(
      '/checkout',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
  }
}
