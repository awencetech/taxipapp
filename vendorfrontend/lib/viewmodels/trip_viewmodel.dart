import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../core/constants/app_constants.dart';
import '../models/vendor_models.dart';

class TripViewModel extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  bool _isLoading = false;
  List<Trip> _trips = [];
  String? _errorMessage;

  bool get isLoading => _isLoading;
  List<Trip> get trips => _trips;
  String? get errorMessage => _errorMessage;

  Future<void> fetchTrips() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.get(AppConstants.vendorTripsUrl);
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        _trips = data.map((json) => Trip.fromJson(json)).toList();
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
