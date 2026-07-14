import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import '../models/driver_models.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/google_auth_service.dart';
import '../services/socket_service.dart';
import '../core/constants/app_constants.dart';

class AuthViewModel extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();
  final GoogleAuthService _googleAuthService = GoogleAuthService();
  final SocketService _socketService = SocketService();

  DriverModel? _driver;
  Map<String, dynamic>? _newDriverInfo;
  bool _isLoading = false;
  String? _error;

  DriverModel? get driver => _driver;
  Map<String, dynamic>? get newDriverInfo => _newDriverInfo;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _driver != null;
  List<DocumentModel> get documents => _driver?.documents ?? [];

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // SharedPreferences keys
  static const String _driverDataKey = 'driver_data';

  // Get documents by category
  List<DocumentModel> getDocumentsByCategory(String category) {
    return _driver?.documents
            .where((doc) => doc.category == category)
            .toList() ??
        [];
  }

  // Upload a document to backend
  Future<bool> uploadDocument({
    required String title,
    required String category,
    XFile? documentFile,
    DateTime? expiryDate,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      FormData formData = FormData();
      formData.fields.add(MapEntry('title', title));
      formData.fields.add(MapEntry('category', category));
      if (expiryDate != null) {
        formData.fields.add(
          MapEntry('expiryDate', expiryDate.toIso8601String()),
        );
      }
      if (documentFile != null) {
        if (kIsWeb) {
          final bytes = await documentFile.readAsBytes();
          formData.files.add(
            MapEntry(
              'document',
              MultipartFile.fromBytes(bytes, filename: documentFile.name),
            ),
          );
        } else {
          formData.files.add(
            MapEntry(
              'document',
              await MultipartFile.fromFile(
                documentFile.path,
                filename: documentFile.name,
              ),
            ),
          );
        }
      }

      final response = await _apiService.post(
        AppConstants.uploadDocumentUrl,
        data: formData,
      );

      if (response.data['success'] == true) {
        await fetchDriverProfile();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response.data['message'] ?? 'Failed to upload document';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('Error uploading document: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Edit an existing document
  Future<bool> editDocument({
    required String docId,
    required String title,
    required String category,
    XFile? documentFile,
    DateTime? expiryDate,
    String? status,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      FormData formData = FormData();
      formData.fields.add(MapEntry('title', title));
      formData.fields.add(MapEntry('category', category));
      if (expiryDate != null) {
        formData.fields.add(
          MapEntry('expiryDate', expiryDate.toIso8601String()),
        );
      }
      if (status != null) {
        formData.fields.add(MapEntry('status', status));
      }
      if (documentFile != null) {
        if (kIsWeb) {
          final bytes = await documentFile.readAsBytes();
          formData.files.add(
            MapEntry(
              'document',
              MultipartFile.fromBytes(bytes, filename: documentFile.name),
            ),
          );
        } else {
          formData.files.add(
            MapEntry(
              'document',
              await MultipartFile.fromFile(
                documentFile.path,
                filename: documentFile.name,
              ),
            ),
          );
        }
      }

      final url = AppConstants.editDocumentUrl.replaceAll(':docId', docId);
      final response = await _apiService.put(url, data: formData);

      if (response.data['success'] == true) {
        await fetchDriverProfile();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response.data['message'] ?? 'Failed to edit document';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('Error editing document: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Delete a document
  Future<bool> deleteDocument({required String docId}) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final url = AppConstants.deleteDocumentUrl.replaceAll(':docId', docId);
      final response = await _apiService.delete(url);

      if (response.data['success'] == true) {
        await fetchDriverProfile();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response.data['message'] ?? 'Failed to delete document';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('Error deleting document: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Save driver model to SharedPreferences for persistence
  Future<void> _saveDriverToPrefs(DriverModel driver) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_driverDataKey, jsonEncode(driver.toJson()));
  }

  // Load driver model from SharedPreferences
  Future<DriverModel?> _loadDriverFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final driverJson = prefs.getString(_driverDataKey);
    if (driverJson != null) {
      try {
        final driverMap = jsonDecode(driverJson) as Map<String, dynamic>;
        return DriverModel.fromJson(driverMap);
      } catch (e) {
        debugPrint('Failed to load driver from prefs: $e');
        return null;
      }
    }
    return null;
  }

  Future<void> fetchDriverProfile() async {
    try {
      debugPrint('fetchDriverProfile: Starting...');
      _isLoading = true;
      notifyListeners();

      final response = await _apiService.get(AppConstants.getDriverProfileUrl);
      debugPrint(
        'fetchDriverProfile: Response received, status: ${response.statusCode}',
      );
      debugPrint('fetchDriverProfile: Response data: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data;
        debugPrint(
          'fetchDriverProfile: Top-level data type: ${data.runtimeType}',
        );

        final actualData = (data is Map && data['data'] != null)
            ? data['data']
            : data;
        debugPrint(
          'fetchDriverProfile: actualData type: ${actualData.runtimeType}',
        );

        final userData = (actualData is Map)
            ? (actualData['user'] ?? actualData['driver'] ?? actualData)
            : actualData;
        debugPrint(
          'fetchDriverProfile: userData type: ${userData.runtimeType}',
        );
        debugPrint('fetchDriverProfile: userData content: $userData');

        if (userData is Map) {
          debugPrint('fetchDriverProfile: Parsing DriverModel...');
          _driver = DriverModel.fromJson(Map<String, dynamic>.from(userData));
          debugPrint('fetchDriverProfile: DriverModel parsed successfully!');
          debugPrint('fetchDriverProfile: _driver.id: ${_driver?.id}');
          debugPrint('fetchDriverProfile: _driver.name: ${_driver?.name}');
          debugPrint(
            'fetchDriverProfile: _driver.documents length: ${_driver?.documents.length}',
          );

          final prefs = await SharedPreferences.getInstance();
          if (_driver != null) {
            debugPrint('fetchDriverProfile: Saving driver to prefs...');
            await prefs.setString(AppConstants.driverIdKey, _driver!.id);
            await _saveDriverToPrefs(_driver!);
            debugPrint('fetchDriverProfile: Driver saved to prefs!');
          }
        } else {
          debugPrint('fetchDriverProfile: userData is NOT a Map!');
        }
      }
    } catch (e, stackTrace) {
      debugPrint('fetchDriverProfile: ERROR CAUGHT!');
      debugPrint('fetchDriverProfile: Error: $e');
      debugPrint('fetchDriverProfile: Stack trace: $stackTrace');
      final errorMsg = e.toString().toLowerCase();
      if (errorMsg.contains('403') ||
          errorMsg.contains('not approved') ||
          errorMsg.contains('approved')) {
        _error = 'Driver not approved. Please wait for vendor/admin approval.';
        await logout();
      }
    } finally {
      debugPrint(
        'fetchDriverProfile: Finally block, setting _isLoading to false',
      );
      _isLoading = false;
      notifyListeners();
      debugPrint('fetchDriverProfile: Notified listeners!');
    }
  }

  Future<void> checkAutoLogin() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _isLoading = true;
      notifyListeners();

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AppConstants.tokenKey);

      // First try to load locally from SharedPreferences as fallback
      final savedDriver = await _loadDriverFromPrefs();
      if (savedDriver != null) {
        _driver = savedDriver;
        notifyListeners();
      }

      // Then try to update from backend
      if (token != null) {
        await fetchDriverProfile();
      }

      _isLoading = false;
      notifyListeners();
    });
  }

  Future<bool> updateDriverProfile({
    String? name,
    String? mobile,
    String? email,
    String? address,
    XFile? profilePicFile,
    String? profilePicUrl,
    String? vehicleType,
    String? vehicleNumber,
    String? bankName,
    String? accountHolderName,
    String? accountNumber,
    String? ifscCode,
    String? branchName,
    List<BankAccountModel>? bankAccounts,
  }) async {
    try {
      debugPrint('updateDriverProfile called');
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Prepare request data
      dynamic requestData;
      Map<String, dynamic> baseData = {
        'name': name,
        'mobile': mobile,
        'email': email,
        'address': address,
        'vehicleType': vehicleType,
        'vehicleNumber': vehicleNumber,
        'bankName': bankName,
        'accountHolderName': accountHolderName,
        'accountNumber': accountNumber,
        'ifscCode': ifscCode,
        'branchName': branchName,
        if (bankAccounts != null)
          'bankAccounts': bankAccounts.map((e) => e.toJson()).toList(),
      };

      // If we have a profilePicFile, create FormData
      if (profilePicFile != null) {
        debugPrint('Creating FormData for file upload');
        Map<String, dynamic> formDataMap = Map.from(baseData);

        if (kIsWeb) {
          // For web, use fromBytes
          final bytes = await profilePicFile.readAsBytes();
          formDataMap['profilePic'] = MultipartFile.fromBytes(
            bytes,
            filename: profilePicFile.name,
          );
        } else {
          // For mobile, use fromFile
          formDataMap['profilePic'] = await MultipartFile.fromFile(
            profilePicFile.path,
            filename: profilePicFile.name,
          );
        }

        requestData = FormData.fromMap(formDataMap);
      } else {
        debugPrint('Sending regular JSON data');
        requestData = baseData;
      }

      final response = await _apiService.put(
        AppConstants.updateDriverProfileUrl,
        data: requestData,
      );

      debugPrint('updateDriverProfile response: ${response.data}');

      if (response.data['success'] == true) {
        // First try to get updated driver from backend
        final backendDriverData =
            response.data['data']['user'] ?? response.data;

        if (backendDriverData != null &&
            backendDriverData is Map<String, dynamic>) {
          _driver = DriverModel.fromJson(backendDriverData);
          debugPrint('Loaded driver from backend: ${_driver?.profilePic}');
        } else if (_driver != null) {
          // Fallback: manually update current driver object
          _driver = DriverModel(
            id: _driver!.id,
            name: name ?? _driver!.name,
            email: email ?? _driver!.email,
            mobile: mobile ?? _driver!.mobile,
            vehicleType: vehicleType ?? _driver!.vehicleType,
            vehicleNumber: vehicleNumber ?? _driver!.vehicleNumber,
            address: address ?? _driver!.address,
            isOnline: _driver!.isOnline,
            profilePic: profilePicUrl ?? _driver!.profilePic,
            rating: _driver!.rating,
            bankName: bankName ?? _driver!.bankName,
            accountHolderName: accountHolderName ?? _driver!.accountHolderName,
            accountNumber: accountNumber ?? _driver!.accountNumber,
            ifscCode: ifscCode ?? _driver!.ifscCode,
            branchName: branchName ?? _driver!.branchName,
            bankAccounts: bankAccounts ?? _driver!.bankAccounts,
          );
          debugPrint('Manually updated driver: ${_driver?.profilePic}');
        }

        if (_driver != null) {
          await _saveDriverToPrefs(_driver!);
        }
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
      debugPrint('Error in updateDriverProfile: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      debugPrint('AuthViewModel.changePassword: Starting...');
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await _apiService.put(
        AppConstants.changePasswordUrl,
        data: {'currentPassword': currentPassword, 'newPassword': newPassword},
      );

      debugPrint(
        'AuthViewModel.changePassword: Response status: ${response.statusCode}',
      );
      debugPrint(
        'AuthViewModel.changePassword: Response data: ${response.data}',
      );

      if (response.data['success'] == true) {
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response.data['message'] ?? 'Failed to change password';
        debugPrint('AuthViewModel.changePassword: Error: $_error');
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('AuthViewModel.changePassword: Error caught: $e');
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteBankDetails() async {
    return await updateDriverProfile(
      bankName: '',
      accountHolderName: '',
      accountNumber: '',
      ifscCode: '',
      branchName: '',
    );
  }

  Future<bool> sendOTP(String phone) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Mocking OTP send for now as backend seems to only have it for forgot password
      // In a real app, this would call an endpoint like /auth/send-otp
      await Future.delayed(const Duration(seconds: 1));
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<Map<String, dynamic>> signInWithFirebasePhone(
    String idToken,
    String role, {
    String? name,
    String? firebaseUid,
    String? mobile,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _authService.firebasePhoneSignIn(
        idToken,
        role,
        name: name,
      );
      if (result['isNewDriver'] == true) {
        _newDriverInfo = {...result, 'firebaseUid': firebaseUid};
        _isLoading = false;
        notifyListeners();
        return {'success': true, 'isNewDriver': true};
      } else {
        _driver = result['user'];
        if (_driver != null) {
          _socketService.connect(_driver!.id);

          // Save login session to SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('isLoggedIn', true);
          await prefs.setString('authProvider', 'phone');
          if (mobile != null) {
            await prefs.setString('mobile', mobile);
          }
        }
        _isLoading = false;
        notifyListeners();
        return {'success': true, 'isNewDriver': false};
      }
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return {'success': false};
    }
  }

  Future<bool> login(String email, String password) async {
    debugPrint('=== AuthViewModel: Starting login ===');
    debugPrint('Clearing old auth data first...');
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Clear any old tokens or driver data
    _driver = null;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      debugPrint(
        'AuthViewModel: Sending POST request to ${AppConstants.driverLoginUrl}',
      );
      final response = await _apiService.post(
        AppConstants.driverLoginUrl,
        data: {
          'email': email,
          'password': password,
          'role': 'driver', // Ensure role is specified for auth controller
        },
      );
      debugPrint(
        'AuthViewModel: Login response status: ${response.statusCode}',
      );
      debugPrint('AuthViewModel: Login response data: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;

        // Check for success flag if present in the response
        if (data is Map && data['success'] == false) {
          _error = data['message'] ?? 'Login failed';
          debugPrint('AuthViewModel: Login failed with message: $_error');
          _isLoading = false;
          notifyListeners();
          return false;
        }

        // Check if data is nested under 'data' key
        final actualData = (data is Map && data['data'] != null)
            ? data['data']
            : data;

        final token = (actualData is Map)
            ? (actualData['token'] ?? data['token'])
            : null;

        if (token != null) {
          debugPrint('AuthViewModel: Token found, saving to prefs: $token');
          await prefs.setString(AppConstants.tokenKey, token);

          // Now fetch the full driver profile from /drivers/profile
          await fetchDriverProfile();

          _isLoading = false;
          debugPrint(
            'AuthViewModel: Login successful, isLoggedIn=${_driver != null}',
          );
          notifyListeners();
          return true;
        } else {
          _error = 'Token not found in response';
          debugPrint('AuthViewModel: $_error');
          _isLoading = false;
          notifyListeners();
          return false;
        }
      }
      debugPrint(
        'AuthViewModel: Login failed with status ${response.statusCode}',
      );
      _error = 'Login failed with status ${response.statusCode}';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('AuthViewModel: Login error caught: $e');
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<Map<String, dynamic>> register(
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
        AppConstants.driverSignupUrl,
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
        final actualData = (data is Map && data['data'] != null)
            ? data['data']
            : data;
        final token = (actualData is Map)
            ? (actualData['token'] ?? data['token'])
            : null;

        if (token == null) {
          _error = 'Token not found in response';
          _isLoading = false;
          notifyListeners();
          return {'success': false, 'message': _error};
        }

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(AppConstants.tokenKey, token);

        final driverResponse = await _apiService.post(
          AppConstants.driverRegisterUrl,
          data: {'vehicleType': vehicleType, 'vehicleNumber': vehicleNumber},
        );

        if (driverResponse.statusCode == 200 ||
            driverResponse.statusCode == 201) {
          _isLoading = false;
          notifyListeners();
          return {'success': true, 'message': 'Registration submitted'};
        } else {
          _error = 'Failed to submit driver details';
          _isLoading = false;
          notifyListeners();
          return {'success': false, 'message': _error};
        }
      } else {
        _error = response.data['message'] ?? 'Signup failed';
        _isLoading = false;
        notifyListeners();
        return {'success': false, 'message': _error};
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': _error};
    }
  }

  Future<Map<String, dynamic>> loginWithGoogle() async {
    _isLoading = true;
    _error = null;
    _newDriverInfo = null;
    notifyListeners();

    try {
      final googleData = await _googleAuthService.signIn();
      if (googleData == null) {
        _isLoading = false;
        notifyListeners();
        return {'success': false};
      }

      final driverData = {
        'googleToken': googleData['idToken'] ?? googleData['accessToken'],
        'email': googleData['email'],
        'name': googleData['name'],
        'googleId': googleData['googleId'],
        'photoUrl': googleData['photoUrl'],
      };

      final response = await _apiService.post(
        AppConstants.googleLoginUrl,
        data: driverData,
      );

      // Handle new user case first
      if (response.data['isNewUser'] == true) {
        _newDriverInfo = response.data;
        _isLoading = false;
        notifyListeners();
        return {'success': true, 'status': 'NOT_FOUND', 'isNewUser': true};
      }

      final data = response.data;
      final actualData = (data['data'] != null) ? data['data'] : data;
      final driver = DriverModel.fromJson(actualData['user'] ?? actualData);

      // Determine driver status
      String status;
      String? rejectionReason;

      if (driver.status == 'approved' || driver.approvalStatus == 'approved') {
        status = 'APPROVED';
      } else if (driver.status == 'rejected' ||
          driver.approvalStatus == 'rejected') {
        status = 'REJECTED';
        rejectionReason = driver.rejectionReason;
      } else if (driver.status == 'pending' ||
          driver.approvalStatus == 'pending') {
        status = 'PENDING';
      } else {
        status = 'PENDING'; // Default to pending if status is unknown
      }

      if (status == 'APPROVED') {
        // Save driver and token only if approved
        _driver = driver;

        final prefs = await SharedPreferences.getInstance();
        final token = actualData['token'] ?? data['token'];
        if (token != null) {
          await prefs.setString(AppConstants.tokenKey, token);
          await prefs.setString(AppConstants.driverIdKey, driver.id);
          await _saveDriverToPrefs(driver);
        }
      } else {
        // Don't save full driver object if not approved, just keep for status check
        _driver = null;
      }

      _isLoading = false;
      notifyListeners();

      return {
        'success': true,
        'status': status,
        'rejectionReason': rejectionReason,
        'isNewUser': false,
      };
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return {'success': false};
    }
  }

  Future<bool> registerPendingDriver(
    String name,
    String lastName,
    String mobile,
    String vehicleType,
    String vehicleNumber, {
    String? firebaseUid,
    String? googleId,
    String countryCode = '+91',
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.post(
        AppConstants.driverRegisterPendingUrl,
        data: {
          'name': name,
          'lastName': lastName,
          'mobile': mobile,
          'vehicleType': vehicleType,
          'vehicleNumber': vehicleNumber,
          if (firebaseUid != null) 'firebaseUid': firebaseUid,
          if (googleId != null) 'googleId': googleId,
          'countryCode': countryCode,
        },
      );

      if (response.data['success'] == true) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('pending_mobile', mobile);
        if (firebaseUid != null) {
          await prefs.setString('pending_firebase_uid', firebaseUid);
        }
        if (googleId != null) {
          await prefs.setString('pending_google_id', googleId);
        }
        await prefs.setBool('isRegistrationPending', true);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response.data['message'] ?? 'Failed to submit registration';
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

  Future<Map<String, dynamic>?> getDriverStatus({
    String? mobile,
    String? firebaseUid,
    String? googleId,
  }) async {
    try {
      final Map<String, dynamic> queryParams = {};
      if (mobile != null) queryParams['mobile'] = mobile;
      if (firebaseUid != null) queryParams['firebaseUid'] = firebaseUid;
      if (googleId != null) queryParams['googleId'] = googleId;

      final response = await _apiService.get(
        AppConstants.driverStatusUrl,
        queryParameters: queryParams,
      );

      if (response.data['success'] == true) {
        return response.data['data'];
      }
      return null;
    } catch (e) {
      _error = e.toString();
      return null;
    }
  }

  Future<bool> completeGoogleProfile(
    String name,
    String mobile, [
    String vehicleType = 'Car',
    String vehicleNumber = 'TEMP',
    String countryCode = '+91',
  ]) async {
    if (_newDriverInfo == null) return false;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final driverData = {
        ..._newDriverInfo!,
        'name': name,
        'mobile': mobile,
        'countryCode': countryCode,
        'role': 'driver',
        'authProvider': 'phone',
        'vehicleType': vehicleType,
        'vehicleNumber': vehicleNumber,
      };

      final response = await _apiService.post(
        AppConstants.completeProfileUrl,
        data: driverData,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        final actualData = (data is Map && data['data'] != null)
            ? data['data']
            : data;

        final prefs = await SharedPreferences.getInstance();
        final token = (actualData is Map)
            ? (actualData['token'] ?? data['token'])
            : null;

        if (token == null) {
          _error = 'Token not found in response';
          _isLoading = false;
          notifyListeners();
          return false;
        }

        await prefs.setString(AppConstants.tokenKey, token);
        await prefs.setString('mobile', mobile);
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('authProvider', 'phone');

        final userData = (actualData is Map)
            ? (actualData['user'] ?? actualData)
            : actualData;
        _driver = DriverModel.fromJson(
          userData is Map
              ? Map<String, dynamic>.from(userData)
              : <String, dynamic>{},
        );
        _newDriverInfo = null;

        if (_driver?.id != null) {
          await prefs.setString(AppConstants.driverIdKey, _driver!.id);
          await _saveDriverToPrefs(_driver!);
        }

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response.data['message'] ?? 'Failed to complete profile';
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

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await _googleAuthService.signOut();
    _driver = null;
    _newDriverInfo = null;
    notifyListeners();
  }
}
