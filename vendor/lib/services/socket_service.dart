import 'package:socket_io_client/socket_io_client.dart' as io;
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../core/constants/app_constants.dart';

class SocketService {
  late io.Socket socket;

  final _tripUpdateController =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get tripUpdateStream =>
      _tripUpdateController.stream;

  final _driverLocationController =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get driverLocationStream =>
      _driverLocationController.stream;

  final _driverStatusController =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get driverStatusStream =>
      _driverStatusController.stream;

  void connect(String vendorId) {
    socket = io.io(
      AppConstants.socketUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setReconnectionAttempts(5)
          .setReconnectionDelay(2000)
          .disableAutoConnect()
          .build(),
    );

    socket.connect();

    socket.onConnect((_) {
      if (kDebugMode) {
        debugPrint('Connected to Socket.io');
      }
      socket.emit('joinVendor', vendorId);
    });

    socket.onConnectError((data) {
      if (kDebugMode) {
        debugPrint('Socket Connection Error: $data');
      }
    });
    socket.onError((data) {
      if (kDebugMode) {
        debugPrint('Socket Error: $data');
      }
    });

    socket.on('tripUpdate', (data) {
      _tripUpdateController.add(data);
    });

    socket.on('driverLocationUpdate', (data) {
      _driverLocationController.add(data);
    });

    socket.on('driverStatusChanged', (data) {
      if (kDebugMode) {
        debugPrint('Received driverStatusChanged: $data');
      }
      _driverStatusController.add(data);
    });

    socket.onDisconnect((_) {
      if (kDebugMode) {
        debugPrint('Disconnected from Socket.io');
      }
    });
  }

  void disconnect() {
    socket.disconnect();
  }

  void emit(String event, dynamic data) {
    socket.emit(event, data);
  }

  void dispose() {
    _tripUpdateController.close();
    _driverLocationController.close();
    _driverStatusController.close();
  }
}
