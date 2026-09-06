import 'package:bk_absen/core/storage/cache_service.dart';
import 'package:dio/dio.dart';

import '../../../core/network/dio_client.dart';
import '../../../core/storage/token_manager.dart';
import '../../../model/user_model.dart';

class AuthRepository {
  Future<UserModel> login(String email, String password) async {
    try {
      final res = await DioClient.dio.post(
        '/login',
        data: {"email": email, "password": password},
      );

      final token = res.data['token'];
      await TokenManager.set(token);

      final me = await DioClient.dio.get('/me');
      await CacheService.write("user", Map<String, dynamic>.from(me.data));

      return UserModel.fromJson(me.data);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        throw Exception(
          'Server sedang tidak dapat dihubungi. '
          'Silakan coba beberapa menit lagi.',
        );
      }

      final data = e.response?.data;

      if (data is Map<String, dynamic>) {
        final message = data['message'];

        if (message is String && message.isNotEmpty) {
          throw Exception(message);
        }
      }

      if (e.response != null) {
        throw Exception(
          'Terjadi kesalahan pada server (${e.response?.statusCode}). '
          'Silakan coba beberapa menit lagi',
        );
      }

      throw Exception(
        'Tidak dapat terhubung ke server. Silakan coba lagi beberapa menit lagi.',
      );
    } catch (e) {
      throw Exception('Terjadi kesalahan. Silakan coba lagi.');
    }
  }

  Future<UserModel?> me() async {
    try {
      final res = await DioClient.dio.get('/me');

      await CacheService.write("user", Map<String, dynamic>.from(res.data));

      return UserModel.fromJson(res.data);
    } catch (_) {
      final cache = CacheService.read("user");

      if (cache != null) {
        return UserModel.fromJson(cache);
      }

      return null;
    }
  }

  Future<void> logout() async {
    try {
      await DioClient.dio.post('/logout');
    } catch (_) {}

    await TokenManager.clear();
    await CacheService.delete("user");
  }
}
