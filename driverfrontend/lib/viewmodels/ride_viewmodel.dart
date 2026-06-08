import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import '../models/driver_models.dart';
import '../services/socket_service.dart';
import '../services/api_service.dart';
import '../core/constants/app_constants.dart';
import '../views/rides/trip_navigation_screen.dart';

class RideViewModel extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final SocketService _socketService = SocketService();
  StreamSubscription<Map<String, dynamic>>? _rideRequestSubscription;

  RideRequestModel? _incomingRequest;
  bool _isOnline = false;
  bool _isLoading = false;
  StreamSubscription<Position>? _positionStream;
  final List<RideRequestModel> _nearbyRides = [];
  List<RideRequestModel> _rideHistory = [];
  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  String? _error;
  String? _driverId;

  RideRequestModel? get incomingRequest => _incomingRequest;
  bool get isOnline => _isOnline;
  bool get isLoading => _isLoading;
  List<RideRequestModel> get nearbyRides => _nearbyRides;
  List<RideRequestModel> get rideHistory => _rideHistory;
  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  String? get error => _error;

  void initialize(String driverId) {
    _driverId = driverId;
    _socketService.connect(driverId);

    _rideRequestSubscription = _socketService.rideRequestStream.listen((data) {
      _incomingRequest = RideRequestModel.fromJson(data);
      notifyListeners();
    });
  }

  void toggleOnlineOffline() async {
    _isOnline = !_isOnline;

    if (_isOnline) {
      _startLocationUpdates();
    } else {
      _stopLocationUpdates();
    }

    notifyListeners();
  }

  void _startLocationUpdates() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    _positionStream =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 10,
          ),
        ).listen((Position position) {
          if (_isOnline) {
            _updateLocationOnServer(position);
          }
        });
  }

  void _stopLocationUpdates() {
    _positionStream?.cancel();
    _positionStream = null;
  }

  Future<void> _updateLocationOnServer(Position position) async {
    try {
      await _apiService.post(
        AppConstants.updateLocationUrl,
        data: {'latitude': position.latitude, 'longitude': position.longitude},
      );

      if (_driverId != null) {
        _socketService.emit('updateLocation', {
          'driverId': _driverId,
          'lat': position.latitude,
          'lng': position.longitude,
        });
      }
    } catch (e) {
      debugPrint('Location Update Error: $e');
    }
  }

  Future<void> acceptRide(BuildContext context, String rideId) async {
    _isLoading = true;
    notifyListeners();
    try {
      if (_driverId != null) {
        _socketService.emit('acceptRide', {
          'rideId': rideId,
          'driverId': _driverId,
        });
      }

      _incomingRequest = null;
      notifyListeners();

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const TripNavigationScreen(isToPickup: true),
        ),
      );
    } catch (e) {
      debugPrint('Accept Ride Error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void rejectRide() {
    _incomingRequest = null;
    notifyListeners();
  }

  Future<void> fetchRideHistory() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.get(AppConstants.driverRidesUrl);

      if (response.data['success'] == true) {
        final List<dynamic>? ridesData = response.data['data']?['rides'];
        _rideHistory = ridesData != null
            ? ridesData.map((ride) => RideRequestModel.fromJson(ride)).toList()
            : [];
      } else {
        _error = response.data['message'] ?? 'Failed to load rides';
      }
      notifyListeners();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchNotifications() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.get(AppConstants.notificationsUrl);
      if (response.data['success'] == true) {
        final List<dynamic>? notificationsData =
            response.data['data']?['notifications'];
        _notifications = notificationsData != null
            ? notificationsData
                  .map((n) => NotificationModel.fromJson(n))
                  .toList()
            : [];
        _unreadCount = response.data['data']?['unreadCount'] ?? 0;
      }
      notifyListeners();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _apiService.put(
        AppConstants.markNotificationReadUrl.replaceFirst(
          ':id',
          notificationId,
        ),
      );
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = NotificationModel(
          id: _notifications[index].id,
          title: _notifications[index].title,
          message: _notifications[index].message,
          type: _notifications[index].type,
          isRead: true,
          data: _notifications[index].data,
          createdAt: _notifications[index].createdAt,
        );
        if (_unreadCount > 0) {
          _unreadCount--;
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Mark as Read Error: $e');
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _apiService.put(AppConstants.markAllNotificationsReadUrl);
      _notifications = _notifications
          .map(
            (n) => NotificationModel(
              id: n.id,
              title: n.title,
              message: n.message,
              type: n.type,
              isRead: true,
              data: n.data,
              createdAt: n.createdAt,
            ),
          )
          .toList();
      _unreadCount = 0;
      notifyListeners();
    } catch (e) {
      debugPrint('Mark All Read Error: $e');
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      await _apiService.delete(
        AppConstants.deleteNotificationUrl.replaceFirst(':id', notificationId),
      );
      _notifications.removeWhere((n) => n.id == notificationId);
      notifyListeners();
    } catch (e) {
      debugPrint('Delete Notification Error: $e');
    }
  }

  @override
  void dispose() {
    _stopLocationUpdates();
    _rideRequestSubscription?.cancel();
    super.dispose();
  }
}
