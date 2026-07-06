import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../core/constants/app_constants.dart';
import '../models/vendor_models.dart';

class EarningViewModel extends ChangeNotifier {
  final ApiService _apiService;

  bool _isLoading = false;
  bool _isFetching = false;
  Earnings? _earnings;
  String? _errorMessage;

  EarningViewModel({required ApiService apiService}) : _apiService = apiService;

  bool get isLoading => _isLoading;
  Earnings? get earnings => _earnings;
  String? get errorMessage => _errorMessage;

  Future<void> fetchEarnings() async {
    if (_isFetching) return;
    
    _isFetching = true;
    _isLoading = _earnings == null;
    _errorMessage = null;
    if (_isLoading) notifyListeners();

    try {
      final response = await _apiService.get(AppConstants.vendorEarningsUrl);
      if (response.statusCode == 200) {
        _earnings = Earnings.fromJson(response.data);
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
