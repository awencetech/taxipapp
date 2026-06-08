import 'package:flutter/material.dart';
import '../models/referral_model.dart';
import '../services/api_service.dart';

class ReferralProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  ReferralModel? _referralData;
  bool _isLoading = false;
  String? _error;

  ReferralModel? get referralData => _referralData;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchReferralData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.getReferralData();
      if (response.data['success'] == true && response.data['data'] != null) {
        _referralData = ReferralModel.fromMap(response.data['data']);
      }
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
