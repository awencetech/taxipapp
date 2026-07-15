import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'dart:developer' as developer;
import '../models/driver_models.dart';
import '../services/socket_service.dart';
import '../services/api_service.dart';
import '../core/constants/app_constants.dart';
import '../views/rides/ride_details_screen.dart';

class RideViewModel extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final SocketService _socketService = SocketService();
  StreamSubscription<Map<String, dynamic>>? _rideRequestSubscription;

  final List<RideRequestModel> _incomingRequests = [];
  RideRequestModel? _currentRide;
  bool _isOnline = false;
  bool _isLoading = false;
  DateTime? _onlineStartTime;
  Timer? _onlineTimer;
  StreamSubscription<Position>? _positionStream;
  final List<RideRequestModel> _nearbyRides = [];
  List<RideRequestModel> _rideHistory = [];
  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  String? _error;
  String? _driverId;

  List<RideRequestModel> get incomingRequests => _incomingRequests;
  RideRequestModel? get currentRide => _currentRide;
  bool get isOnline => _isOnline;
  bool get isLoading => _isLoading;

  String get onlineDuration {
    if (_onlineStartTime == null) return '00:00:00';
    final Duration elapsed = DateTime.now().difference(_onlineStartTime!);
    int hours = elapsed.inHours;
    int minutes = elapsed.inMinutes.remainder(60);
    int seconds = elapsed.inSeconds.remainder(60);
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  List<RideRequestModel> get nearbyRides => _nearbyRides;
  List<RideRequestModel> get rideHistory => _rideHistory;
  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  String? get error => _error;

  Future<void> initialize(String driverId) async {
    _driverId = driverId;
    _socketService.connect(driverId);

    // Fetch current active ride (if any), pending rides, and ride history
    await fetchCurrentRide();
    await fetchPendingRides();

    _rideRequestSubscription = _socketService.rideRequestStream.listen((data) {
      developer.log('Received new ride request from socket: $data');
      try {
        final newRide = RideRequestModel.fromJson(data);
        // Only add if not already in the list
        if (!_incomingRequests.any((r) => r.id == newRide.id)) {
          _incomingRequests.add(newRide);
          notifyListeners();
        }
      } catch (e) {
        developer.log('Error parsing ride request: $e');
      }
    });
  }

  void toggleOnlineOffline() async {
    _isOnline = !_isOnline;

    try {
      await _apiService.put(
        AppConstants.driverStatusUrl,
        data: {
          'isOnline': _isOnline,
          'status': _isOnline ? 'available' : 'offline',
        },
      );

      // Emit socket event for status change
      if (_driverId != null) {
        if (_isOnline) {
          _socketService.emit('goOnline', {'driverId': _driverId});
        } else {
          _socketService.emit('goOffline', {'driverId': _driverId});
        }
      }
    } catch (e) {
      debugPrint('Error updating driver status: $e');
    }

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
    _onlineStartTime = DateTime.now();
    if (_onlineTimer == null || !_onlineTimer!.isActive) {
      _onlineTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        notifyListeners();
      });
    }
  }

  void _stopOnlineTimer() {
    _onlineTimer?.cancel();
    _onlineTimer = null;
    _onlineStartTime = null;
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
        // Remove from both incoming list and ride history
        _incomingRequests.removeWhere((ride) => ride.id == rideId);
        _rideHistory.removeWhere((ride) => ride.id == rideId);

        // Emit socket event: rideAccepted
        _socketService.emit('rideAccepted', {
          'rideId': rideId,
          'driverId': _driverId,
        });

        notifyListeners();

        if (context.mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const RideDetailsScreen()),
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

      // Emit socket event: rideRejected
      _socketService.emit('rideRejected', {
        'rideId': rideId,
        'driverId': _driverId,
      });

      // Remove from both incoming list and ride history
      _incomingRequests.removeWhere((ride) => ride.id == rideId);
      _rideHistory.removeWhere((ride) => ride.id == rideId);
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

        // Emit socket event: driverArrived
        _socketService.emit('driverArrived', {
          'rideId': _currentRide!.id,
          'driverId': _driverId,
        });

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

        // Emit socket event: tripStarted
        _socketService.emit('tripStarted', {
          'rideId': _currentRide!.id,
          'driverId': _driverId,
        });

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
        // Emit socket event: tripCompleted
        _socketService.emit('tripCompleted', {
          'rideId': _currentRide!.id,
          'driverId': _driverId,
        });

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

  Future<void> fetchPendingRides() async {
    try {
      developer.log('Fetching pending rides...');
      final response = await _apiService.get(AppConstants.pendingRidesUrl);
      developer.log('Pending rides response: ${response.data}');

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

      if (isSuccess && ridesData != null) {
        for (var rideData in ridesData) {
          final ride = RideRequestModel.fromJson(rideData);
          if (!_incomingRequests.any((r) => r.id == ride.id)) {
            _incomingRequests.add(ride);
          }
        }
        notifyListeners();
      }
    } catch (e) {
      developer.log('Error fetching pending rides: $e');
    }
  }

  Future<void> fetchRideHistory() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.get(AppConstants.driverHistoryUrl);

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

  // For testing purposes: add sample ride requests
  void addSampleRides() {
    final sampleRides = [
      RideRequestModel(
        id: 'sample-ride-1',
        passengerName: 'John Doe',
        pickupAddress:
            'Chennai Central Railway Station, Park Town, Chennai, Tamil Nadu',
        dropAddress:
            'T Nagar Bus Stand, Pondy Bazaar, T Nagar, Chennai, Tamil Nadu',
        pickupCoords: [13.0827, 80.2707],
        dropCoords: [13.0820, 80.2800],
        fare: 250,
        distance: 5.2,
        estimatedTime: 15,
        status: 'pending',
        vehicleType: 'AUTO',
        paymentMethod: 'cash',
        createdAt: DateTime.now(),
      ),
      RideRequestModel(
        id: 'sample-ride-2',
        passengerName: 'Jane Smith',
        pickupAddress: 'Anna Nagar Roundtana, Anna Nagar, Chennai, Tamil Nadu',
        dropAddress: 'Phoenix Marketcity, Velachery, Chennai, Tamil Nadu',
        pickupCoords: [13.0674, 80.2376],
        dropCoords: [12.9772, 80.2209],
        fare: 450,
        distance: 12.5,
        estimatedTime: 35,
        status: 'pending',
        vehicleType: 'BIKE',
        paymentMethod: 'upi',
        createdAt: DateTime.now().subtract(const Duration(minutes: 2)),
      ),
    ];

    for (var ride in sampleRides) {
      if (!_incomingRequests.any((r) => r.id == ride.id)) {
        _incomingRequests.add(ride);
      }
    }
    notifyListeners();
  }
}
