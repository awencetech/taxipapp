import 'package:shared_preferences/shared_preferences.dart';
import 'package:taxi_nanban/services/api_service.dart';
import 'package:taxi_nanban/models/user_model.dart';
import 'dart:async';

class AuthService {
  final ApiService _apiService = ApiService();
  final _userController = StreamController<UserModel?>.broadcast();

  Stream<UserModel?> get userStream => _userController.stream;

  Future<UserModel?> signUp(
      String name, String email, String password, String mobile) async {
    try {
      final response = await _apiService.register({
        'name': name,
        'email': email,
        'password': password,
        'mobile': mobile,
      });

      if (response.statusCode == 201 && response.data['success'] == true) {
        final userData = response.data['user'];
        final user = UserModel.fromMap(userData);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', response.data['token']);
        await prefs.setString('user_id', user.id);

        _userController.add(user);
        return user;
      } else {
        final message = response.data['message'] ?? 'Signup failed';
        throw Exception(message);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<UserModel?> signIn(String email, String password) async {
    try {
      final response = await _apiService.login({
        'email': email,
        'password': password,
      });

      if (response.statusCode == 200 && response.data['success'] == true) {
        final userData = response.data['user'];
        final user = UserModel.fromMap(userData);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', response.data['token']);
        await prefs.setString('user_id', user.id);

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
      Map<String, dynamic> userData) async {
    try {
      final response = await _apiService.googleLogin(userData);

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
          final user = UserModel.fromMap(userMap);

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('jwt_token', response.data['token']);
          await prefs.setString('user_id', user.id);

          _userController.add(user);
          return {
            'isNewUser': false,
            'user': user,
          };
        }
      } else {
        final message = response.data['message'] ?? 'Google login failed';
        throw Exception(message);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<UserModel?> completeProfile(Map<String, dynamic> userData) async {
    try {
      final response = await _apiService.completeProfile(userData);

      if ((response.statusCode == 201 || response.statusCode == 200) &&
          response.data['success'] == true) {
        final userMap = response.data['user'];
        final user = UserModel.fromMap(userMap);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', response.data['token']);
        await prefs.setString('user_id', user.id);

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

  Future<void> forgotPassword(String email) async {
    try {
      final response = await _apiService.forgotPassword(email);
      if (response.statusCode != 200 || response.data['success'] != true) {
        throw Exception(response.data['message'] ?? 'Failed to send OTP');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> verifyOTP(String email, String otp) async {
    try {
      final response = await _apiService.verifyOTP(email, otp);
      if (response.statusCode != 200 || response.data['success'] != true) {
        throw Exception(response.data['message'] ?? 'Invalid OTP');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> resetPassword(String email, String otp, String password) async {
    try {
      final response = await _apiService.resetPassword(email, otp, password);
      if (response.statusCode != 200 || response.data['success'] != true) {
        throw Exception(response.data['message'] ?? 'Failed to reset password');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    await prefs.remove('user_id');
    _userController.add(null);
  }

  Future<UserModel?> getCurrentUser() async {
    try {
      final response = await _apiService.getProfile();
      if (response.statusCode == 200 && response.data['success'] == true) {
        final userData = response.data['data']['user'];
        final user = UserModel.fromMap(userData);
        _userController.add(user);
        return user;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<UserModel?> updateProfile(
      String name, String email, String mobile) async {
    try {
      final response = await _apiService.updateProfile({
        'name': name,
        'email': email,
        'mobile': mobile,
      });

      if (response.statusCode == 200 && response.data['success'] == true) {
        final userData = response.data['data']['user'];
        final user = UserModel.fromMap(userData);
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
