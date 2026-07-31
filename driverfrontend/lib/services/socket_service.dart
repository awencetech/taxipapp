import 'package:socket_io_client/socket_io_client.dart' as io;
import 'dart:async';
import 'dart:developer' as developer;
import '../core/constants/app_constants.dart';

class SocketService {
  late io.Socket socket;

  final _rideRequestController =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get rideRequestStream =>
      _rideRequestController.stream;

  void connect(String driverId) {
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
      socket.emit('join', driverId);
    });

    socket.onConnectError(
      (data) => developer.log('Socket Connection Error: $data'),
    );
    socket.onError((data) => developer.log('Socket Error: $data'));

    socket.on('newRideRequest', (data) {
      developer.log('New Ride Request Event: $data');
      _rideRequestController.add(data);
    });

    socket.on('ride-request', (data) {
      developer.log('Normalized Ride Request Event: $data');
      _rideRequestController.add(data);
    });

    socket.on('ride-updated', (data) {
      developer.log('Ride Updated Event: $data');
      _rideRequestController.add(data);
    });

    socket.on('notification', (data) {
      developer.log('Socket Notification Event: $data');
      _rideRequestController.add(data);
    });

    socket.on('driver-status', (data) {
      developer.log('Driver Status Event: $data');
      _rideRequestController.add(data);
    });

    socket.onDisconnect((_) => developer.log('Disconnected from Socket.io'));
  }

  void disconnect() {
    socket.disconnect();
  }

  void emit(String event, dynamic data) {
    socket.emit(event, data);
  }
}
