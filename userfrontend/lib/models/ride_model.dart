class RideModel {
  final String id;
  final String userId;
  final String? driverId;
  final String pickupAddress;
  final String dropAddress;
  final double fare;
  final double? distance;
  final String status;
  final String? otp;
  final DateTime? createdAt;
  final String? userName;

  RideModel({
    required this.id,
    required this.userId,
    this.driverId,
    required this.pickupAddress,
    required this.dropAddress,
    required this.fare,
    this.distance,
    required this.status,
    this.otp,
    this.createdAt,
    this.userName,
  });

  factory RideModel.fromMap(Map<String, dynamic> map) {
    return RideModel(
      id: map['_id'] ?? map['id'] ?? '',
      userId: map['user'] is Map ? map['user']['_id'] : (map['user'] ?? ''),
      userName: map['user'] is Map ? map['user']['name'] : null,
      driverId: map['driver'] is Map ? map['driver']['_id'] : map['driver'],
      pickupAddress: map['pickupLocation']?['address'] ?? '',
      dropAddress: map['dropLocation']?['address'] ?? '',
      fare: (map['fare'] ?? 0.0).toDouble(),
      distance: (map['distance'] ?? 0.0).toDouble(),
      status: map['status'] ?? 'pending',
      otp: map['otp'],
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user': userId,
      'driver': driverId,
      'pickupLocation': {'address': pickupAddress},
      'dropLocation': {'address': dropAddress},
      'fare': fare,
      'distance': distance,
      'status': status,
      'otp': otp,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}
