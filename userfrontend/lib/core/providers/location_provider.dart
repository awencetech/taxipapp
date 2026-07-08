
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:uuid/uuid.dart';
import 'dart:async';
import '../services/google_maps_service.dart';
import '../services/api_service.dart';

class LocationProvider extends ChangeNotifier {
  final GoogleMapsService _mapsService = GoogleMapsService();
  final ApiService _apiService = ApiService();
  final _uuid = const Uuid();
  String? _sessionToken;

  Position? _currentPosition;
  bool _isLoading = false;
  String? _error;
  StreamSubscription<Position>? _positionStream;
  String _currentAddress = '';
  bool _isFetchingLocation = false;
  bool _autoFollow = true;
  bool _isUpdating = false;
  bool _hasPermissions = false;
  bool _permanentlyDenied = false;
  Timer? _locationUpdateTimer;

  // Search related
  List<dynamic> _suggestions = [];
  bool _isSearching = false;
  Timer? _debounce;

  Position? get currentPosition => _currentPosition;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<dynamic> get suggestions => _suggestions;
  bool get isSearching => _isSearching;
  bool get isFetchingLocation => _isFetchingLocation;
  String get currentAddress => _currentAddress;
  bool get autoFollow => _autoFollow;
  bool get isUpdating => _isUpdating;
  bool get hasPermissions => _hasPermissions;
  bool get permanentlyDenied => _permanentlyDenied;

  LocationProvider() {
    _sessionToken = _uuid.v4();
    _initLocation();
  }

  void setAutoFollow(bool value) {
    _autoFollow = value;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<bool> checkAndRequestPermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _error = 'Location services are disabled. Please enable GPS.';
      _hasPermissions = false;
      notifyListeners();
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _error = 'Location permission is required.';
        _hasPermissions = false;
        _permanentlyDenied = false;
        notifyListeners();
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _error =
          'Location permission is permanently denied. Open settings to enable.';
      _hasPermissions = false;
      _permanentlyDenied = true;
      notifyListeners();
      return false;
    }

    _hasPermissions = true;
    _permanentlyDenied = false;
    _error = null;
    notifyListeners();
    return true;
  }

  Future<LatLng?> getCurrentLocation() async {
    _isFetchingLocation = true;
    _error = null;
    notifyListeners();

    try {
      final hasPermission = await checkAndRequestPermissions();

      if (!hasPermission) {
        await _useDefaultLocation();
        _isFetchingLocation = false;
        notifyListeners();
        return const LatLng(11.0168, 76.9558);
      }

      Position? bestPosition;

      // Better location settings for live location
      const isWeb = kIsWeb;
      const accuracy =
          isWeb ? LocationAccuracy.medium : LocationAccuracy.bestForNavigation;
      const timeout = isWeb ? Duration(seconds: 15) : Duration(seconds: 30);
      const maxRetries = 3;
      int retryCount = 0;

      // Try last known position first for quick initial display
      try {
        bestPosition = await Geolocator.getLastKnownPosition();
        if (bestPosition != null) {
          _currentPosition = bestPosition;
          notifyListeners(); // Update UI quickly with last known
          if (kDebugMode) {
            print('Using last known position initially: ${bestPosition.latitude}, ${bestPosition.longitude}');
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error getting last known position: $e');
        }
      }

      // Then fetch fresh position
      while (retryCount < maxRetries) {
        retryCount++;
        try {
          final position = await Geolocator.getCurrentPosition(
            desiredAccuracy: accuracy,
            timeLimit: timeout,
          );

          if (kDebugMode) {
            print('Fetched fresh position: ${position.latitude}, ${position.longitude}, accuracy: ${position.accuracy}m');
          }

          bestPosition = position;
          _currentPosition = bestPosition;
          notifyListeners(); // Update UI with fresh position
          break;
        } catch (e) {
          if (kDebugMode) {
            print('Error fetching position (attempt $retryCount): $e');
          }
          if (retryCount == maxRetries) break;
          await Future.delayed(const Duration(seconds: 2));
        }
      }

      if (_currentPosition != null) {
        if (kDebugMode) {
          print('Final position: ${_currentPosition!.latitude}, ${_currentPosition!.longitude}');
        }
        // Reverse geocode to get address
        await _reverseGeocode(
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        );
        // Start continuous updates
        await _startContinuousUpdates();
      } else {
        if (kDebugMode) {
          print('No position found, using default');
        }
        await _useDefaultLocation();
      }

      _isFetchingLocation = false;
      notifyListeners();
      return _currentPosition != null
          ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
          : null;
    } catch (e) {
      if (kDebugMode) {
        print('Error in getCurrentLocation: $e');
      }
      await _useDefaultLocation();
      _error = 'Unable to fetch current location. Please enable GPS.';
      _isFetchingLocation = false;
      notifyListeners();
      return const LatLng(11.0168, 76.9558);
    }
  }

  Future<void> _useDefaultLocation() async {
    const defaultLat = 11.0168;
    const defaultLng = 76.9558;
    _currentPosition = Position(
      latitude: defaultLat,
      longitude: defaultLng,
      timestamp: DateTime.now(),
      accuracy: 0.0,
      altitude: 0.0,
      altitudeAccuracy: 0.0,
      heading: 0.0,
      headingAccuracy: 0.0,
      speed: 0.0,
      speedAccuracy: 0.0,
    );
    _currentAddress = '';
    notifyListeners();
  }

  Future<void> _startContinuousUpdates() async {
    // Cancel existing stream
    await _positionStream?.cancel();
    _locationUpdateTimer?.cancel();

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 10,
    );

    _positionStream =
        Geolocator.getPositionStream(locationSettings: locationSettings)
            .listen((Position position) {
      _currentPosition = position;
      _isUpdating = true;
      notifyListeners();

      // Send to backend every 5 seconds at max
      _locationUpdateTimer ??= Timer(const Duration(seconds: 5), () {
        _sendLocationToBackend();
        _locationUpdateTimer = null;
      });
    });
  }

  Future<void> _sendLocationToBackend() async {
    if (_currentPosition == null) return;

    try {
      await _apiService.updateUserLocation({
        'latitude': _currentPosition!.latitude,
        'longitude': _currentPosition!.longitude,
      });
    } catch (e) {
      // Ignore backend errors for location updates
      if (kDebugMode) {
        print('Failed to send location to backend: $e');
      }
    }
  }

  Future<void> _reverseGeocode(LatLng coords) async {
    try {
      final address =
          await _mapsService.reverseGeocode(coords.latitude, coords.longitude);
      _currentAddress = address;
    } catch (e) {
      _currentAddress = 'Current Location';
    }
    notifyListeners();
  }

  Future<String> getAddressFromLatLng(double lat, double lng) async {
    try {
      return await _mapsService.reverseGeocode(lat, lng);
    } catch (e) {
      return 'Unknown Location';
    }
  }

  void onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      searchPlaces(query);
    });
  }

  Future<void> searchPlaces(String query) async {
    if (query.isEmpty) {
      _suggestions = [];
      _error = null;
      notifyListeners();
      return;
    }

    _isSearching = true;
    _error = null;
    notifyListeners();

    try {
      _suggestions = await _mapsService.getAutocomplete(query, _sessionToken!);
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _suggestions = [];
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  Future<LatLng?> getPlaceCoords(String placeId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final coords = await _mapsService.getPlaceDetails(placeId);
      _sessionToken = _uuid.v4(); // Reset session token after a final selection
      _suggestions = [];
      _isLoading = false;
      notifyListeners();
      return coords;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  void clearSuggestions() {
    _suggestions = [];
    notifyListeners();
  }

  void clearCurrentAddress() {
    _currentAddress = '';
    notifyListeners();
  }

  Future<void> _initLocation() async {
    // Don't do anything heavy here - let getCurrentLocation handle it
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _locationUpdateTimer?.cancel();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> openAppSettings() async {
    await Geolocator.openAppSettings();
  }
}
