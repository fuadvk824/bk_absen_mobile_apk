import 'dart:io';

import 'package:bk_absen/core/network/dio_client.dart';
import 'package:bk_absen/model/check_in_out_model.dart';
import 'package:bk_absen/model/user_model.dart';
import 'package:dio/dio.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class AttendanceRepository {
  Future<UserModel?> getUser() async {
    try {
      final res = await DioClient.dio.get('/me');

      return UserModel.fromJson(res.data);
    } catch (_) {
      return null;
    }
  }

  Future<CheckInOutModel?> getToday() async {
    try {
      final res = await DioClient.dio.get('/attendance');
      final data = res.data['data'] ?? res.data;
      return CheckInOutModel.fromJson(data);
    } catch (_) {
      return null;
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

    // optional
    String? lateReason,
    File? lateProof,
  }) async {
    final compressed = await compressImage(imagePath);

    final formDataMap = {
      "employee_id": employeeId,
      "latitude_checkin": lat,
      "longitude_checkin": lng,
      "distance_checkin": distance,
      "location_status": locationStatus,
      // "gambar_checkin": await MultipartFile.fromFile(imagePath),
      "gambar_checkin": await MultipartFile.fromFile(compressed.path),
    };

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
