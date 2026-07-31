import 'package:socket_io_client/socket_io_client.dart' as io;
import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

class SocketService {
  late io.Socket socket;
  // Using physical device IP for connectivity
  static String get serverUrl {
    if (kIsWeb) {
      return 'http://localhost:5003';
    } else if (Platform.isAndroid) {
      return 'http://10.0.2.2:5003';
    } else {
      return 'http://localhost:5003';
    }
  }

  final _rideStatusController =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get rideStatusStream =>
      _rideStatusController.stream;

  final _driverLocationController =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get driverLocationStream =>
      _driverLocationController.stream;

  void connect(String userId) {
    developer.log('Attempting to connect to Socket.io at $serverUrl');

    socket = io.io(
        serverUrl,
        io.OptionBuilder()
            .setTransports(['websocket'])
            .setReconnectionAttempts(5)
            .setReconnectionDelay(2000)
            .disableAutoConnect()
            .build());

    socket.connect();

    socket.onConnect((_) {
      developer.log('Connected to Socket.io');
      socket.emit('join', userId);
    });

    socket.onConnectError(
        (data) => developer.log('Socket Connection Error: $data'));
    socket.onError((data) => developer.log('Socket Error: $data'));

    socket.on('rideStatusUpdate', (data) {
      developer.log('Ride Status Updated Event: $data');
      _rideStatusController.add(data);
    });

    socket.on('rideAccepted', (data) {
      developer.log('Ride Accepted Event: $data');
      _rideStatusController.add({'status': 'accepted', ...data});
    });

    socket.on('driverLocationUpdate', (data) {
      developer.log('Driver Location Update Event: $data');
      _driverLocationController.add(data);
    });

    socket.onDisconnect((_) => developer.log('Disconnected from Socket.io'));
  }

  void disconnect() {
    socket.disconnect();
  }
}
