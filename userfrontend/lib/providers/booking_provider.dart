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
    _socketService.driverLocationStream.listen((data) {
      // Update local driver positions if needed
      notifyListeners();
    });

    _socketService.rideStatusStream.listen((data) {
      if (_currentRide != null && data['rideId'] == _currentRide!.id) {
        _currentRide = RideModel.fromMap(
            {..._currentRide!.toMap(), 'status': data['status']});
        notifyListeners();
      }
    });
  }

  Future<void> fetchRideHistory() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.getRideHistory();
      if (response.statusCode == 200 && response.data['status'] == 'success') {
        final List data = response.data['data']['rides'];
        _rideHistory = data.map((e) => RideModel.fromMap(e)).toList();
      } else {
        _error = response.data['message'] ?? 'Failed to fetch ride history';
      }
    } catch (e) {
      _error = e.toString();
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

  void cancelRide() {
    _currentRide = null;
    _selectedRideType = null;
    _selectedPaymentMethod = null;
    notifyListeners();
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
