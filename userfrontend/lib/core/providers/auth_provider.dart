import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/google_auth_service.dart';
import '../services/socket_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final GoogleAuthService _googleAuthService = GoogleAuthService();
  final SocketService _socketService = SocketService();
  UserModel? _user;
  Map<String, dynamic>? _newUserInfo;
  bool _isLoading = false;
  String? _error;

  UserModel? get user => _user;
  Map<String, dynamic>? get newUserInfo => _newUserInfo;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _user != null;

  Future<void> checkAuthStatus() async {
    _user = await _authService.getCurrentUser();
    if (_user != null) {
      _socketService.connect(_user!.id);
    }
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _user = await _authService.signIn(email, password);
      if (_user != null) {
        _socketService.connect(_user!.id);
      }
      _isLoading = false;
      notifyListeners();
      return _user != null;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<Map<String, dynamic>> loginWithGoogle() async {
    _isLoading = true;
    _error = null;
    _newUserInfo = null;
    notifyListeners();

    try {
      final googleData = await _googleAuthService.signIn();
      if (googleData == null) {
        _isLoading = false;
        notifyListeners();
        return {'success': false};
      }

      final result = await _authService.googleSignIn(googleData);

      if (result['isNewUser'] == true) {
        _newUserInfo = result;
        _isLoading = false;
        notifyListeners();
        return {'success': true, 'isNewUser': true};
      } else {
        _user = result['user'];
        if (_user != null) {
          _socketService.connect(_user!.id);
        }
        _isLoading = false;
        notifyListeners();
        return {'success': true, 'isNewUser': false};
      }
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return {'success': false};
    }
  }

  Future<bool> completeGoogleProfile(String name, String mobile) async {
    if (_newUserInfo == null) return false;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final userData = {
        ..._newUserInfo!,
        'name': name,
        'mobile': mobile,
      };

      _user = await _authService.completeProfile(userData);
      if (_user != null) {
        _socketService.connect(_user!.id);
      }
      _newUserInfo = null;
      _isLoading = false;
      notifyListeners();
      return _user != null;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(
      String name, String email, String password, String mobile) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _user = await _authService.signUp(name, email, password, mobile);
      if (_user != null) {
        _socketService.connect(_user!.id);
      }
      _isLoading = false;
      notifyListeners();
      return _user != null;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _authService.signOut();
    _socketService.disconnect();
    _user = null;
    notifyListeners();
  }

  Future<bool> signInWithFirebasePhone(String idToken, String role, {String? name}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _user = await _authService.firebasePhoneSignIn(idToken, role, name: name);
      if (_user != null) {
        _socketService.connect(_user!.id);
      }
      _isLoading = false;
      notifyListeners();
      return _user != null;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> forgotPassword(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.forgotPassword(email);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> verifyOTP(String email, String otp) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.verifyOTP(email, otp);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> resetPassword(String email, String otp, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.resetPassword(email, otp, password);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProfile(String name, String email, String mobile) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updatedUser = await _authService.updateProfile(name, email, mobile);
      if (updatedUser != null) {
        _user = updatedUser;
        _isLoading = false;
        notifyListeners();
        return true;
      }
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
