import 'dart:convert';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../../core/network/dio_client.dart';
import '../../core/constants/api_constants.dart';
import '../../core/services/secure_storage_service.dart';

class AuthRepository {
  final DioClient _dioClient;
  final SecureStorageService _secureStorage;

  AuthRepository({
    required DioClient dioClient,
    required SecureStorageService secureStorage,
  })  : _dioClient = dioClient,
        _secureStorage = secureStorage;

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    String deviceName = 'Flutter Web';
    if (!kIsWeb) {
      final deviceInfo = DeviceInfoPlugin();

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        deviceName = '${androidInfo.manufacturer} ${androidInfo.model}';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        deviceName = iosInfo.name;
      }
    }

    final response = await _dioClient.dio.post(
      ApiConstants.login,
      data: {
        'email': email,
        'password': password,
        'device_name': deviceName,
      },
    );

    final token = response.data['data']['token'];
    final user = UserModel.fromJson(response.data['data']['user']);
    await _secureStorage.saveToken(token);
    await _secureStorage.saveUser(jsonEncode(user.toJson()));
    return user;
  }

  Future<UserModel> getProfile() async {
    final response = await _dioClient.dio.get(ApiConstants.me);
    return UserModel.fromJson(response.data['data']['user']);
  }

  Future<void> logout() async {
    await _dioClient.dio.post(ApiConstants.logout);
    await _secureStorage.clearAll();
  }

  Future<void> sendOtp(String email) async {
    await _dioClient.dio.post(
      ApiConstants.sendOtp,
      data: {'email': email},
    );
  }

  Future<void> resetPassword({
    required String email,
    required String otp,
    required String password,
  }) async {
    await _dioClient.dio.post(
      ApiConstants.resetPassword,
      data: {
        'email': email,
        'otp': otp,
        'password': password,
      },
    );
  }
}
