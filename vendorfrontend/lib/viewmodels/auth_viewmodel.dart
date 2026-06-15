import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../core/constants/app_constants.dart';
import '../models/vendor_models.dart';

class AuthViewModel extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  bool _isLoading = false;
  bool _isLoggedIn = false;
  Vendor? _vendor;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  bool get isLoggedIn => _isLoggedIn;
  Vendor? get vendor => _vendor;
  String? get errorMessage => _errorMessage;

  AuthViewModel() {
    checkAutoLogin();
  }

  Future<void> checkAutoLogin() async {
    _isLoading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.tokenKey);
    final vendorId = prefs.getString(AppConstants.vendorIdKey);

    if (token != null && vendorId != null) {
      _isLoggedIn = true;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> login({String? email, String? phone, required String password}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final Map<String, dynamic> data = {};
      if (email != null) data['email'] = email;
      if (phone != null) data['phone'] = phone;
      data['password'] = password;

      final response = await _apiService.post(
        AppConstants.vendorLoginUrl,
        data: data,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        final token = data['token'];
        final vendorId = data['vendor']['_id'];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(AppConstants.tokenKey, token);
        await prefs.setString(AppConstants.vendorIdKey, vendorId);

        _vendor = Vendor.fromJson(data['vendor']);
        _isLoggedIn = true;
        _isLoading = false;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> sendOTP(String phone) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.post(
        AppConstants.vendorSendOtpUrl,
        data: {'phone': phone},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _isLoading = false;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> verifyOTP(String phone, String otp) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.post(
        AppConstants.vendorVerifyOtpUrl,
        data: {'phone': phone, 'otp': otp},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        final token = data['token'];
        final vendorId = data['vendor']['_id'];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(AppConstants.tokenKey, token);
        await prefs.setString(AppConstants.vendorIdKey, vendorId);

        _vendor = Vendor.fromJson(data['vendor']);
        _isLoggedIn = true;
        _isLoading = false;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(
      String name, String email, String phone, String password, String companyName) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.post(
        AppConstants.vendorRegisterUrl,
        data: {
          'name': name,
          'email': email,
          'phone': phone,
          'password': password,
          'companyName': companyName,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        final token = data['token'];
        final vendorId = data['vendor']['_id'];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(AppConstants.tokenKey, token);
        await prefs.setString(AppConstants.vendorIdKey, vendorId);

        _vendor = Vendor.fromJson(data['vendor']);
        _isLoggedIn = true;
        _isLoading = false;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.tokenKey);
    await prefs.remove(AppConstants.vendorIdKey);

    _isLoggedIn = false;
    _vendor = null;
    notifyListeners();
  }
}
