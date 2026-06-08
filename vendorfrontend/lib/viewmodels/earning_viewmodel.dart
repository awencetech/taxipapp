import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../core/constants/app_constants.dart';
import '../models/vendor_models.dart';

class EarningViewModel extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  bool _isLoading = false;
  Earnings? _earnings;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  Earnings? get earnings => _earnings;
  String? get errorMessage => _errorMessage;

  Future<void> fetchEarnings() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.get(AppConstants.vendorEarningsUrl);
      if (response.statusCode == 200) {
        _earnings = Earnings.fromJson(response.data);
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
