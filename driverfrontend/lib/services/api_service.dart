import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';

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
          debugPrint('=== API Service: On Request ===');
          debugPrint('Method: ${options.method}');
          debugPrint('URI: ${options.uri}');
          debugPrint('Path: ${options.path}');
          debugPrint('Request Data: ${options.data}');
          debugPrint('Initial Headers: ${options.headers}');

          // Skip Authorization header only for actual public routes.
          final path = options.path;
          final method = options.method?.toUpperCase();
          final hasLookupQueryParams =
              (options.queryParameters?.isNotEmpty ?? false);
          final isPublicAuthRoute = path.contains('/login') ||
              path.contains('/signup') ||
              path.contains('/register') ||
              (path == AppConstants.driverStatusUrl &&
                  method == 'GET' &&
                  hasLookupQueryParams);

          debugPrint('Request method: $method');
          debugPrint('Request path: $path');
          debugPrint('Has lookup query params: $hasLookupQueryParams');
          debugPrint('Is public route: $isPublicAuthRoute');

          if (!isPublicAuthRoute) {
            final prefs = await SharedPreferences.getInstance();
            final token = prefs.getString(AppConstants.tokenKey);
            debugPrint('Token from prefs: $token');
            if (token != null) {
              options.headers['Authorization'] = 'Bearer $token';
              debugPrint('Authorization header added: Bearer $token');
            } else {
              debugPrint('⚠️ Token is null in prefs!');
            }
          } else {
            debugPrint('Skipping auth header for public route');
          }
          debugPrint('Final Headers: ${options.headers}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          debugPrint('=== API Service: On Response ===');
          debugPrint('Response Status: ${response.statusCode}');
          debugPrint('Response Data: ${response.data}');
          return handler.next(response);
        },
        onError: (error, handler) {
          debugPrint('=== API Service: On Error ===');
          debugPrint('Error: ${error.message}');
          if (error.response != null) {
            debugPrint('Error Status: ${error.response?.statusCode}');
            debugPrint('Error Data: ${error.response?.data}');
            debugPrint('Error Headers: ${error.response?.headers}');
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
      // If data is FormData, use it directly; otherwise proceed as normal
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

  Future<Response> firebasePhoneAuth(Map<String, dynamic> data) async {
    try {
      return await _dio.post(AppConstants.firebasePhoneAuthUrl, data: data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Exception _handleError(DioException error) {
    String message;
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
        if (error.response?.statusCode == 401) {
          message = 'Unauthorized. Please login again.';
        } else if (error.response?.statusCode == 404) {
          message = 'API endpoint not found. Please check backend.';
        } else if (error.response?.statusCode == 500) {
          message = 'Server error. Please try again later.';
        } else {
          message = error.response?.data['message'] ?? 'Something went wrong.';
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
    return Exception(message);
  }
}
