import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../core/constants/app_constants.dart';
import '../models/vendor_models.dart';

class VehicleViewModel extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  bool _isLoading = false;
  List<Vehicle> _vehicles = [];
  String? _errorMessage;

  bool get isLoading => _isLoading;
  List<Vehicle> get vehicles => _vehicles;
  String? get errorMessage => _errorMessage;

  Future<void> fetchVehicles() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.get(AppConstants.vendorVehiclesUrl);
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        _vehicles = data.map((json) => Vehicle.fromJson(json)).toList();
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addVehicle(Map<String, dynamic> vehicleData) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.post(
        AppConstants.vendorAddVehicleUrl,
        data: vehicleData,
      );
      if (response.statusCode == 201) {
        await fetchVehicles();
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

  Future<bool> deleteVehicle(String vehicleId) async {
    try {
      final response = await _apiService.delete(
        '${AppConstants.vendorVehiclesUrl}/$vehicleId',
      );
      if (response.statusCode == 200) {
        _vehicles.removeWhere((v) => v.id == vehicleId);
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
