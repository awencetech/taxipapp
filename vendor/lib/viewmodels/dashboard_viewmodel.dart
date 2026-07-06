import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../core/constants/app_constants.dart';
import '../models/vendor_models.dart';

class DashboardViewModel extends ChangeNotifier {
  final ApiService _apiService;

  bool _isLoading = false;
  bool _isFetching = false;
  DashboardStats? _stats;
  String? _errorMessage;

  DashboardViewModel({required ApiService apiService}) : _apiService = apiService;

  bool get isLoading => _isLoading;
  DashboardStats? get stats => _stats;
  String? get errorMessage => _errorMessage;

  Future<void> fetchDashboardStats() async {
    if (_isFetching) return;

    _isFetching = true;
    _isLoading = _stats == null;
    _errorMessage = null;
    if (_isLoading) notifyListeners();

    try {
      final response = await _apiService.get(AppConstants.vendorDashboardUrl);
      if (response.statusCode == 200) {
        _stats = DashboardStats.fromJson(response.data);
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isFetching = false;
      _isLoading = false;
      notifyListeners();
    }
  }
}
