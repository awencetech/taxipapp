import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiService {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:5000/api/v1';
    } else if (Platform.isAndroid) {
      // 10.0.2.2 is the special IP for Android emulator to access localhost
      return 'http://10.0.2.2:5000/api/v1';
    } else {
      // iOS simulator or others
      return 'http://localhost:5000/api/v1';
    }
  }

  late final Dio _dio;

  Dio get dio => _dio;

  ApiService() {
    _dio = Dio(
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
      return await _dio.get('/users/rides');
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
      return await _dio.post('/rides/create', data: jsonEncode(data));
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
      return await _dio.put('/rides/$rideId/status', data: jsonEncode(data));
    } catch (e) {
      developer.log('UpdateRideStatus error: $e');
      rethrow;
    }
  }

  Future<Response> cancelRide(
    String rideId,
    String reason,
  ) async {
    try {
      return await _dio.put('/rides/$rideId/cancel',
          data: jsonEncode({'reason': reason}));
    } catch (e) {
      developer.log('CancelRide error: $e');
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

  // Addresses
  Future<Response> getAddresses() async {
    try {
      return await _dio.get('/users/addresses');
    } catch (e) {
      developer.log('GetAddresses error: $e');
      rethrow;
    }
  }

  Future<Response> addAddress(Map<String, dynamic> data) async {
    try {
      return await _dio.post('/users/addresses', data: data);
    } catch (e) {
      developer.log('AddAddress error: $e');
      rethrow;
    }
  }

  Future<Response> updateAddress(String id, Map<String, dynamic> data) async {
    try {
      return await _dio.put('/users/addresses/$id', data: data);
    } catch (e) {
      developer.log('UpdateAddress error: $e');
      rethrow;
    }
  }

  Future<Response> deleteAddress(String id) async {
    try {
      return await _dio.delete('/users/addresses/$id');
    } catch (e) {
      developer.log('DeleteAddress error: $e');
      rethrow;
    }
  }

  Future<Response> setDefaultAddress(String id) async {
    try {
      return await _dio.put('/users/addresses/$id/default');
    } catch (e) {
      developer.log('SetDefaultAddress error: $e');
      rethrow;
    }
  }

  // Payment Methods
  Future<Response> addPaymentMethod(Map<String, dynamic> data) async {
    try {
      return await _dio.post('/users/payment-methods', data: data);
    } catch (e) {
      developer.log('AddPaymentMethod error: $e');
      rethrow;
    }
  }

  Future<Response> deletePaymentMethod(String id) async {
    try {
      return await _dio.delete('/users/payment-methods/$id');
    } catch (e) {
      developer.log('DeletePaymentMethod error: $e');
      rethrow;
    }
  }

  Future<Response> setDefaultPaymentMethod(String id) async {
    try {
      return await _dio.put('/users/payment-methods/$id/default');
    } catch (e) {
      developer.log('SetDefaultPaymentMethod error: $e');
      rethrow;
    }
  }

  // Notifications
  Future<Response> getNotificationSettings() async {
    try {
      return await _dio.get('/users/notification-settings');
    } catch (e) {
      developer.log('GetNotificationSettings error: $e');
      rethrow;
    }
  }

  Future<Response> updateNotificationSettings(Map<String, dynamic> data) async {
    try {
      return await _dio.put('/users/notification-settings', data: data);
    } catch (e) {
      developer.log('UpdateNotificationSettings error: $e');
      rethrow;
    }
  }

  Future<Response> getNotifications() async {
    try {
      return await _dio.get('/users/notifications');
    } catch (e) {
      developer.log('GetNotifications error: $e');
      rethrow;
    }
  }

  Future<Response> markNotificationAsRead(String id) async {
    try {
      return await _dio.put('/users/notifications/$id/read');
    } catch (e) {
      developer.log('MarkNotificationAsRead error: $e');
      rethrow;
    }
  }

  Future<Response> markAllNotificationsAsRead() async {
    try {
      return await _dio.put('/users/notifications/mark-all-read');
    } catch (e) {
      developer.log('MarkAllNotificationsAsRead error: $e');
      rethrow;
    }
  }

  Future<Response> deleteNotification(String id) async {
    try {
      return await _dio.delete('/users/notifications/$id');
    } catch (e) {
      developer.log('DeleteNotification error: $e');
      rethrow;
    }
  }

  // Security
  Future<Response> changePassword(Map<String, dynamic> data) async {
    try {
      return await _dio.put('/auth/change-password', data: data);
    } catch (e) {
      developer.log('ChangePassword error: $e');
      rethrow;
    }
  }

  Future<Response> changePIN(Map<String, dynamic> data) async {
    try {
      return await _dio.put('/auth/change-pin', data: data);
    } catch (e) {
      developer.log('ChangePIN error: $e');
      rethrow;
    }
  }

  Future<Response> getLoginActivity() async {
    try {
      return await _dio.get('/users/login-activity');
    } catch (e) {
      developer.log('GetLoginActivity error: $e');
      rethrow;
    }
  }

  Future<Response> logoutAllDevices() async {
    try {
      return await _dio.post('/auth/logout-all');
    } catch (e) {
      developer.log('LogoutAllDevices error: $e');
      rethrow;
    }
  }

  Future<Response> deleteAccount() async {
    try {
      return await _dio.delete('/users/me');
    } catch (e) {
      developer.log('DeleteAccount error: $e');
      rethrow;
    }
  }

  // Referral
  Future<Response> getReferralData() async {
    try {
      return await _dio.get('/users/referral');
    } catch (e) {
      developer.log('GetReferralData error: $e');
      rethrow;
    }
  }

  // Tickets/Support
  Future<Response> getTickets() async {
    try {
      return await _dio.get('/users/tickets');
    } catch (e) {
      developer.log('GetTickets error: $e');
      rethrow;
    }
  }

  Future<Response> createTicket(Map<String, dynamic> data) async {
    try {
      return await _dio.post('/users/tickets', data: data);
    } catch (e) {
      developer.log('CreateTicket error: $e');
      rethrow;
    }
  }

  Future<Response> getTicketDetails(String id) async {
    try {
      return await _dio.get('/users/tickets/$id');
    } catch (e) {
      developer.log('GetTicketDetails error: $e');
      rethrow;
    }
  }

  Future<Response> sendTicketMessage(
      String id, Map<String, dynamic> data) async {
    try {
      return await _dio.post('/users/tickets/$id/messages', data: data);
    } catch (e) {
      developer.log('SendTicketMessage error: $e');
      rethrow;
    }
  }
}
