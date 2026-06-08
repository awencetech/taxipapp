import 'user_model.dart';

class DriverModel {
  final String id;
  final UserModel user;
  final bool isOnline;
  final String status;
  final List<double> currentLocation;
  final double ratings;

  DriverModel({
    required this.id,
    required this.user,
    required this.isOnline,
    required this.status,
    required this.currentLocation,
    required this.ratings,
  });

  factory DriverModel.fromMap(Map<String, dynamic> map) {
    return DriverModel(
      id: map['_id'] ?? map['id'] ?? '',
      user: UserModel.fromMap(map['user'] ?? {}),
      isOnline: map['isOnline'] ?? false,
      status: map['status'] ?? 'offline',
      currentLocation: List<double>.from(map['currentLocation']?['coordinates'] ?? [0.0, 0.0]),
      ratings: (map['ratings'] ?? 5.0).toDouble(),
    );
  }
}
