import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../core/constants/app_constants.dart';
import '../models/vendor_models.dart';

class DashboardViewModel extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  bool _isLoading = false;
  DashboardStats? _stats;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  DashboardStats? get stats => _stats;
  String? get errorMessage => _errorMessage;

  Future<void> fetchDashboardStats() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.get(AppConstants.vendorDashboardUrl);
      if (response.statusCode == 200) {
        _stats = DashboardStats.fromJson(response.data);
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
