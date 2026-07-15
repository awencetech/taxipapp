import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import '../models/driver_models.dart';
import '../core/constants/app_constants.dart';
import 'dart:async';

class AuthService {
  final ApiService _apiService = ApiService();
  final _userController = StreamController<DriverModel?>.broadcast();

  Stream<DriverModel?> get userStream => _userController.stream;

  Future<DriverModel?> signUp(
    String name,
    String email,
    String password,
    String mobile,
    String? vehicleType,
    String? vehicleNumber,
  ) async {
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

      if (response.statusCode == 201 && response.data['success'] == true) {
        // Now register driver details (vehicle type, number)
        final token = response.data['token'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(AppConstants.tokenKey, token);

        // Set the token for API service
        // Note: This assumes ApiService uses the token from SharedPreferences
        final driverResponse = await _apiService.post(
          AppConstants.driverRegisterUrl,
          data: {
            if (vehicleType != null) 'vehicleType': vehicleType,
            if (vehicleNumber != null) 'vehicleNumber': vehicleNumber,
          },
        );

        if (driverResponse.statusCode == 200 ||
            driverResponse.statusCode == 201) {
          final userData = response.data['user'];
          final user = DriverModel.fromJson(userData);
          await prefs.setString(AppConstants.driverIdKey, user.id);
          _userController.add(user);
          return user;
        } else {
          throw Exception(
            driverResponse.data['message'] ??
                'Failed to register driver details',
          );
        }
      } else {
        final message = response.data['message'] ?? 'Signup failed';
        throw Exception(message);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<DriverModel?> signIn(String email, String password) async {
    try {
      final response = await _apiService.post(
        AppConstants.loginUrl,
        data: {'email': email, 'password': password},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final userData = response.data['user'];
        final user = DriverModel.fromJson(userData);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(AppConstants.tokenKey, response.data['token']);
        await prefs.setString(AppConstants.driverIdKey, user.id);

        _userController.add(user);
        return user;
      } else {
        final message = response.data['message'] ?? 'Login failed';
        throw Exception(message);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> googleSignIn(
    Map<String, dynamic> userData,
  ) async {
    try {
      final response = await _apiService.post(
        AppConstants.googleLoginUrl,
        data: userData,
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        if (response.data['isNewUser'] == true) {
          return {
            'isNewUser': true,
            'email': response.data['email'],
            'name': response.data['name'],
            'googleId': response.data['googleId'],
            'photoUrl': response.data['photoUrl'],
          };
        } else {
          final userMap = response.data['user'];
          final user = DriverModel.fromJson(userMap);

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(AppConstants.tokenKey, response.data['token']);
          await prefs.setString(AppConstants.driverIdKey, user.id);

          _userController.add(user);
          return {'isNewUser': false, 'user': user};
        }
      } else {
        final message = response.data['message'] ?? 'Google login failed';
        throw Exception(message);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<DriverModel?> completeProfile(Map<String, dynamic> userData) async {
    try {
      final response = await _apiService.post(
        AppConstants.completeProfileUrl,
        data: userData,
      );

      if ((response.statusCode == 201 || response.statusCode == 200) &&
          response.data['success'] == true) {
        final userMap = response.data['user'];
        final user = DriverModel.fromJson(userMap);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(AppConstants.tokenKey, response.data['token']);
        await prefs.setString(AppConstants.driverIdKey, user.id);

        _userController.add(user);
        return user;
      } else {
        final message = response.data['message'] ?? 'Profile completion failed';
        throw Exception(message);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> firebasePhoneSignIn(
    String idToken,
    String role, {
    String? name,
  }) async {
    try {
      final response = await _apiService.firebasePhoneAuth({
        'idToken': idToken,
        'role': role,
        'name': name,
      });

      if (response.statusCode == 200 && response.data['success'] == true) {
        if (response.data['isNewDriver'] == true) {
          return {'isNewDriver': true, 'mobile': response.data['mobile']};
        } else {
          final userData = response.data['user'];
          final user = DriverModel.fromJson(userData);

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(AppConstants.tokenKey, response.data['token']);
          await prefs.setString(AppConstants.driverIdKey, user.id);

          _userController.add(user);
          return {'isNewDriver': false, 'user': user};
        }
      } else {
        final message =
            response.data['message'] ?? 'Firebase phone auth failed';
        throw Exception(message);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.tokenKey);
    await prefs.remove(AppConstants.driverIdKey);
    _userController.add(null);
  }

  Future<DriverModel?> getCurrentUser() async {
    try {
      final response = await _apiService.get(AppConstants.getDriverProfileUrl);
      if (response.statusCode == 200 && response.data['success'] == true) {
        final userData = response.data['data']['user'];
        final user = DriverModel.fromJson(userData);
        _userController.add(user);
        return user;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<DriverModel?> updateProfile(
    String name,
    String email,
    String mobile,
  ) async {
    try {
      final response = await _apiService.put(
        AppConstants.updateDriverProfileUrl,
        data: {'name': name, 'email': email, 'mobile': mobile},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final userData = response.data['data']['user'];
        final user = DriverModel.fromJson(userData);
        _userController.add(user);
        return user;
      } else {
        final message = response.data['message'] ?? 'Update failed';
        throw Exception(message);
      }
    } catch (e) {
      rethrow;
    }
  }
}
