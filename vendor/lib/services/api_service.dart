import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final Map<String, dynamic>? data;

  ApiException({
    required this.message,
    this.statusCode,
    this.data,
  });
}

class ApiService {
  late final Dio _dio;

  ApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString(AppConstants.tokenKey);
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) {
          debugPrint('API Error: ${error.message}');
          if (error.response != null) {
            debugPrint('Error Status: ${error.response?.statusCode}');
          }
          return handler.next(error);
        },
      ),
    );
  }

  Future<Response> post(String path, {dynamic data}) async {
    try {
      return await _dio.post(path, data: data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.get(path, queryParameters: queryParameters);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> put(String path, {dynamic data}) async {
    try {
      return await _dio.put(path, data: data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> delete(String path, {dynamic data}) async {
    try {
      return await _dio.delete(path, data: data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  ApiException _handleError(DioException error) {
    String message;
    int? statusCode;
    Map<String, dynamic>? data;

    statusCode = error.response?.statusCode;
    if (error.response?.data is Map<String, dynamic>) {
      data = error.response?.data as Map<String, dynamic>;
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        message = 'Connection timeout. Please check your internet connection.';
        break;
      case DioExceptionType.sendTimeout:
        message = 'Send timeout. Please try again.';
        break;
      case DioExceptionType.receiveTimeout:
        message = 'Receive timeout. Please try again.';
        break;
      case DioExceptionType.badResponse:
        if (statusCode == 401) {
          message = 'Unauthorized. Please login again.';
        } else if (statusCode == 404) {
          message = 'API endpoint not found. Please check backend.';
        } else if (statusCode == 500) {
          message = 'Server error. Please try again later.';
        } else {
          if (data != null && data.containsKey('message')) {
            message = data['message'];
          } else if (error.response?.data is String) {
            message = error.response?.data as String;
          } else {
            message = 'Something went wrong.';
          }
        }
        break;
      case DioExceptionType.cancel:
        message = 'Request cancelled.';
        break;
      case DioExceptionType.connectionError:
        message = 'Connection error. Please check your internet connection.';
        break;
      case DioExceptionType.unknown:
      default:
        message = 'Something went wrong. Please try again.';
        break;
    }
    return ApiException(
      message: message,
      statusCode: statusCode,
      data: data,
    );
  }
}
