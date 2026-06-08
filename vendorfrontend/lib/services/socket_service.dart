import 'package:socket_io_client/socket_io_client.dart' as io;
import 'dart:async';
import 'dart:developer' as developer;
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

  void connect(String vendorId) {
    developer.log(
      'Attempting to connect to Socket.io at ${AppConstants.socketUrl}',
    );

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
      developer.log('Connected to Socket.io');
      socket.emit('joinVendor', vendorId);
    });

    socket.onConnectError(
      (data) => developer.log('Socket Connection Error: $data'),
    );
    socket.onError((data) => developer.log('Socket Error: $data'));

    socket.on('tripUpdate', (data) {
      developer.log('Trip Update Event: $data');
      _tripUpdateController.add(data);
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

  void emit(String event, dynamic data) {
    socket.emit(event, data);
  }

  void dispose() {
    _tripUpdateController.close();
    _driverLocationController.close();
  }
}
