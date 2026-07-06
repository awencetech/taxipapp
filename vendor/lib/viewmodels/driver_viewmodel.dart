import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../core/constants/app_constants.dart';
import '../models/vendor_models.dart';

class DriverViewModel extends ChangeNotifier {
  final ApiService _apiService;

  bool _isLoading = false;
  bool _isFetching = false;
  List<Driver> _drivers = [];
  String? _errorMessage;

  DriverViewModel({required ApiService apiService}) : _apiService = apiService;

  bool get isLoading => _isLoading;
  List<Driver> get drivers => _drivers;
  String? get errorMessage => _errorMessage;

  Future<void> fetchDrivers() async {
    if (_isFetching) return;

    _isFetching = true;
    _isLoading = _drivers.isEmpty;
    _errorMessage = null;
    if (_isLoading) notifyListeners();

    try {
      final response = await _apiService.get(AppConstants.vendorDriversUrl);
      if (response.statusCode == 200) {
        if (response.data is List) {
          final List<dynamic> data = response.data;
          _drivers = data.map((json) => Driver.fromJson(json)).toList();
        } else {
          _errorMessage = 'Invalid response format: expected a list of drivers';
          _drivers = [];
        }
      }
    } catch (e) {
      debugPrint('Error fetching drivers: $e');
      _errorMessage = e.toString();
      _drivers = [];
    } finally {
      _isFetching = false;
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addDriver(Map<String, dynamic> driverData) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.post(
        AppConstants.vendorAddDriverUrl,
        data: driverData,
      );
      if (response.statusCode == 201) {
        await fetchDrivers();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteDriver(String driverId) async {
    try {
      final response = await _apiService.delete(
        '${AppConstants.vendorDriversUrl}/$driverId',
      );
      if (response.statusCode == 200) {
        _drivers.removeWhere((d) => d.id == driverId);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    }
  }

  Future<bool> approveDriver(String driverId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.put(
        '${AppConstants.vendorDriversUrl}/$driverId/approve',
      );
      if (response.statusCode == 200) {
        await fetchDrivers();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> declineDriver(String driverId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.put(
        '${AppConstants.vendorDriversUrl}/$driverId/decline',
      );
      if (response.statusCode == 200) {
        await fetchDrivers();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
