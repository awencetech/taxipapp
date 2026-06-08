class DriverModel {
  final String id;
  final String name;
  final String email;
  final String mobile;
  final String vehicleType;
  final String vehicleNumber;
  final bool isOnline;
  final String? profilePic;
  final double rating;

  DriverModel({
    required this.id,
    required this.name,
    required this.email,
    required this.mobile,
    required this.vehicleType,
    required this.vehicleNumber,
    required this.isOnline,
    this.profilePic,
    this.rating = 0.0,
  });

  factory DriverModel.fromJson(Map<String, dynamic> json) {
    return DriverModel(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      mobile: json['mobile'] ?? '',
      vehicleType: json['vehicleType'] ?? 'Car',
      vehicleNumber: json['vehicleNumber'] ?? 'TN 01 AB 1234',
      isOnline: json['isOnline'] ?? false,
      profilePic: json['profilePic'],
      rating: (json['ratings'] ?? json['rating'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'mobile': mobile,
      'vehicleType': vehicleType,
      'vehicleNumber': vehicleNumber,
      'isOnline': isOnline,
      'profilePic': profilePic,
      'rating': rating,
    };
  }
}

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final Map<String, dynamic>? data;
  final DateTime? createdAt;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    this.data,
    this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      type: json['type'] ?? 'system',
      isRead: json['isRead'] ?? false,
      data: json['data'] != null
          ? Map<String, dynamic>.from(json['data'])
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
    );
  }
}

class RideRequestModel {
  final String id;
  final String passengerName;
  final String pickupAddress;
  final String dropAddress;
  final List<double> pickupCoords;
  final List<double> dropCoords;
  final double fare;
  final double distance;
  final int estimatedTime;
  final String status;
  final DateTime? createdAt;

  RideRequestModel({
    required this.id,
    required this.passengerName,
    required this.pickupAddress,
    required this.dropAddress,
    required this.pickupCoords,
    required this.dropCoords,
    required this.fare,
    required this.distance,
    required this.estimatedTime,
    this.status = 'pending',
    this.createdAt,
  });

  factory RideRequestModel.fromJson(Map<String, dynamic> json) {
    return RideRequestModel(
      id: json['_id'] ?? json['id'] ?? '',
      passengerName: json['user'] != null
          ? json['user']['name'] ?? 'Passenger'
          : 'Passenger',
      pickupAddress: json['pickupLocation'] != null
          ? json['pickupLocation']['address'] ?? ''
          : '',
      dropAddress: json['dropLocation'] != null
          ? json['dropLocation']['address'] ?? ''
          : '',
      pickupCoords:
          json['pickupLocation'] != null &&
              json['pickupLocation']['coordinates'] != null
          ? List<double>.from(json['pickupLocation']['coordinates'])
          : [0.0, 0.0],
      dropCoords:
          json['dropLocation'] != null &&
              json['dropLocation']['coordinates'] != null
          ? List<double>.from(json['dropLocation']['coordinates'])
          : [0.0, 0.0],
      fare: (json['fare'] ?? 0.0).toDouble(),
      distance: (json['distance'] ?? 0.0).toDouble(),
      estimatedTime: json['duration'] ?? 0,
      status: json['status'] ?? 'pending',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
    );
  }
}
