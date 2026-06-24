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
  RideRequestModel? _currentRide;
  bool _isOnline = false;
  bool _isLoading = false;
  int _onlineSeconds = 0;
  Timer? _onlineTimer;
  StreamSubscription<Position>? _positionStream;
  final List<RideRequestModel> _nearbyRides = [];
  List<RideRequestModel> _rideHistory = [];
  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  String? _error;
  String? _driverId;

  RideRequestModel? get incomingRequest => _incomingRequest;
  RideRequestModel? get currentRide => _currentRide;
  bool get isOnline => _isOnline;
  bool get isLoading => _isLoading;
  int get onlineSeconds => _onlineSeconds;

  String get onlineDuration {
    int minutes = _onlineSeconds ~/ 60;
    int seconds = _onlineSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

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
      _startOnlineTimer();
    } else {
      _stopLocationUpdates();
      _stopOnlineTimer();
    }

    notifyListeners();
  }

  void _startOnlineTimer() {
    _onlineSeconds = 0;
    _onlineTimer?.cancel();
    _onlineTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _onlineSeconds++;
      notifyListeners();
    });
  }

  void _stopOnlineTimer() {
    _onlineTimer?.cancel();
    _onlineTimer = null;
    _onlineSeconds = 0;
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
      final response = await _apiService.post(
        AppConstants.driverAcceptRideUrl,
        data: {'rideId': rideId},
      );

      if (response.data['status'] == 'success') {
        _currentRide = RideRequestModel.fromJson(response.data['data']['ride']);
        _incomingRequest = null;
        await fetchRideHistory(); // Refresh ride history to remove from pending
        notifyListeners();

        if (context.mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => TripNavigationScreen(isToPickup: true),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Accept Ride Error: $e');
      _error = e.toString();
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to accept ride: $e')));
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> rejectRide(
    String rideId, {
    String reason = 'Rejected by driver',
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _apiService.post(
        AppConstants.driverRejectRideUrl,
        data: {'rideId': rideId, 'reason': reason},
      );

      _incomingRequest = null;
      await fetchRideHistory(); // Refresh ride history
      notifyListeners();
    } catch (e) {
      debugPrint('Reject Ride Error: $e');
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> arrivedAtPickup() async {
    if (_currentRide == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.post(
        AppConstants.driverArrivedUrl,
        data: {'rideId': _currentRide!.id},
      );

      if (response.data['status'] == 'success') {
        _currentRide = RideRequestModel.fromJson(response.data['data']['ride']);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Arrived Error: $e');
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> startTrip() async {
    if (_currentRide == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.post(
        AppConstants.driverStartTripUrl,
        data: {'rideId': _currentRide!.id},
      );

      if (response.data['status'] == 'success') {
        _currentRide = RideRequestModel.fromJson(response.data['data']['ride']);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Start Trip Error: $e');
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> completeTrip(BuildContext context) async {
    if (_currentRide == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.post(
        AppConstants.driverCompleteTripUrl,
        data: {'rideId': _currentRide!.id},
      );

      if (response.data['status'] == 'success') {
        _currentRide = null;
        await fetchRideHistory();
        notifyListeners();

        if (context.mounted) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      debugPrint('Complete Trip Error: $e');
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchCurrentRide() async {
    try {
      final response = await _apiService.get(AppConstants.driverCurrentRideUrl);
      if (response.data['status'] == 'success' &&
          response.data['data']['ride'] != null) {
        _currentRide = RideRequestModel.fromJson(response.data['data']['ride']);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Fetch Current Ride Error: $e');
    }
  }

  Future<void> fetchRideHistory() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.get(AppConstants.driverHistoryUrl);
      debugPrint('Ride history response: ${response.data}');

      // Handle both response formats
      bool isSuccess = false;
      List<dynamic>? ridesData;

      if (response.data['status'] == 'success') {
        isSuccess = true;
        ridesData = response.data['data']?['rides'];
      } else if (response.data['success'] == true) {
        isSuccess = true;
        ridesData = response.data['data']?['rides'];
      }

      if (isSuccess) {
        _rideHistory = ridesData != null
            ? ridesData.map((ride) => RideRequestModel.fromJson(ride)).toList()
            : [];
      } else {
        _error = response.data['message'] ?? 'Failed to load rides';
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Ride history error: $e');
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

  List<SupportTicketModel> _tickets = [];
  bool _ticketsLoading = false;
  List<SupportTicketModel> get tickets => _tickets;
  bool get ticketsLoading => _ticketsLoading;

  Future<void> fetchTickets() async {
    _ticketsLoading = true;
    _error = null;
    notifyListeners();
    try {
      final response = await _apiService.get(AppConstants.mySupportTicketsUrl);
      debugPrint('Tickets response: ${response.data}');

      if (response.data['success'] == true) {
        final data = response.data['data'];
        if (data != null && data is List) {
          _tickets = data
              .map((ticket) => SupportTicketModel.fromJson(ticket))
              .toList();
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Fetch tickets error: $e');
      _error = e.toString();
    } finally {
      _ticketsLoading = false;
      notifyListeners();
    }
  }

  Future<SupportTicketModel?> createTicket({
    required String category,
    required String title,
    required String description,
    String? rideId,
    String priority = 'Medium',
  }) async {
    try {
      final response = await _apiService.post(
        AppConstants.createSupportTicketsUrl,
        data: {
          'category': category,
          'subject': title,
          'description': description,
          'ride': rideId,
          'priority': priority,
        },
      );
      if (response.data['success'] == true) {
        final ticket = SupportTicketModel.fromJson(response.data['data']);
        _tickets.add(ticket);
        notifyListeners();
        return ticket;
      }
    } catch (e) {
      debugPrint('Create ticket error: $e');
      _error = e.toString();
      rethrow;
    }
    return null;
  }

  Future<SupportTicketModel?> getTicket(String ticketId) async {
    try {
      final response = await _apiService.get(
        AppConstants.supportTicketUrl.replaceFirst(':id', ticketId),
      );
      if (response.data['success'] == true) {
        return SupportTicketModel.fromJson(response.data['data']);
      }
    } catch (e) {
      debugPrint('Get ticket error: $e');
      _error = e.toString();
    }
    return null;
  }

  Future<void> addMessage(String ticketId, String message) async {
    try {
      await _apiService.post(
        AppConstants.supportTicketMessagesUrl.replaceFirst(':id', ticketId),
        data: {'message': message},
      );
    } catch (e) {
      debugPrint('Add message error: $e');
      _error = e.toString();
      rethrow;
    }
  }

  @override
  void dispose() {
    _stopLocationUpdates();
    _rideRequestSubscription?.cancel();
    super.dispose();
  }
}
