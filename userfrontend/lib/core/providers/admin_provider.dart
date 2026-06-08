import 'package:flutter/material.dart';
import '../models/ride_model.dart';
import '../models/payment_model.dart';
import '../models/settings_model.dart';
import '../services/api_service.dart';

class AdminProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<RideModel> _rides = [];
  List<PaymentModel> _payments = [];
  SettingsModel? _settings;
  double _totalEarnings = 0;
  Map<String, dynamic> _stats = {};
  bool _isLoading = false;
  String? _error;

  List<RideModel> get rides => _rides;
  List<PaymentModel> get payments => _payments;
  SettingsModel? get settings => _settings;
  double get totalEarnings => _totalEarnings;
  Map<String, dynamic> get stats => _stats;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchStats() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.getAdminStats();
      if (response.statusCode == 200 && response.data['success'] == true) {
        _stats = response.data['data'] ?? {};
      } else {
        _error = response.data['message'] ?? 'Failed to fetch stats';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchRides() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.getAdminRides();
      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];
        if (data != null && data['rides'] != null) {
          final List ridesData = data['rides'];
          _rides = ridesData.map((e) => RideModel.fromMap(e)).toList();
        } else {
          _rides = [];
        }
      } else {
        _error = response.data['message'] ?? 'Failed to fetch rides';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchPayments() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.getAdminPayments();
      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];
        if (data != null) {
          if (data['payments'] != null) {
            final List paymentsData = data['payments'];
            _payments =
                paymentsData.map((e) => PaymentModel.fromMap(e)).toList();
          } else {
            _payments = [];
          }
          _totalEarnings = (data['totalEarnings'] ?? 0.0).toDouble();
        }
      } else {
        _error = response.data['message'] ?? 'Failed to fetch payments';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchSettings() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.getAdminSettings();
      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];
        if (data != null && data['settings'] != null) {
          _settings = SettingsModel.fromMap(data['settings']);
        }
      } else {
        _error = response.data['message'] ?? 'Failed to fetch settings';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateSettings(SettingsModel newSettings) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response =
          await _apiService.updateAdminSettings(newSettings.toMap());
      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];
        if (data != null && data['settings'] != null) {
          _settings = SettingsModel.fromMap(data['settings']);
        }
        return true;
      } else {
        _error = response.data['message'] ?? 'Failed to update settings';
        return false;
      }
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
