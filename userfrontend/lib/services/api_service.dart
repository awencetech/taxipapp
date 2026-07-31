import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiService {
  static String get baseUrl {
    if (kIsWeb) {
      // Use the current origin for web builds so the app automatically
      // targets the same host/port the frontend was served from.
      // This avoids mismatches between the dev server port and the API port.
      try {
        final origin = Uri.base.origin; // e.g. http://localhost:5003
        return '\$origin/api/v1';
      } catch (e) {
        return 'http://localhost:5003/api/v1';
      }
    } else if (Platform.isAndroid) {
      // 10.0.2.2 is the special IP for Android emulator to access localhost
      return 'http://10.0.2.2:5003/api/v1';
    } else {
      // iOS simulator or others
      return 'http://localhost:5003/api/v1';
    }
  }

  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      validateStatus: (status) => status! < 500,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  ApiService() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          developer.log(
            'API REQUEST[${options.method}] => FULL URL: ${options.baseUrl}${options.path}',
          );
          if (options.data != null) {
            developer.log('Request Body: ${options.data}');
          }

          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('jwt_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          developer.log(
            'API RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}',
          );
          developer.log('Response Body: ${response.data}');
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          developer.log(
            'API ERROR[${e.response?.statusCode}] => PATH: ${e.requestOptions.path}',
          );
          developer.log('Error Type: ${e.type}');
          developer.log('Error Message: ${e.message}');
          if (e.response?.data != null) {
            developer.log('Error Data: ${e.response?.data}');
          }

          String errorMessage = 'An unexpected error occurred';

          if (e.type == DioExceptionType.connectionTimeout ||
              e.type == DioExceptionType.sendTimeout ||
              e.type == DioExceptionType.receiveTimeout) {
            errorMessage =
                'Request Timeout. Please check your internet or server status.';
          } else if (e.type == DioExceptionType.connectionError) {
            errorMessage =
                'Connection refused. Cannot connect to server at ${e.requestOptions.baseUrl}.';
          } else if (e.response?.statusCode == 404) {
            errorMessage =
                '404 Not Found: The requested resource does not exist.';
          } else if (e.response?.data != null &&
              e.response?.data['message'] != null) {
            errorMessage = e.response?.data['message'];
          } else {
            errorMessage = e.message ?? 'Server not reachable';
          }

          // Create a new exception with the friendly message
          final error = DioException(
            requestOptions: e.requestOptions,
            response: e.response,
            type: e.type,
            error: errorMessage,
          );

          return handler.next(error);
        },
      ),
    );
  }

  // Auth
  Future<Response> register(Map<String, dynamic> data) async {
    try {
      return await _dio.post(
        '/auth/register',
        data: jsonEncode(data),
        options: Options(
          headers: {'Content-Type': 'application/json'},
        ),
      );
    } catch (e) {
      developer.log('Register error: $e');
      rethrow;
    }
  }

  Future<Response> login(Map<String, dynamic> data) async {
    try {
      return await _dio.post(
        '/auth/login',
        data: jsonEncode(data),
        options: Options(
          headers: {'Content-Type': 'application/json'},
        ),
      );
    } catch (e) {
      developer.log('Login error: $e');
      rethrow;
    }
  }

  Future<Response> forgotPassword(String email) async {
    try {
      return await _dio.post('/auth/forgot-password', data: {'email': email});
    } catch (e) {
      developer.log('ForgotPassword error: $e');
      rethrow;
    }
  }

  Future<Response> verifyOTP(String email, String otp) async {
    try {
      return await _dio
          .post('/auth/verify-otp', data: {'email': email, 'otp': otp});
    } catch (e) {
      developer.log('VerifyOTP error: $e');
      rethrow;
    }
  }

  Future<Response> resetPassword(
      String email, String otp, String password) async {
    try {
      return await _dio.post('/auth/reset-password', data: {
        'email': email,
        'otp': otp,
        'password': password,
      });
    } catch (e) {
      developer.log('ResetPassword error: $e');
      rethrow;
    }
  }

  Future<Response> googleLogin(Map<String, dynamic> data) async {
    try {
      return await _dio.post(
        '/auth/google-login',
        data: jsonEncode(data),
        options: Options(
          headers: {'Content-Type': 'application/json'},
        ),
      );
    } catch (e) {
      developer.log('GoogleLogin error: $e');
      rethrow;
    }
  }

  Future<Response> completeProfile(Map<String, dynamic> data) async {
    try {
      return await _dio.post(
        '/auth/complete-profile',
        data: jsonEncode(data),
        options: Options(
          headers: {'Content-Type': 'application/json'},
        ),
      );
    } catch (e) {
      developer.log('CompleteProfile error: $e');
      rethrow;
    }
  }

  Future<Response> getProfile() async {
    try {
      return await _dio.get('/users/me');
    } catch (e) {
      developer.log('GetProfile error: $e');
      rethrow;
    }
  }

  Future<Response> updateProfile(Map<String, dynamic> data) async {
    try {
      return await _dio.put('/users/profile', data: data);
    } catch (e) {
      developer.log('UpdateProfile error: $e');
      rethrow;
    }
  }

  Future<Response> getRideHistory() async {
    try {
      return await _dio.get('/rides/user/my-rides');
    } catch (e) {
      developer.log('GetRideHistory error: $e');
      rethrow;
    }
  }

  Future<Response> getUserPayments() async {
    try {
      return await _dio.get('/users/payments');
    } catch (e) {
      developer.log('GetUserPayments error: $e');
      rethrow;
    }
  }

  // Drivers
  Future<Response> getNearbyDrivers() async {
    try {
      // Note: In the new backend, this might be handled differently or as a query
      return await _dio.get('/drivers/nearby');
    } catch (e) {
      developer.log('GetNearbyDrivers error: $e');
      rethrow;
    }
  }

  Future<Response> updateDriverLocation(Map<String, dynamic> data) async {
    try {
      return await _dio.put('/drivers/location', data: data);
    } catch (e) {
      developer.log('UpdateLocation error: $e');
      rethrow;
    }
  }

  // Rides
  Future<Response> bookRide(Map<String, dynamic> data) async {
    try {
      return await _dio.post('/ride/request', data: data);
    } catch (e) {
      developer.log('BookRide error: $e');
      rethrow;
    }
  }

  Future<Response> getRideDetails(String rideId) async {
    try {
      return await _dio.get('/rides/$rideId');
    } catch (e) {
      developer.log('GetRideDetails error: $e');
      rethrow;
    }
  }

  Future<Response> updateRideStatus(
    String rideId,
    Map<String, dynamic> data,
  ) async {
    try {
      return await _dio.put('/rides/$rideId/status', data: data);
    } catch (e) {
      developer.log('UpdateRideStatus error: $e');
      rethrow;
    }
  }

  // Admin
  Future<Response> getAdminStats() async {
    try {
      return await _dio.get('/admin/stats');
    } catch (e) {
      developer.log('GetAdminStats error: $e');
      rethrow;
    }
  }

  Future<Response> getAdminRides() async {
    try {
      return await _dio.get('/admin/rides');
    } catch (e) {
      developer.log('GetAdminRides error: $e');
      rethrow;
    }
  }

  Future<Response> getAdminPayments() async {
    try {
      return await _dio.get('/admin/payments');
    } catch (e) {
      developer.log('GetAdminPayments error: $e');
      rethrow;
    }
  }

  Future<Response> getAdminSettings() async {
    try {
      return await _dio.get('/admin/settings');
    } catch (e) {
      developer.log('GetAdminSettings error: $e');
      rethrow;
    }
  }

  Future<Response> updateAdminSettings(Map<String, dynamic> data) async {
    try {
      return await _dio.put('/admin/settings', data: data);
    } catch (e) {
      developer.log('UpdateAdminSettings error: $e');
      rethrow;
    }
  }
}
