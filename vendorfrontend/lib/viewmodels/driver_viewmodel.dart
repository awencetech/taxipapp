import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../core/constants/app_constants.dart';
import '../models/vendor_models.dart';

class DriverViewModel extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  bool _isLoading = false;
  List<Driver> _drivers = [];
  String? _errorMessage;

  bool get isLoading => _isLoading;
  List<Driver> get drivers => _drivers;
  String? get errorMessage => _errorMessage;

  Future<void> fetchDrivers() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.get(AppConstants.vendorDriversUrl);
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        _drivers = data.map((json) => Driver.fromJson(json)).toList();
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
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
}
