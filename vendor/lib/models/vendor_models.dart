class Vendor {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String? profilePicture;
  final String companyName;
  final bool isApproved;
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
    required this.isApproved,
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
      isApproved: json['isApproved'] ?? false,
      totalDrivers: json['totalDrivers'] ?? 0,
      totalVehicles: json['totalVehicles'] ?? 0,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}

class Driver {
  final String id;
  final String? driverId;
  final String name;
  final String email;
  final String phone;
  final String? profilePicture;
  final String? licenseNumber;
  final String status;
  final double rating;
  final int totalRides;
  final DateTime createdAt;
  final double? currentLatitude;
  final double? currentLongitude;
  final String? vehicleType;
  final String? vehicleNumber;
  final String? vehicleModel;
  final DateTime? lastUpdated;
  final double? speed;
  final String? currentAddress;
  final bool? isOnline;
  final bool? isBusy;
  final bool? isApproved;
  final String? currentRide;
  final double? totalEarnings;
  final String? vehicleBrand;
  final int todayTrips;
  final num todayEarnings;

  Driver({
    required this.id,
    this.driverId,
    required this.name,
    required this.email,
    required this.phone,
    this.profilePicture,
    this.licenseNumber,
    required this.status,
    required this.rating,
    required this.totalRides,
    required this.createdAt,
    this.currentLatitude,
    this.currentLongitude,
    this.vehicleType,
    this.vehicleNumber,
    this.vehicleModel,
    this.lastUpdated,
    this.speed,
    this.currentAddress,
    this.isOnline,
    this.isBusy,
    this.isApproved = false,
    this.currentRide,
    this.totalEarnings,
    this.vehicleBrand,
    this.todayTrips = 0,
    this.todayEarnings = 0,
  });

  factory Driver.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;
    return Driver(
      id: (json['_id'] ?? json['id']).toString(),
      driverId: json['driverId']?.toString(),
      name: user?['name']?.toString() ?? 'Unknown',
      email: user?['email']?.toString() ?? 'unknown@example.com',
      phone: user?['mobile']?.toString() ?? '0000000000',
      profilePicture: user?['profilePic']?.toString(),
      licenseNumber: json['licenseNumber']?.toString(),
      status: json['status']?.toString() ?? 'offline',
      rating: (json['ratings'] as num?)?.toDouble() ?? 0.0,
      totalRides: (json['numReviews'] as num?)?.toInt() ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      currentLatitude: (json['currentLatitude'] as num?)?.toDouble(),
      currentLongitude: (json['currentLongitude'] as num?)?.toDouble(),
      vehicleType: json['vehicleType']?.toString(),
      vehicleNumber: json['vehicleNumber']?.toString(),
      vehicleModel: json['vehicleModel']?.toString(),
      lastUpdated: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
      speed: (json['speed'] as num?)?.toDouble(),
      currentAddress: json['currentAddress']?.toString(),
      isOnline: json['isOnline'] as bool? ?? false,
      isBusy: json['isBusy'] as bool? ?? false,
      isApproved: json['isApproved'] as bool? ?? false,
      currentRide: json['currentRide']?.toString(),
      totalEarnings: (json['totalEarnings'] as num?)?.toDouble(),
      vehicleBrand: json['vehicleBrand']?.toString(),
      todayTrips: (json['todayTrips'] as num?)?.toInt() ?? 0,
      todayEarnings: json['todayEarnings'] as num? ?? 0,
    );
  }
}

class User {
  final String? id;
  final String? name;
  final String? email;
  final String? mobile;
  final String? profilePic;

  User({this.id, this.name, this.email, this.mobile, this.profilePic});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id']?.toString(),
      name: json['name']?.toString(),
      email: json['email']?.toString(),
      mobile: json['mobile']?.toString(),
      profilePic: json['profilePic']?.toString(),
    );
  }
}

class Ride {
  final String id;
  final User? user;
  final String? pickupAddress;
  final double? pickupLatitude;
  final double? pickupLongitude;
  final String? dropAddress;
  final double? dropLatitude;
  final double? dropLongitude;
  final String status;
  final num? fare;
  final num? distance;
  final num? duration;
  final DateTime? createdAt;
  final DateTime? startTime;
  final DateTime? endTime;

  Ride({
    required this.id,
    this.user,
    this.pickupAddress,
    this.pickupLatitude,
    this.pickupLongitude,
    this.dropAddress,
    this.dropLatitude,
    this.dropLongitude,
    required this.status,
    this.fare,
    this.distance,
    this.duration,
    this.createdAt,
    this.startTime,
    this.endTime,
  });

  factory Ride.fromJson(Map<String, dynamic> json) {
    final pickupLoc = json['pickupLocation'] as Map<String, dynamic>?;
    final dropLoc = json['dropLocation'] as Map<String, dynamic>?;

    return Ride(
      id: json['_id']?.toString() ?? '',
      user: json['user'] != null ? User.fromJson(json['user']) : null,
      pickupAddress: pickupLoc?['address']?.toString(),
      pickupLatitude: (pickupLoc?['coordinates']?[1] as num?)?.toDouble(),
      pickupLongitude: (pickupLoc?['coordinates']?[0] as num?)?.toDouble(),
      dropAddress: dropLoc?['address']?.toString(),
      dropLatitude: (dropLoc?['coordinates']?[1] as num?)?.toDouble(),
      dropLongitude: (dropLoc?['coordinates']?[0] as num?)?.toDouble(),
      status: json['status']?.toString() ?? 'searching',
      fare: json['fare'] as num?,
      distance: json['distance'] as num?,
      duration: json['duration'] as num?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      startTime: json['startTime'] != null
          ? DateTime.tryParse(json['startTime'].toString())
          : null,
      endTime: json['endTime'] != null
          ? DateTime.tryParse(json['endTime'].toString())
          : null,
    );
  }
}

class Vehicle {
  final String id;
  final String? driver; // driver object ID
  final String model;
  final String number;
  final String type;
  final String color;
  final int? year;
  final String? brand;
  final String? rcNumber;
  final DateTime? insuranceExpiry;
  final DateTime? pollutionExpiry;
  final String status; // active, inactive, maintenance
  final DateTime createdAt;
  final DateTime updatedAt;

  // Additional fields from API
  final String? driverName;
  final String? driverId;
  final String? driverPhone;
  final String? driverAvatar;
  final String? driverStatus;
  final int todayTrips;
  final num todayEarnings;
  final DateTime? lastRide;

  Vehicle({
    required this.id,
    this.driver,
    required this.model,
    required this.number,
    required this.type,
    required this.color,
    this.year,
    this.brand,
    this.rcNumber,
    this.insuranceExpiry,
    this.pollutionExpiry,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.driverName,
    this.driverId,
    this.driverPhone,
    this.driverAvatar,
    this.driverStatus,
    this.todayTrips = 0,
    this.todayEarnings = 0,
    this.lastRide,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: (json['_id']?.toString() ?? json['id']?.toString()) ?? '',
      driver: json['driver']?.toString(),
      model: json['model'] ?? 'Unknown Model',
      number: json['plateNumber'] ?? 'Unknown',
      type: json['type'] ?? 'sedan',
      color: json['color'] ?? 'Unknown',
      year: json['year'],
      brand: json['brand'],
      rcNumber: json['rcNumber'],
      insuranceExpiry: json['insuranceExpiry'] != null
          ? DateTime.tryParse(json['insuranceExpiry'])
          : null,
      pollutionExpiry: json['pollutionExpiry'] != null
          ? DateTime.tryParse(json['pollutionExpiry'])
          : null,
      status: json['status'] ?? json['vehicleStatus'] ?? 'active',
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      driverName: json['driverName'],
      driverId: json['driverId'],
      driverPhone: json['driverPhone'],
      driverAvatar: json['driverAvatar'],
      driverStatus: json['driverStatus'],
      todayTrips: json['todayTrips'] ?? 0,
      todayEarnings: json['todayEarnings'] ?? 0,
      lastRide: json['lastRide'] != null
          ? DateTime.tryParse(json['lastRide'])
          : null,
    );
  }
}

class TripUser {
  final String? id;
  final String? name;
  final String? email;
  final String? mobile;
  final String? profilePic;

  TripUser({this.id, this.name, this.email, this.mobile, this.profilePic});

  factory TripUser.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return TripUser();
    }
    return TripUser(
      id: json['_id']?.toString() ?? json['id']?.toString(),
      name: json['name'],
      email: json['email'],
      mobile: json['mobile'],
      profilePic: json['profilePic'],
    );
  }
}

class Trip {
  final String id;
  final String? userId;
  final TripUser? user;
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
    this.user,
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
      userId: json['user'] is Map
          ? json['user']['_id']?.toString()
          : json['user']?.toString() ?? json['userId'],
      user: TripUser.fromJson(json['user'] is Map ? json['user'] : null),
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
  final double pendingPayments;
  final double settledPayments;
  final double driverPayouts;
  final List<Map<String, dynamic>> transactions;

  Earnings({
    required this.totalEarnings,
    required this.todayEarnings,
    required this.weeklyEarnings,
    required this.monthlyEarnings,
    required this.vendorCommission,
    required this.driverCommission,
    required this.walletBalance,
    required this.pendingPayments,
    required this.settledPayments,
    required this.driverPayouts,
    required this.transactions,
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
      pendingPayments: (json['pendingPayments'] ?? 0.0).toDouble(),
      settledPayments: (json['settledPayments'] ?? 0.0).toDouble(),
      driverPayouts: (json['driverPayouts'] ?? 0.0).toDouble(),
      transactions:
          (json['transactions'] as List?)
              ?.map((x) => Map<String, dynamic>.from(x as Map))
              .toList() ??
          [],
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
