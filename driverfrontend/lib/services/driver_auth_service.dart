import 'package:dio/dio.dart';
import '../core/constants/app_constants.dart';
import 'api_service.dart';

class DriverAuthService {
  final ApiService _apiService = ApiService();

  Future<Map<String, dynamic>> sendOtp(String email) async {
    final Response response = await _apiService.post(
      AppConstants.driverForgotPasswordUrl,
      data: {'email': email},
    );
    return {
      'success': response.data['success'] == true,
      'message': response.data['message'] ?? 'Unable to send OTP',
    };
  }

  Future<Map<String, dynamic>> verifyOtp(String email, String otp) async {
    final Response response = await _apiService.post(
      AppConstants.driverVerifyOtpUrl,
      data: {'email': email, 'otp': otp},
    );
    return {
      'success': response.data['success'] == true,
      'message': response.data['message'] ?? 'Unable to verify OTP',
    };
  }

  Future<Map<String, dynamic>> resetPassword(String email, String otp, String password) async {
    final requestBody = {
      'email': email,
      'otp': otp,
      'password': password,
    };
    print('DriverAuthService resetPassword request body: $requestBody');

    final Response response = await _apiService.post(
      AppConstants.driverResetPasswordUrl,
      data: requestBody,
    );
    print('DriverAuthService resetPassword status code: ${response.statusCode}');
    print('DriverAuthService resetPassword response data: ${response.data}');
    return {
      'success': response.data['success'] == true,
      'message': response.data['message'] ?? 'Unable to reset password',
    };
  }
}
