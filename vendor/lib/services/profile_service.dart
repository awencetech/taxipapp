import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class ProfileService extends ChangeNotifier {
  static const String _kProfileImagePath = 'profile_image_path';
  static const String _kProfileImageBase64 = 'profile_image_base64';
  static const String _kUserName = 'user_name';
  static const String _kUserRole = 'user_role';

  String? _profileImagePath;
  String? _profileImageBase64;
  String _userName = 'Ramesh Patel';
  String _userRole = 'Fleet Owner';
  bool _isInitialized = false;

  String? get profileImagePath => _profileImagePath;
  String? get profileImageBase64 => _profileImageBase64;
  String get userName => _userName;
  String get userRole => _userRole;
  bool get isInitialized => _isInitialized;

  ProfileService() {
    _initialize();
  }

  Future<void> _initialize() async {
    await _loadProfileData();
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> _loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    _profileImagePath = prefs.getString(_kProfileImagePath);
    _profileImageBase64 = prefs.getString(_kProfileImageBase64);
    _userName = prefs.getString(_kUserName) ?? 'Ramesh Patel';
    _userRole = prefs.getString(_kUserRole) ?? 'Fleet Owner';
    notifyListeners();
  }

  ImageProvider? getImageProvider() {
    if (kIsWeb) {
      if (_profileImageBase64 != null) {
        return MemoryImage(_base64Decode(_profileImageBase64!));
      }
    } else {
      if (_profileImagePath != null) {
        return FileImage(File(_profileImagePath!));
      }
    }
    return null;
  }

  Uint8List _base64Decode(String source) {
    final codec = Base64Codec();
    return codec.decode(source);
  }

  String _base64Encode(Uint8List bytes) {
    final codec = Base64Codec();
    return codec.encode(bytes);
  }

  Future<void> updateProfileImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(source: source);

      if (pickedFile != null) {
        if (kIsWeb) {
          final bytes = await pickedFile.readAsBytes();
          final base64String = _base64Encode(bytes);
          await _saveProfileImageBase64(base64String);
          _profileImageBase64 = base64String;
          _profileImagePath = null;
        } else {
          final String permanentPath = await _saveImagePermanently(pickedFile);
          await _saveProfileImagePath(permanentPath);
          _profileImagePath = permanentPath;
          _profileImageBase64 = null;
        }

        notifyListeners();
      }
    } catch (e) {
      // Keep minimal logging for debugging (optional, only in debug mode
      if (kDebugMode) {
        debugPrint('Error updating profile image: $e');
      }
    }
  }

  Future<String> _saveImagePermanently(XFile imageFile) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.${imageFile.path.split('.').last}';
      final newPath = '${directory.path}/$fileName';

      final File originalFile = File(imageFile.path);
      final File newFile = await originalFile.copy(newPath);

      return newFile.path;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error saving image: $e');
      }
      return imageFile.path;
    }
  }

  Future<void> _saveProfileImagePath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kProfileImagePath, path);
    await prefs.remove(_kProfileImageBase64);
  }

  Future<void> _saveProfileImageBase64(String base64) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kProfileImageBase64, base64);
    await prefs.remove(_kProfileImagePath);
  }

  Future<void> deleteProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    if (_profileImagePath != null && !kIsWeb) {
      try {
        final File oldFile = File(_profileImagePath!);
        if (await oldFile.exists()) {
          await oldFile.delete();
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Error deleting old profile image: $e');
        }
      }
    }
    await prefs.remove(_kProfileImagePath);
    await prefs.remove(_kProfileImageBase64);
    _profileImagePath = null;
    _profileImageBase64 = null;
    notifyListeners();
  }

  Future<void> updateUserName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kUserName, name);
    _userName = name;
    notifyListeners();
  }

  Future<void> updateUserRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kUserRole, role);
    _userRole = role;
    notifyListeners();
  }

  Future<void> clearProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kProfileImagePath);
    await prefs.remove(_kProfileImageBase64);
    await prefs.remove(_kUserName);
    await prefs.remove(_kUserRole);
    _profileImagePath = null;
    _profileImageBase64 = null;
    _userName = 'Ramesh Patel';
    _userRole = 'Fleet Owner';
    notifyListeners();
  }
}