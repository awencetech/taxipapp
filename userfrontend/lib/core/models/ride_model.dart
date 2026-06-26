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
  // Driver details
  final String? driverName;
  final String? driverVehicleType;
  final String? driverVehicleNumber;
  final double? driverRating;
  final double? driverLatitude;
  final double? driverLongitude;

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
    this.driverName,
    this.driverVehicleType,
    this.driverVehicleNumber,
    this.driverRating,
    this.driverLatitude,
    this.driverLongitude,
  });

  factory RideModel.fromMap(Map<String, dynamic> map) {
    // Helper function to parse double
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) {
        return double.tryParse(value) ?? 0.0;
      }
      return 0.0;
    }

    // Helper function to get address from location
    String getAddress(dynamic location) {
      if (location is Map) {
        if (location['address'] != null) return location['address'].toString();
        if (location['locationAddress'] != null)
          return location['locationAddress'].toString();
      }
      return '';
    }

    // Get userId
    String userId = '';
    String? userName;
    if (map['user'] is Map) {
      userId = map['user']['_id']?.toString() ?? '';
      userName = map['user']['name']?.toString();
    } else if (map['user'] != null) {
      userId = map['user'].toString();
    }

    // Get driverId
    String? driverId;
    String? driverName;
    String? driverVehicleType;
    String? driverVehicleNumber;
    double? driverRating;
    double? driverLatitude;
    double? driverLongitude;
    if (map['driver'] is Map) {
      driverId = map['driver']['_id']?.toString();
      driverName = map['driver']['name']?.toString();
      driverVehicleType = map['driver']['vehicleType']?.toString();
      driverVehicleNumber = map['driver']['vehicleNumber']?.toString();
      driverRating =
          parseDouble(map['driver']['rating'] ?? map['driver']['ratings']);
      driverLatitude = parseDouble(map['driver']['currentLatitude']);
      driverLongitude = parseDouble(map['driver']['currentLongitude']);
    } else if (map['driver'] != null) {
      driverId = map['driver'].toString();
    }
    // Also check for driverLocationUpdated data
    driverLatitude ??= parseDouble(map['latitude']);
    driverLongitude ??= parseDouble(map['longitude']);

    // Get pickup and drop addresses
    String pickupAddress = getAddress(map['pickupLocation']);
    String dropAddress = getAddress(map['dropLocation']);

    // Fallback to direct address fields if needed
    if (pickupAddress.isEmpty && map['pickupAddress'] != null) {
      pickupAddress = map['pickupAddress'].toString();
    }
    if (dropAddress.isEmpty && map['dropAddress'] != null) {
      dropAddress = map['dropAddress'].toString();
    }

    return RideModel(
      id: map['_id']?.toString() ?? map['id']?.toString() ?? '',
      userId: userId,
      userName: userName,
      driverId: driverId,
      driverName: driverName,
      driverVehicleType: driverVehicleType,
      driverVehicleNumber: driverVehicleNumber,
      driverRating: driverRating,
      driverLatitude: driverLatitude,
      driverLongitude: driverLongitude,
      pickupAddress: pickupAddress,
      dropAddress: dropAddress,
      fare: parseDouble(map['fare']),
      distance: map['distance'] != null ? parseDouble(map['distance']) : null,
      status: map['status']?.toString().toLowerCase() ?? 'pending',
      otp: map['otp']?.toString(),
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString())
          : null,
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
      'driverLatitude': driverLatitude,
      'driverLongitude': driverLongitude,
    };
  }
}
