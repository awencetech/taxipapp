import 'package:flutter/material.dart';
import '../models/driver_model.dart';
import '../models/ride_model.dart';
import '../models/payment_model.dart';
import '../models/ride_type.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';

class BookingProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final SocketService _socketService = SocketService();

  RideModel? _currentRide;
  List<RideModel> _rideHistory = [];
  List<PaymentModel> _userPayments = [];
  List<DriverModel> _nearbyDrivers = [];
  bool _isLoading = false;
  String? _error;
  RideType? _selectedRideType;
  PaymentMethod? _selectedPaymentMethod;

  RideModel? get currentRide => _currentRide;
  List<RideModel> get rideHistory => _rideHistory;
  List<PaymentModel> get userPayments => _userPayments;
  List<DriverModel> get nearbyDrivers => _nearbyDrivers;
  bool get isLoading => _isLoading;
  String? get error => _error;
  RideType? get selectedRideType => _selectedRideType;
  PaymentMethod? get selectedPaymentMethod => _selectedPaymentMethod;

  BookingProvider() {
    // Only listen to ride status stream, and only notify if current ride changes
    _socketService.rideStatusStream.listen((data) {
      if (_currentRide != null && data['rideId'] == _currentRide!.id) {
        final newStatus = data['status'];
        if (_currentRide!.status != newStatus) {
          _currentRide = RideModel.fromMap(
              {..._currentRide!.toMap(), 'status': newStatus});
          notifyListeners();
        }
      }
    });
  }

  Future<void> fetchRideHistory() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.getRideHistory();
      // Handle both response formats
      bool isSuccess = false;
      List<dynamic>? data;

      if (response.statusCode == 200 || response.statusCode == 304) {
        if (response.data != null) {
          if (response.data['status'] == 'success') {
            isSuccess = true;
            data = response.data['data']?['rides'] ?? response.data['rides'];
          } else if (response.data['success'] == true) {
            isSuccess = true;
            data = response.data['data']?['rides'] ?? response.data['rides'];
          }
        }
      }

      if (isSuccess && data != null) {
        _rideHistory = data.map((e) => RideModel.fromMap(e)).toList();
      } else {
        // If not success but no error, just set to empty list
        if (response.statusCode == 200 || response.statusCode == 304) {
          _rideHistory = [];
        } else {
          _error = response.data?['message']?.toString() ??
              'Failed to fetch ride history';
        }
      }
    } catch (e) {
      _error = e.toString();
      _rideHistory = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchUserPayments() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.getUserPayments();
      if (response.statusCode == 200 && response.data['success'] == true) {
        final List data = response.data['data']['payments'];
        _userPayments = data.map((e) => PaymentModel.fromMap(e)).toList();
      } else {
        _error = response.data['message'] ?? 'Failed to fetch payments';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> findDrivers() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.getNearbyDrivers();
      if (response.statusCode == 200) {
        List data = response.data['data']['drivers'];
        _nearbyDrivers = data.map((d) => DriverModel.fromMap(d)).toList();
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> requestRide(Map<String, dynamic> rideData) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.bookRide(rideData);
      if (response.statusCode == 201) {
        _currentRide = RideModel.fromMap(response.data['data']['ride']);
        _isLoading = false;
        notifyListeners();
        return true;
      }
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> cancelRide(String rideId, String reason) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.cancelRide(rideId, reason);
      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchRideHistory();
      } else {
        _error = response.data['message'] ?? 'Failed to cancel ride';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectRideType(RideType rideType) {
    _selectedRideType = rideType;
    notifyListeners();
  }

  void selectPaymentMethod(PaymentMethod paymentMethod) {
    _selectedPaymentMethod = paymentMethod;
    notifyListeners();
  }
}
