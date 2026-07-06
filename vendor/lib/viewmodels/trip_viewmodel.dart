import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../core/constants/app_constants.dart';
import '../models/vendor_models.dart';

class TripViewModel extends ChangeNotifier {
  final ApiService _apiService;

  bool _isLoading = false;
  bool _isFetching = false;
  List<Trip> _trips = [];
  String? _errorMessage;

  TripViewModel({required ApiService apiService}) : _apiService = apiService;

  bool get isLoading => _isLoading;
  List<Trip> get trips => _trips;
  String? get errorMessage => _errorMessage;

  Future<void> fetchTrips() async {
    if (_isFetching) return;

    _isFetching = true;
    _isLoading = _trips.isEmpty;
    _errorMessage = null;
    if (_isLoading) notifyListeners();

    try {
      final response = await _apiService.get(AppConstants.vendorTripsUrl);
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        _trips = data.map((json) => Trip.fromJson(json)).toList();
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
