import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../core/constants/app_constants.dart';
import '../models/vendor_models.dart';

class VehicleViewModel extends ChangeNotifier {
  final ApiService _apiService;

  bool _isLoading = false;
  bool _isFetching = false;
  List<Vehicle> _vehicles = [];
  String? _errorMessage;

  // Filters
  String? _searchQuery;
  String _statusFilter = 'all'; // all, active, inactive, maintenance
  String _vehicleTypeFilter = 'all'; // all, bike, auto, mini, sedan, suv
  String _driverStatusFilter = 'all'; // all, online, offline, on-trip
  String _sortBy = 'newest'; // newest, oldest, earnings, trips

  VehicleViewModel({required ApiService apiService}) : _apiService = apiService;

  bool get isLoading => _isLoading;
  List<Vehicle> get vehicles => _vehicles;
  String? get errorMessage => _errorMessage;

  String? get searchQuery => _searchQuery;
  String get statusFilter => _statusFilter;
  String get vehicleTypeFilter => _vehicleTypeFilter;
  String get driverStatusFilter => _driverStatusFilter;
  String get sortBy => _sortBy;

  void setSearchQuery(String query) {
    _searchQuery = query;
    fetchVehicles();
  }

  void setStatusFilter(String status) {
    _statusFilter = status;
    fetchVehicles();
  }

  void setVehicleTypeFilter(String type) {
    _vehicleTypeFilter = type;
    fetchVehicles();
  }

  void setDriverStatusFilter(String status) {
    _driverStatusFilter = status;
    fetchVehicles();
  }

  void setSortBy(String sort) {
    _sortBy = sort;
    fetchVehicles();
  }

  void resetFilters() {
    _searchQuery = null;
    _statusFilter = 'all';
    _vehicleTypeFilter = 'all';
    _driverStatusFilter = 'all';
    _sortBy = 'newest';
    fetchVehicles();
  }

  Future<void> fetchVehicles() async {
    if (_isFetching) return;

    _isFetching = true;
    _isLoading = _vehicles.isEmpty;
    _errorMessage = null;
    if (_isLoading) notifyListeners();

    try {
      final queryParams = <String, String>{};
      if (_searchQuery != null && _searchQuery!.isNotEmpty) {
        queryParams['search'] = _searchQuery!;
      }
      if (_statusFilter != 'all') {
        queryParams['status'] = _statusFilter;
      }
      if (_vehicleTypeFilter != 'all') {
        queryParams['vehicleType'] = _vehicleTypeFilter;
      }
      if (_driverStatusFilter != 'all') {
        queryParams['driverStatus'] = _driverStatusFilter;
      }
      queryParams['sortBy'] = _sortBy;

      final response = await _apiService.get(
        AppConstants.vendorVehiclesUrl,
        queryParameters: queryParams,
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        _vehicles = data.map((json) => Vehicle.fromJson(json)).toList();
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isFetching = false;
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
