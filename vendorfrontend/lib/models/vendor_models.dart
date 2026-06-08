class Vendor {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String? profilePicture;
  final String companyName;
  final int totalDrivers;
  final int totalVehicles;
  final DateTime createdAt;

  Vendor({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.profilePicture,
    required this.companyName,
    required this.totalDrivers,
    required this.totalVehicles,
    required this.createdAt,
  });

  factory Vendor.fromJson(Map<String, dynamic> json) {
    return Vendor(
      id: json['_id'] ?? json['id'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      profilePicture: json['profilePicture'],
      companyName: json['companyName'],
      totalDrivers: json['totalDrivers'] ?? 0,
      totalVehicles: json['totalVehicles'] ?? 0,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}

class Driver {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String? profilePicture;
  final String? licenseNumber;
  final String status;
  final double rating;
  final int totalRides;
  final DateTime createdAt;

  Driver({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.profilePicture,
    this.licenseNumber,
    required this.status,
    required this.rating,
    required this.totalRides,
    required this.createdAt,
  });

  factory Driver.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;
    return Driver(
      id: json['_id'] ?? json['id'],
      name: user?['name'] ?? 'Unknown',
      email: user?['email'] ?? 'unknown@example.com',
      phone: user?['mobile'] ?? '0000000000',
      profilePicture: user?['profilePic'],
      licenseNumber: json['licenseNumber'],
      status: json['status'] ?? 'offline',
      rating: (json['ratings'] ?? 0.0).toDouble(),
      totalRides: json['numReviews'] ?? 0,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}

class Vehicle {
  final String id;
  final String model;
  final String number;
  final String type;
  final String color;
  final int? year;
  final String? driverId;
  final DateTime createdAt;

  Vehicle({
    required this.id,
    required this.model,
    required this.number,
    required this.type,
    required this.color,
    this.year,
    this.driverId,
    required this.createdAt,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['_id'] ?? json['id'],
      model: json['model'] ?? 'Unknown Model',
      number: json['plateNumber'] ?? 'Unknown',
      type: json['type'] ?? 'sedan',
      color: json['color'] ?? 'Unknown',
      year: json['year'],
      driverId: json['driver']?.toString(),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}

class Trip {
  final String id;
  final String? userId;
  final String? driverId;
  final String? pickupAddress;
  final String? dropAddress;
  final double distance;
  final double fare;
  final String status;
  final DateTime? startTime;
  final DateTime? endTime;
  final DateTime createdAt;

  Trip({
    required this.id,
    this.userId,
    this.driverId,
    this.pickupAddress,
    this.dropAddress,
    required this.distance,
    required this.fare,
    required this.status,
    this.startTime,
    this.endTime,
    required this.createdAt,
  });

  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      id: json['_id'] ?? json['id'],
      userId: json['user']?.toString() ?? json['userId'],
      driverId: json['driver']?.toString() ?? json['driverId'],
      pickupAddress:
          json['pickupLocation']?['address'] ?? json['pickupAddress'],
      dropAddress: json['dropLocation']?['address'] ?? json['dropAddress'],
      distance: (json['distance'] ?? 0.0).toDouble(),
      fare: (json['fare'] ?? 0.0).toDouble(),
      status: json['status'] ?? 'pending',
      startTime: json['startTime'] != null
          ? DateTime.parse(json['startTime'])
          : null,
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}

class Earnings {
  final double totalEarnings;
  final double todayEarnings;
  final double weeklyEarnings;
  final double monthlyEarnings;
  final double vendorCommission;
  final double driverCommission;
  final double walletBalance;

  Earnings({
    required this.totalEarnings,
    required this.todayEarnings,
    required this.weeklyEarnings,
    required this.monthlyEarnings,
    required this.vendorCommission,
    required this.driverCommission,
    required this.walletBalance,
  });

  factory Earnings.fromJson(Map<String, dynamic> json) {
    return Earnings(
      totalEarnings: (json['totalEarnings'] ?? 0.0).toDouble(),
      todayEarnings: (json['todayEarnings'] ?? 0.0).toDouble(),
      weeklyEarnings: (json['weeklyEarnings'] ?? 0.0).toDouble(),
      monthlyEarnings: (json['monthlyEarnings'] ?? 0.0).toDouble(),
      vendorCommission: (json['vendorCommission'] ?? 0.0).toDouble(),
      driverCommission: (json['driverCommission'] ?? 0.0).toDouble(),
      walletBalance: (json['walletBalance'] ?? 0.0).toDouble(),
    );
  }
}

class DashboardStats {
  final int totalRidesToday;
  final double totalEarnings;
  final int activeDrivers;
  final int onlineVehicles;
  final int completedRides;
  final int cancelledRides;
  final List<Trip> recentTrips;

  DashboardStats({
    required this.totalRidesToday,
    required this.totalEarnings,
    required this.activeDrivers,
    required this.onlineVehicles,
    required this.completedRides,
    required this.cancelledRides,
    required this.recentTrips,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalRidesToday: json['totalRidesToday'] ?? 0,
      totalEarnings: (json['totalEarnings'] ?? 0.0).toDouble(),
      activeDrivers: json['activeDrivers'] ?? 0,
      onlineVehicles: json['onlineVehicles'] ?? 0,
      completedRides: json['completedRides'] ?? 0,
      cancelledRides: json['cancelledRides'] ?? 0,
      recentTrips:
          (json['recentTrips'] as List?)
              ?.map((x) => Trip.fromJson(x))
              .toList() ??
          [],
    );
  }
}
