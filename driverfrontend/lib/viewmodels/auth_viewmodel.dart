import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/driver_models.dart';
import '../services/api_service.dart';
import '../services/google_auth_service.dart';
import '../core/constants/app_constants.dart';

class AuthViewModel extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final GoogleAuthService _googleAuthService = GoogleAuthService();

  DriverModel? _driver;
  Map<String, dynamic>? _newDriverInfo;
  bool _isLoading = false;
  String? _error;

  DriverModel? get driver => _driver;
  Map<String, dynamic>? get newDriverInfo => _newDriverInfo;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _driver != null;

  Future<void> checkAutoLogin() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _isLoading = true;
      notifyListeners();

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AppConstants.tokenKey);
      if (token != null) {
        try {
          final response = await _apiService.get(
            AppConstants.getDriverProfileUrl,
          );
          if (response.statusCode == 200 && response.data['success'] == true) {
            _driver = DriverModel.fromJson(
              response.data['data']['user'] ?? response.data,
            );
          }
        } catch (e) {
          _error = e.toString();
        }
      }

      _isLoading = false;
      notifyListeners();
    });
  }

  Future<bool> updateDriverProfile({
    String? name,
    String? mobile,
    String? profilePic,
    String? vehicleType,
    String? vehicleNumber,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await _apiService.put(
        AppConstants.updateDriverProfileUrl,
        data: {
          'name': name,
          'mobile': mobile,
          'profilePic': profilePic,
          'vehicleType': vehicleType,
          'vehicleNumber': vehicleNumber,
        },
      );

      if (response.data['success'] == true) {
        _driver = DriverModel.fromJson(
          response.data['data']['user'] ?? response.data,
        );
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response.data['message'] ?? 'Failed to update profile';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.post(
        AppConstants.loginUrl,
        data: {'email': email, 'password': password},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        _driver = DriverModel.fromJson(data['user'] ?? data);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(AppConstants.tokenKey, data['token']);
        await prefs.setString(AppConstants.driverIdKey, _driver!.id);

        _isLoading = false;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(
    String name,
    String email,
    String password,
    String mobile,
    String vehicleType,
    String vehicleNumber,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.post(
        AppConstants.registerUrl,
        data: {
          'name': name,
          'email': email,
          'password': password,
          'mobile': mobile,
          'role': 'driver',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(AppConstants.tokenKey, data['token']);

        final driverResponse = await _apiService.post(
          AppConstants.driverRegisterUrl,
          data: {'vehicleType': vehicleType, 'vehicleNumber': vehicleNumber},
        );

        if (driverResponse.statusCode == 200 ||
            driverResponse.statusCode == 201) {
          _driver = DriverModel(
            id: data['user']['_id'] ?? data['user']['id'],
            name: data['user']['name'],
            email: data['user']['email'],
            mobile: data['user']['mobile'],
            vehicleType: vehicleType,
            vehicleNumber: vehicleNumber,
            isOnline: false,
          );

          await prefs.setString(AppConstants.driverIdKey, _driver!.id);

          _isLoading = false;
          notifyListeners();
          return true;
        }
      }
      return false;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<Map<String, dynamic>> loginWithGoogle() async {
    _isLoading = true;
    _error = null;
    _newDriverInfo = null;
    notifyListeners();

    try {
      final googleAccount = await _googleAuthService.signIn();
      if (googleAccount == null) {
        _isLoading = false;
        notifyListeners();
        return {'success': false};
      }

      final driverData = {
        'email': googleAccount.email,
        'name': googleAccount.displayName,
        'googleId': googleAccount.id,
        'photoUrl': googleAccount.photoUrl,
      };

      final response = await _apiService.post(
        AppConstants.googleLoginUrl,
        data: driverData,
      );

      if (response.data['isNewUser'] == true) {
        _newDriverInfo = response.data;
        _isLoading = false;
        notifyListeners();
        return {'success': true, 'isNewUser': true};
      } else {
        final data = response.data;
        _driver = DriverModel.fromJson(data['user'] ?? data);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(AppConstants.tokenKey, data['token']);
        await prefs.setString(AppConstants.driverIdKey, _driver!.id);

        _isLoading = false;
        notifyListeners();
        return {'success': true, 'isNewUser': false};
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return {'success': false};
    }
  }

  Future<bool> completeGoogleProfile(
    String name,
    String mobile,
    String vehicleType,
    String vehicleNumber,
  ) async {
    if (_newDriverInfo == null) return false;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final driverData = {..._newDriverInfo!, 'name': name, 'mobile': mobile};

      final response = await _apiService.post(
        AppConstants.completeProfileUrl,
        data: driverData,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(AppConstants.tokenKey, data['token']);

        final driverResponse = await _apiService.post(
          AppConstants.driverRegisterUrl,
          data: {'vehicleType': vehicleType, 'vehicleNumber': vehicleNumber},
        );

        if (driverResponse.statusCode == 200 ||
            driverResponse.statusCode == 201) {
          _driver = DriverModel.fromJson(data['user'] ?? data);
          _newDriverInfo = null;

          await prefs.setString(AppConstants.driverIdKey, _driver!.id);

          _isLoading = false;
          notifyListeners();
          return true;
        }
      }
      return false;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await _googleAuthService.signOut();
    _driver = null;
    _newDriverInfo = null;
    notifyListeners();
  }
}
