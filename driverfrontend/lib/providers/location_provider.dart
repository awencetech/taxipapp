import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:uuid/uuid.dart';
import 'dart:async';
import '../services/google_maps_service.dart';

class LocationProvider extends ChangeNotifier {
  final GoogleMapsService _mapsService = GoogleMapsService();
  final _uuid = const Uuid();
  String? _sessionToken;

  Position? _currentPosition;
  bool _isLoading = false;
  String? _error;
  StreamSubscription<Position>? _positionStream;
  String _currentAddress = '';

  List<dynamic> _suggestions = [];
  bool _isSearching = false;
  Timer? _debounce;

  bool _isFetchingLocation = false;
  bool _locationInitialized = false;
  Position? get currentPosition => _currentPosition;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<dynamic> get suggestions => _suggestions;
  bool get isSearching => _isSearching;
  bool get isFetchingLocation => _isFetchingLocation;
  String get currentAddress => _currentAddress;
  bool get locationInitialized => _locationInitialized;
  LocationProvider() {
    _sessionToken = _uuid.v4();
    _initLocation();
  }

  void onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      searchPlaces(query);
    });
  }

  Future<bool> checkLocationPermission() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _error = 'Location services are disabled. Please enable GPS.';
        notifyListeners();
        return false;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _error = 'Location permission denied';
          notifyListeners();
          return false;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        _error =
            'Location permission permanently denied. Please enable in settings.';
        notifyListeners();
        return false;
      }
      return true;
    } catch (e) {
      _error = 'Error checking location permission: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  Future<LatLng?> getCurrentLocation() async {
    _isFetchingLocation = true;
    _error = null;
    notifyListeners();

    try {
      final hasPermission = await checkLocationPermission();
      if (kDebugMode) {
        print(
          '[Location] Permission status: ${hasPermission ? 'granted' : 'denied'}',
        );
      }

      if (!hasPermission) {
        await _useDefaultLocation();
        _isFetchingLocation = false;
        notifyListeners();
        return null;
      }

      Position? bestPosition;

      // Web-optimized settings
      final isWeb = kIsWeb;
      final accuracy = isWeb
          ? LocationAccuracy.medium
          : LocationAccuracy.bestForNavigation;
      final timeout = isWeb
          ? const Duration(seconds: 30)
          : const Duration(seconds: 10);
      final acceptableAccuracy = isWeb
          ? 5000.0
          : 100.0; // 5km for Web, 100m for mobile
      final maxRetries = isWeb ? 1 : 3;
      int retryCount = 0;

      while (retryCount < maxRetries) {
        retryCount++;
        if (kDebugMode) {
          print(
            '[Location] Attempt $retryCount/$maxRetries to fetch location (Web: $isWeb)',
          );
        }

        try {
          _currentPosition = await Geolocator.getCurrentPosition(
            desiredAccuracy: accuracy,
            timeLimit: timeout,
          );

          if (_currentPosition != null) {
            if (kDebugMode) {
              print('[Location] Raw position received:');
              print('  Latitude: ${_currentPosition!.latitude}');
              print('  Longitude: ${_currentPosition!.longitude}');
              print('  Accuracy: ${_currentPosition!.accuracy}m');
              print('  Timestamp: ${_currentPosition!.timestamp}');
            }

            // Check accuracy - more lenient on Web
            if (_currentPosition!.accuracy <= acceptableAccuracy) {
              bestPosition = _currentPosition;
              if (kDebugMode) {
                print(
                  '[Location] Accuracy is acceptable (<=${acceptableAccuracy}m), using this position',
                );
              }
              break;
            } else {
              if (kDebugMode) {
                print(
                  '[Location] Accuracy is less than ideal (${_currentPosition!.accuracy}m), but using it anyway on Web',
                );
              }
              bestPosition = _currentPosition;
              break; // Use whatever we get on Web
            }
          }
        } catch (e) {
          if (kDebugMode) {
            print('[Location] Attempt $retryCount failed: $e');
          }
          if (retryCount == maxRetries) {
            break; // Don't rethrow on Web - just use last known or default
          }
        }
      }

      // If we didn't get a position, try last known
      if (bestPosition == null) {
        if (kDebugMode) {
          print('[Location] Trying last known position');
        }
        try {
          bestPosition = await Geolocator.getLastKnownPosition();
          if (bestPosition != null) {
            if (kDebugMode) {
              print('[Location] Last known position found:');
              print('  Latitude: ${bestPosition.latitude}');
              print('  Longitude: ${bestPosition.longitude}');
            }
          }
        } catch (e) {
          if (kDebugMode) {
            print('[Location] Last known position not available: $e');
          }
        }
      }

      _currentPosition = bestPosition;

      if (_currentPosition != null) {
        await _reverseGeocode(
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        );
        _locationInitialized = true;
        if (kDebugMode) {
          print('[Location] Final position:');
          print('  Latitude: ${_currentPosition!.latitude}');
          print('  Longitude: ${_currentPosition!.longitude}');
          print('  Accuracy: ${_currentPosition!.accuracy}m');
          print('  Address: $_currentAddress');
        }
      } else {
        await _useDefaultLocation();
      }

      _isFetchingLocation = false;
      notifyListeners();
      return _currentPosition != null
          ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
          : null;
    } catch (e) {
      if (kDebugMode) {
        print('[Location] Error fetching location: $e');
      }
      await _useDefaultLocation();
      _error = 'Failed to get current location: ${e.toString()}';
      _isFetchingLocation = false;
      notifyListeners();
      return null;
    }
  }

  Future<void> _reverseGeocode(LatLng coords) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        coords.latitude,
        coords.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        List<String> addressParts = [];

        if (place.street != null && place.street!.isNotEmpty) {
          addressParts.add(place.street!);
        }
        if (place.subLocality != null && place.subLocality!.isNotEmpty) {
          addressParts.add(place.subLocality!);
        }
        if (place.locality != null && place.locality!.isNotEmpty) {
          addressParts.add(place.locality!);
        }
        if (place.subAdministrativeArea != null &&
            place.subAdministrativeArea!.isNotEmpty) {
          addressParts.add(place.subAdministrativeArea!);
        }
        if (place.administrativeArea != null &&
            place.administrativeArea!.isNotEmpty) {
          addressParts.add(place.administrativeArea!);
        }

        _currentAddress = addressParts.join(', ');
        if (_currentAddress.isEmpty) {
          _currentAddress =
              '${coords.latitude.toStringAsFixed(6)}, ${coords.longitude.toStringAsFixed(6)}';
        }
      }
    } catch (e) {
      _currentAddress =
          '${coords.latitude.toStringAsFixed(6)}, ${coords.longitude.toStringAsFixed(6)}';
    }
    notifyListeners();
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
      _sessionToken = _uuid.v4();
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

  void clearError() {
    _error = null;
    notifyListeners();
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
    _isLoading = true;
    bool serviceEnabled;
    LocationPermission permission;

    notifyListeners();

    try {
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _error = 'Location services are disabled.';
        _isLoading = false;
        notifyListeners();
        return;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _error = 'Location permissions are denied';
          _isLoading = false;
          notifyListeners();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _error = 'Location permissions are permanently denied';
        _isLoading = false;
        notifyListeners();
        return;
      }

      _currentPosition = await Geolocator.getCurrentPosition();
      _isLoading = false;
      notifyListeners();

      _positionStream =
          Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: 10,
            ),
          ).listen((Position position) {
            _currentPosition = position;
            notifyListeners();
          });
    } catch (e) {
      _error = 'Error initializing location: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _useDefaultLocation() async {
    const defaultLat = 11.0168; // Coimbatore latitude
    const defaultLng = 76.9558; // Coimbatore longitude
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
    _currentAddress = 'Coimbatore, Tamil Nadu';
    _locationInitialized = true;
    notifyListeners();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _debounce?.cancel();
    super.dispose();
  }
}
