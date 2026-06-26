import 'package:socket_io_client/socket_io_client.dart' as io;
import 'dart:async';
import 'dart:developer' as developer;
import '../models/ride_model.dart';

class SocketService {
  // Singleton instance
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  io.Socket? socket;
  // Using physical device IP for connectivity
  static const String serverUrl = 'http://localhost:5000';
  bool _isConnected = false;

  final _rideStatusController =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get rideStatusStream =>
      _rideStatusController.stream;

  final _driverLocationController =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get driverLocationStream =>
      _driverLocationController.stream;

  final _rideCreatedController = StreamController<RideModel>.broadcast();
  Stream<RideModel> get rideCreatedStream => _rideCreatedController.stream;

  final _rideUpdatedController = StreamController<RideModel>.broadcast();
  Stream<RideModel> get rideUpdatedStream => _rideUpdatedController.stream;

  void connect(String userId) {
    if (_isConnected) {
      developer.log('Socket already connected');
      return;
    }
    developer.log('Attempting to connect to Socket.io at $serverUrl');

    socket = io.io(
        serverUrl,
        io.OptionBuilder()
            .setTransports(['websocket'])
            .setReconnectionAttempts(5)
            .setReconnectionDelay(2000)
            .disableAutoConnect()
            .build());

    socket!.connect();

    socket!.onConnect((_) {
      developer.log('Connected to Socket.io');
      _isConnected = true;
      socket!.emit('join', userId);
    });

    socket!.onConnectError(
        (data) => developer.log('Socket Connection Error: $data'));
    socket!.onError((data) => developer.log('Socket Error: $data'));

    socket!.on('rideStatusUpdate', (data) {
      developer.log('Ride Status Updated Event: $data');
      _rideStatusController.add(data);
    });

    socket!.on('rideAccepted', (data) {
      developer.log('Ride Accepted Event: $data');
      _rideStatusController.add({'status': 'accepted', ...data});
    });

    socket!.on('rideCreated', (data) {
      developer.log('Ride Created Event: $data');
      _rideCreatedController.add(RideModel.fromMap(data));
    });

    socket!.on('rideUpdated', (data) {
      developer.log('Ride Updated Event: $data');
      _rideUpdatedController.add(RideModel.fromMap(data));
    });

    socket!.on('driverAccepted', (data) {
      developer.log('driverAccepted Event: $data');
      _rideStatusController.add({'status': 'accepted', ...data});
      _rideUpdatedController.add(RideModel.fromMap(data));
    });

    socket!.on('driverRejected', (data) {
      developer.log('driverRejected Event: $data');
      _rideStatusController.add({'status': 'searching', ...data});
    });

    socket!.on('driverLocationUpdated', (data) {
      developer.log('driverLocationUpdated Event: $data');
      _driverLocationController.add(data);
    });

    socket!.on('tripStarted', (data) {
      developer.log('tripStarted Event: $data');
      _rideStatusController.add({'status': 'trip_started', ...data});
      _rideUpdatedController.add(RideModel.fromMap(data));
    });

    socket!.on('tripCompleted', (data) {
      developer.log('tripCompleted Event: $data');
      _rideStatusController.add({'status': 'completed', ...data});
      _rideUpdatedController.add(RideModel.fromMap(data));
    });

    socket!.on('driverLocationUpdate', (data) {
      developer.log('Driver Location Update Event: $data');
      _driverLocationController.add(data);
    });

    socket!.onDisconnect((_) {
      developer.log('Disconnected from Socket.io');
      _isConnected = false;
    });
  }

  void disconnect() {
    if (socket != null) {
      socket!.disconnect();
      _isConnected = false;
    }
  }

  void dispose() {
    _rideStatusController.close();
    _driverLocationController.close();
    _rideCreatedController.close();
    _rideUpdatedController.close();
    if (socket != null) {
      socket!.dispose();
    }
  }
}
