import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../core/constants/app_constants.dart';
import '../models/vendor_models.dart';

enum AuthStatus { success, pending, declined }

class AuthViewModel extends ChangeNotifier {
  final ApiService _apiService;

  bool _isLoading = false;
  bool _isLoggedIn = false;
  Vendor? _vendor;
  String? _errorMessage;
  Map<String, dynamic>? _pendingGoogleSignUpData;
  AuthStatus? _authStatus;

  bool get isLoading => _isLoading;
  bool get isLoggedIn => _isLoggedIn;
  Vendor? get vendor => _vendor;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get pendingGoogleSignUpData => _pendingGoogleSignUpData;
  AuthStatus? get authStatus => _authStatus;

  AuthViewModel({required ApiService apiService}) : _apiService = apiService {
    _restoreLoginState();
  }

  Future<void> _restoreLoginState() async {
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

  Future<AuthStatus?> login({
    String? email,
    String? phone,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _authStatus = null;
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
        _authStatus = AuthStatus.success;
        _isLoading = false;
        notifyListeners();
        return AuthStatus.success;
      }
      return null;
    } on ApiException catch (e) {
      if (e.statusCode == 403 && e.data != null) {
        final approvalStatus = e.data!['approvalStatus'];
        if (approvalStatus == 'pending') {
          _authStatus = AuthStatus.pending;
        } else if (approvalStatus == 'declined') {
          _authStatus = AuthStatus.declined;
        }
        _isLoading = false;
        notifyListeners();
        return _authStatus;
      }
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return null;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
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

  Future<AuthStatus?> verifyOTP(String phone, String otp) async {
    _isLoading = true;
    _errorMessage = null;
    _authStatus = null;
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
        _authStatus = AuthStatus.success;
        _isLoading = false;
        notifyListeners();
        return AuthStatus.success;
      }
      return null;
    } on ApiException catch (e) {
      if (e.statusCode == 403 && e.data != null) {
        final approvalStatus = e.data!['approvalStatus'];
        if (approvalStatus == 'pending') {
          _authStatus = AuthStatus.pending;
        } else if (approvalStatus == 'declined') {
          _authStatus = AuthStatus.declined;
        }
        _isLoading = false;
        notifyListeners();
        return _authStatus;
      }
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return null;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<AuthStatus?> register(
    String name,
    String email,
    String phone,
    String password,
    String companyName,
  ) async {
    _isLoading = true;
    _errorMessage = null;
    _authStatus = null;
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
        _vendor = Vendor.fromJson(data['vendor']);
        _authStatus = AuthStatus.pending;
        _isLoading = false;
        notifyListeners();
        return AuthStatus.pending;
      }
      return null;
    } on ApiException catch (e) {
      if (e.statusCode == 403 && e.data != null) {
        final approvalStatus = e.data!['approvalStatus'];
        if (approvalStatus == 'pending') {
          _authStatus = AuthStatus.pending;
        } else if (approvalStatus == 'declined') {
          _authStatus = AuthStatus.declined;
        }
        _isLoading = false;
        notifyListeners();
        return _authStatus;
      }
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return null;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<Map<String, dynamic>> signInWithGoogle() async {
    _isLoading = true;
    _errorMessage = null;
    _pendingGoogleSignUpData = null;
    notifyListeners();

    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId: kIsWeb
            ? '996214358508-qiq5q5lovamh98dio6sj27ps69pm8evk.apps.googleusercontent.com'
            : null,
        scopes: ['email', 'profile'],
      );

      // First try silent sign in
      GoogleSignInAccount? googleUser = await googleSignIn.signInSilently();

      // If silent sign in fails, prompt user
      googleUser ??= await googleSignIn.signIn();

      if (googleUser == null) {
        _isLoading = false;
        notifyListeners();
        return {'success': false};
      }

      await googleUser.authentication;

      // First try to login with Google
      dynamic loginResponse;
      try {
        loginResponse = await _apiService.post(
          AppConstants.vendorLoginUrl,
          data: {'email': googleUser.email, 'googleId': googleUser.id},
        );
      } catch (e) {
        debugPrint('Google login failed, attempting auto-registration: $e');
      }

      if (loginResponse != null && (loginResponse.statusCode == 200 || loginResponse.statusCode == 201)) {
        // User already exists, log them in
        final data = loginResponse.data;
        final token = data['token'];
        final vendorId = data['vendor']['_id'];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(AppConstants.tokenKey, token);
        await prefs.setString(AppConstants.vendorIdKey, vendorId);

        _vendor = Vendor.fromJson(data['vendor']);
        _isLoggedIn = true;
        _isLoading = false;
        notifyListeners();
        return {'success': true, 'isNewUser': false};
      }

      // If user does not exist (or login fails), automatically register them
      try {
        final phone = '555${(DateTime.now().millisecondsSinceEpoch % 10000000).toString().padLeft(7, '0')}';
        final companyName = '${googleUser.displayName ?? 'Vendor'} Company';
        const password = 'GooglePass123!';

        final registerResponse = await _apiService.post(
          AppConstants.vendorRegisterUrl,
          data: {
            'name': googleUser.displayName ?? 'Vendor',
            'email': googleUser.email,
            'googleId': googleUser.id,
            'phone': phone,
            'password': password,
            'companyName': companyName,
          },
        );

        if (registerResponse.statusCode == 200 || registerResponse.statusCode == 201) {
          final data = registerResponse.data;
          final token = data['token'];
          final vendorId = data['vendor']['_id'];

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(AppConstants.tokenKey, token);
          await prefs.setString(AppConstants.vendorIdKey, vendorId);

          _vendor = Vendor.fromJson(data['vendor']);
          _isLoggedIn = true;
          _isLoading = false;
          notifyListeners();
          return {'success': true, 'isNewUser': false};
        }
      } catch (regError) {
        debugPrint('Auto-registration failed, falling back to manual: $regError');
      }
    } catch (e) {
      debugPrint('Google login failed: $e');
    }

    // If login/auto-registration failed, store Google data for later registration
    final GoogleSignIn googleSignIn = GoogleSignIn(
      clientId: kIsWeb
          ? '1019476576912-mj1gij1eapfqgm2tl27nujd0qh720tjj.apps.googleusercontent.com'
          : null,
    );
    final GoogleSignInAccount? googleUser = await googleSignIn.signInSilently();

    if (googleUser != null) {
      _pendingGoogleSignUpData = {
        'name': googleUser.displayName ?? 'Vendor',
        'email': googleUser.email,
        'googleId': googleUser.id,
      };
      _isLoading = false;
      notifyListeners();
      return {'success': true, 'isNewUser': true};
    }

    _isLoading = false;
    notifyListeners();
    return {'success': false};
  }

  Future<Map<String, dynamic>> signUpWithGoogle() async {
    _isLoading = true;
    _errorMessage = null;
    _pendingGoogleSignUpData = null;
    notifyListeners();

    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId: kIsWeb
            ? '996214358508-qiq5q5lovamh98dio6sj27ps69pm8evk.apps.googleusercontent.com'
            : null,
        scopes: ['email', 'profile'],
      );

      // First try silent sign in
      GoogleSignInAccount? googleUser = await googleSignIn.signInSilently();

      // If silent sign in fails, prompt user
      googleUser ??= await googleSignIn.signIn();

      if (googleUser == null) {
        _isLoading = false;
        notifyListeners();
        return {'success': false};
      }

      await googleUser.authentication;

      // First try to login with Google
      dynamic loginResponse;
      try {
        loginResponse = await _apiService.post(
          AppConstants.vendorLoginUrl,
          data: {'email': googleUser.email, 'googleId': googleUser.id},
        );
      } catch (e) {
        debugPrint('Google login failed, proceeding to registration: $e');
      }

      if (loginResponse != null && (loginResponse.statusCode == 200 || loginResponse.statusCode == 201)) {
        // User already exists, log them in
        final data = loginResponse.data;
        final token = data['token'];
        final vendorId = data['vendor']['_id'];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(AppConstants.tokenKey, token);
        await prefs.setString(AppConstants.vendorIdKey, vendorId);

        _vendor = Vendor.fromJson(data['vendor']);
        _isLoggedIn = true;
        _isLoading = false;
        notifyListeners();
        return {'success': true, 'isNewUser': false};
      }

      // If user does not exist (or login fails), automatically register them
      try {
        final phone = '555${(DateTime.now().millisecondsSinceEpoch % 10000000).toString().padLeft(7, '0')}';
        final companyName = '${googleUser.displayName ?? 'Vendor'} Company';
        const password = 'GooglePass123!';

        final registerResponse = await _apiService.post(
          AppConstants.vendorRegisterUrl,
          data: {
            'name': googleUser.displayName ?? 'Vendor',
            'email': googleUser.email,
            'googleId': googleUser.id,
            'phone': phone,
            'password': password,
            'companyName': companyName,
          },
        );

        if (registerResponse.statusCode == 200 || registerResponse.statusCode == 201) {
          final data = registerResponse.data;
          final token = data['token'];
          final vendorId = data['vendor']['_id'];

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(AppConstants.tokenKey, token);
          await prefs.setString(AppConstants.vendorIdKey, vendorId);

          _vendor = Vendor.fromJson(data['vendor']);
          _isLoggedIn = true;
          _isLoading = false;
          notifyListeners();
          return {'success': true, 'isNewUser': false};
        }
      } catch (regError) {
        debugPrint('Auto-registration failed, falling back to manual: $regError');
      }
    } catch (e) {
      debugPrint('Google login failed, proceeding to sign up: $e');
    }

    // If login/auto-registration failed, store Google data for later registration
    final GoogleSignIn googleSignIn = GoogleSignIn(
      clientId: kIsWeb
          ? '1019476576912-mj1gij1eapfqgm2tl27nujd0qh720tjj.apps.googleusercontent.com'
          : null,
    );
    final GoogleSignInAccount? googleUser = await googleSignIn.signInSilently();

    if (googleUser != null) {
      _pendingGoogleSignUpData = {
        'name': googleUser.displayName ?? 'Vendor',
        'email': googleUser.email,
        'googleId': googleUser.id,
      };
      _isLoading = false;
      notifyListeners();
      return {'success': true, 'isNewUser': true};
    }

    _isLoading = false;
    notifyListeners();
    return {'success': false};
  }

  Future<AuthStatus?> completeGoogleSignUp({
    required String phone,
    required String password,
    required String companyName,
  }) async {
    if (_pendingGoogleSignUpData == null) {
      return null;
    }

    _isLoading = true;
    _errorMessage = null;
    _authStatus = null;
    notifyListeners();

    try {
      final response = await _apiService.post(
        AppConstants.vendorRegisterUrl,
        data: {
          ..._pendingGoogleSignUpData!,
          'phone': phone,
          'password': password,
          'companyName': companyName,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        final vendorData = data['vendor'];
        
        // Check approval status
        final approvalStatus = vendorData['approvalStatus'];
        if (approvalStatus == 'pending') {
          _authStatus = AuthStatus.pending;
          _isLoading = false;
          notifyListeners();
          return AuthStatus.pending;
        } else if (approvalStatus == 'declined') {
          _authStatus = AuthStatus.declined;
          _isLoading = false;
          notifyListeners();
          return AuthStatus.declined;
        }

        // If approved, log them in
        final token = data['token'];
        final vendorId = vendorData['_id'];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(AppConstants.tokenKey, token);
        await prefs.setString(AppConstants.vendorIdKey, vendorId);

        _vendor = Vendor.fromJson(vendorData);
        _isLoggedIn = true;
        _pendingGoogleSignUpData = null;
        _authStatus = AuthStatus.success;
        _isLoading = false;
        notifyListeners();
        return AuthStatus.success;
      }
      return null;
    } on ApiException catch (e) {
      if (e.statusCode == 403 && e.data != null) {
        final approvalStatus = e.data!['approvalStatus'];
        if (approvalStatus == 'pending') {
          _authStatus = AuthStatus.pending;
        } else if (approvalStatus == 'declined') {
          _authStatus = AuthStatus.declined;
        }
        _isLoading = false;
        notifyListeners();
        return _authStatus;
      }
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return null;
    } catch (e) {
      _errorMessage = 'Something went wrong. Please try again.';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.tokenKey);
    await prefs.remove(AppConstants.vendorIdKey);

    // Sign out from Google
    final GoogleSignIn googleSignIn = GoogleSignIn(
      clientId: kIsWeb
          ? '1019476576912-mj1gij1eapfqgm2tl27nujd0qh720tjj.apps.googleusercontent.com'
          : null,
    );
    try {
      await googleSignIn.signOut();
    } catch (e) {
      debugPrint('Error signing out from Google: $e');
    }

    _isLoggedIn = false;
    _vendor = null;
    notifyListeners();
  }
}
