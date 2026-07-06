import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import '../models/driver_model.dart';
import '../models/ride_model.dart';
import '../models/payment_model.dart';
import '../models/ride_type.dart';
import '../models/place_details_model.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';

class BookingProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final SocketService _socketService = SocketService();

  RideModel? _currentRide;
  List<RideModel> _pendingRides = []; // For pending rides (in activity)
  List<RideModel> _rideHistory = []; // For completed/canceled rides
  List<PaymentModel> _userPayments = [];
  List<DriverModel> _nearbyDrivers = [];
  bool _isLoading = false;
  String? _error;
  RideType? _selectedRideType;
  PaymentMethod? _selectedPaymentMethod;
  PlaceDetails? _pickupLocation;
  PlaceDetails? _dropLocation;
  double _distance = 0.0; // in km
  int _estimatedTime = 0; // in minutes
  List<LatLng> _polylinePoints = [];
  String _encodedPolyline = ''; // Store the encoded polyline string
  String _distanceText = '';
  String _durationText = '';
  String? _lastRouteKey;

  RideModel? get currentRide => _currentRide;
  List<RideModel> get pendingRides => _pendingRides;
  List<RideModel> get rideHistory => _rideHistory;
  List<PaymentModel> get userPayments => _userPayments;
  List<DriverModel> get nearbyDrivers => _nearbyDrivers;
  bool get isLoading => _isLoading;
  String? get error => _error;
  RideType? get selectedRideType => _selectedRideType;
  PaymentMethod? get selectedPaymentMethod => _selectedPaymentMethod;
  PlaceDetails? get pickupLocation => _pickupLocation;
  PlaceDetails? get dropLocation => _dropLocation;
  double get distance => _distance;
  int get estimatedTime => _estimatedTime;
  List<LatLng> get polylinePoints => _polylinePoints;
  String get distanceText => _distanceText;
  String get durationText => _durationText;

  BookingProvider() {
    // Listen to ride status stream
    _socketService.rideStatusStream.listen((data) {
      final targetId = data['rideId'] ?? data['id'] ?? data['_id'];
      if (_currentRide != null && targetId == _currentRide!.id) {
        _currentRide = RideModel.fromMap({..._currentRide!.toMap(), ...data});
        notifyListeners();
      }
    });

    // Listen to driver location stream
    _socketService.driverLocationStream.listen((data) {
      if (_currentRide != null) {
        // Update driver location in current ride
        _currentRide = RideModel.fromMap({
          ..._currentRide!.toMap(),
          'driverLatitude': data['latitude'],
          'driverLongitude': data['longitude'],
        });
        notifyListeners();
      }
    });

    // Listen to ride created stream
    _socketService.rideCreatedStream.listen((ride) {
      // Check if ride already exists
      final existingIndex = _rideHistory.indexWhere((r) => r.id == ride.id);
      if (existingIndex == -1) {
        // Insert at beginning to keep newest first
        _rideHistory.insert(0, ride);
        notifyListeners();
      }
    });

    // Listen to ride updated stream
    _socketService.rideUpdatedStream.listen((ride) {
      // Check if ride is completed or canceled
      final status = ride.status.toLowerCase();
      if (status == 'completed' ||
          status == 'canceled' ||
          status == 'cancelled') {
        // Move to history
        moveToHistory(ride);
      } else {
        // Find and replace existing ride in pending
        final pendingIndex = _pendingRides.indexWhere((r) => r.id == ride.id);
        if (pendingIndex != -1) {
          _pendingRides[pendingIndex] = ride;
          notifyListeners();
        } else {
          // If not in pending, add to pending
          addToPendingRides(ride);
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
        final allRides = data.map((e) => RideModel.fromMap(e)).toList();
        // Split into pending and history
        _pendingRides = allRides.where((ride) {
          final status = ride.status.toLowerCase();
          return [
            'searching',
            'pending',
            'accepted',
            'arrived',
            'trip_started',
            'driver_arriving'
          ].contains(status);
        }).toList();
        _rideHistory = allRides.where((ride) {
          final status = ride.status.toLowerCase();
          return ['completed', 'cancelled', 'canceled'].contains(status);
        }).toList();
      } else {
        // If not success but no error, just set to empty list
        if (response.statusCode == 200 || response.statusCode == 304) {
          _pendingRides = [];
          _rideHistory = [];
        } else {
          _error = response.data?['message']?.toString() ??
              'Failed to fetch ride history';
        }
      }
    } catch (e) {
      _error = e.toString();
      _pendingRides = [];
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
      // Add the polyline to the ride data if we have it
      if (_encodedPolyline.isNotEmpty) {
        rideData['polyline'] = _encodedPolyline;
      }

      final response = await _apiService.bookRide(rideData);
      if (response.statusCode == 201) {
        _currentRide = RideModel.fromMap(response.data['data']['ride']);
        addToPendingRides(_currentRide!);
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

  // Add ride to pending list
  void addToPendingRides(RideModel ride) {
    // Check if already exists
    final existingIndex = _pendingRides.indexWhere((r) => r.id == ride.id);
    if (existingIndex == -1) {
      _pendingRides.insert(0, ride);
      notifyListeners();
    }
  }

  // Move ride to history
  void moveToHistory(RideModel ride) {
    // Remove from pending
    _pendingRides.removeWhere((r) => r.id == ride.id);
    // Add to history if not already there
    final existingIndex = _rideHistory.indexWhere((r) => r.id == ride.id);
    if (existingIndex == -1) {
      _rideHistory.insert(0, ride);
    }
    notifyListeners();
  }

  Future<void> cancelRide(String rideId, String reason) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.cancelRide(rideId, reason);
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Find the ride in pending and move to history
        final rideToCancel = _pendingRides.firstWhere((r) => r.id == rideId,
            orElse: () => _rideHistory.firstWhere((r) => r.id == rideId,
                orElse: () => throw Exception('Ride not found')));
        // Update ride status to canceled
        final canceledRide =
            RideModel.fromMap({...rideToCancel.toMap(), 'status': 'canceled'});
        moveToHistory(canceledRide);
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

  void setPickupLocation(PlaceDetails location) {
    _pickupLocation = location;
    notifyListeners();
    if (_dropLocation != null) {
      calculateRoute();
    }
  }

  void setDropLocation(PlaceDetails location) {
    _dropLocation = location;
    notifyListeners();
    if (_pickupLocation != null) {
      calculateRoute();
    }
  }

  Future<void> calculateRoute({int attempt = 1}) async {
    if (_pickupLocation == null || _dropLocation == null) return;

    final routeKey =
        '${_pickupLocation!.latitude.toStringAsFixed(5)},${_pickupLocation!.longitude.toStringAsFixed(5)}_${_dropLocation!.latitude.toStringAsFixed(5)},${_dropLocation!.longitude.toStringAsFixed(5)}';

    // Perform caching: if coordinates haven't changed and we have a route, reuse it.
    if (_lastRouteKey == routeKey && _polylinePoints.isNotEmpty) {
      return;
    }

    _isLoading = true;
    _error = null;
    if (attempt == 1) {
      notifyListeners();
    }

    try {
      final response = await _apiService.getDirections(
        _pickupLocation!.latitude,
        _pickupLocation!.longitude,
        _dropLocation!.latitude,
        _dropLocation!.longitude,
      );

      if (response.statusCode == 200 && response.data != null) {
        final responseData = response.data;
        Map<String, dynamic>? data;
        if (responseData['data'] != null) {
          data = responseData['data'];
        } else if (responseData['success'] == true ||
            responseData['status'] == 'success') {
          data = responseData;
        } else {
          data = responseData;
        }

        final distanceValue = data?['distanceValue'];
        if (distanceValue is int) {
          _distance = distanceValue.toDouble();
        } else if (distanceValue is double) {
          _distance = distanceValue;
        } else {
          _distance = 0.0;
        }

        final durationValue = data?['durationValue'];
        if (durationValue is int) {
          _estimatedTime = durationValue;
        } else if (durationValue is double) {
          _estimatedTime = durationValue.toInt();
        } else {
          _estimatedTime = 0;
        }

        final dist = data?['distance'];
        _distanceText = dist != null ? dist.toString() : '';

        final dur = data?['duration'];
        _durationText = dur != null ? dur.toString() : '';

        final encodedPolyline = data?['polyline'];
        _encodedPolyline = encodedPolyline?.toString() ?? '';
        if (encodedPolyline != null && encodedPolyline.toString().isNotEmpty) {
          final polylinePoints =
              PolylinePoints().decodePolyline(encodedPolyline.toString());
          _polylinePoints = polylinePoints
              .map((point) => LatLng(point.latitude, point.longitude))
              .toList();
        } else {
          _polylinePoints = [];
        }

        _lastRouteKey = routeKey;
      } else {
        throw Exception(response.data?['message']?.toString() ??
            'Failed to fetch directions');
      }
    } catch (e) {
      if (attempt < 3) {
        // Retry with a 2-second delay
        await Future.delayed(const Duration(seconds: 2));
        return calculateRoute(attempt: attempt + 1);
      }
      _error = e.toString();
      _polylinePoints = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // New method to calculate route between driver and pickup
  Future<void> calculateDriverToPickupRoute({
    required double driverLat,
    required double driverLng,
    required double pickupLat,
    required double pickupLng,
    int attempt = 1,
  }) async {
    final routeKey =
        '${driverLat.toStringAsFixed(5)},${driverLng.toStringAsFixed(5)}_${pickupLat.toStringAsFixed(5)},${pickupLng.toStringAsFixed(5)}';

    if (_lastRouteKey == routeKey && _polylinePoints.isNotEmpty) {
      return;
    }

    _isLoading = true;
    _error = null;
    if (attempt == 1) {
      notifyListeners();
    }

    try {
      final response = await _apiService.getDirections(
        driverLat,
        driverLng,
        pickupLat,
        pickupLng,
      );

      if (response.statusCode == 200 && response.data != null) {
        final responseData = response.data;
        Map<String, dynamic>? data;
        if (responseData['data'] != null) {
          data = responseData['data'];
        } else if (responseData['success'] == true ||
            responseData['status'] == 'success') {
          data = responseData;
        } else {
          data = responseData;
        }

        final distanceValue = data?['distanceValue'];
        if (distanceValue is int) {
          _distance = distanceValue.toDouble();
        } else if (distanceValue is double) {
          _distance = distanceValue;
        } else {
          _distance = 0.0;
        }

        final durationValue = data?['durationValue'];
        if (durationValue is int) {
          _estimatedTime = durationValue;
        } else if (durationValue is double) {
          _estimatedTime = durationValue.toInt();
        } else {
          _estimatedTime = 0;
        }

        final dist = data?['distance'];
        _distanceText = dist != null ? dist.toString() : '';

        final dur = data?['duration'];
        _durationText = dur != null ? dur.toString() : '';

        final encodedPolyline = data?['polyline'];
        _encodedPolyline = encodedPolyline?.toString() ?? '';
        if (encodedPolyline != null && encodedPolyline.toString().isNotEmpty) {
          final polylinePoints =
              PolylinePoints().decodePolyline(encodedPolyline.toString());
          _polylinePoints = polylinePoints
              .map((point) => LatLng(point.latitude, point.longitude))
              .toList();
        } else {
          _polylinePoints = [];
        }

        _lastRouteKey = routeKey;
      } else {
        throw Exception(response.data?['message']?.toString() ??
            'Failed to fetch directions');
      }
    } catch (e) {
      if (attempt < 3) {
        await Future.delayed(const Duration(seconds: 2));
        return calculateDriverToPickupRoute(
          driverLat: driverLat,
          driverLng: driverLng,
          pickupLat: pickupLat,
          pickupLng: pickupLng,
          attempt: attempt + 1,
        );
      }
      _error = e.toString();
      _polylinePoints = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void resetBooking() {
    _pickupLocation = null;
    _dropLocation = null;
    _selectedRideType = null;
    _distance = 0.0;
    _estimatedTime = 0;
    _polylinePoints = [];
    _encodedPolyline = '';
    _distanceText = '';
    _durationText = '';
    _lastRouteKey = null;
    notifyListeners();
  }
}
