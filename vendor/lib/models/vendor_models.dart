class Vendor {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String? profilePicture;
  final String companyName;
  final bool isApproved;
  final String role;
  final String approvalStatus;
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
    required this.role,
    required this.approvalStatus,
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
      role: json['role'] ?? 'sub_vendor',
      approvalStatus: json['approvalStatus'] ?? 'pending',
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
  final int completedTrips;
  final int cancelledTrips;
  final DateTime createdAt;
  final DateTime? lastLogin;
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
  final double? walletBalance;
  final String? vehicleBrand;
  final int todayTrips;
  final num todayEarnings;
  final String? accountStatus;
  final String? approvedBy;
  final DateTime? approvedAt;
  final String? rejectionReason;
  final bool? documentsVerified;
  final String? firstName;
  final String? lastName;
  final String? approvalStatus;
  final String? city;
  final String? aadhaarNumber; // Masked
  final List<dynamic>? documents;

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
    this.completedTrips = 0,
    this.cancelledTrips = 0,
    required this.createdAt,
    this.lastLogin,
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
    this.walletBalance,
    this.vehicleBrand,
    this.todayTrips = 0,
    this.todayEarnings = 0,
    this.accountStatus,
    this.approvedBy,
    this.approvedAt,
    this.rejectionReason,
    this.documentsVerified,
    this.firstName,
    this.lastName,
    this.approvalStatus,
    this.city,
    this.aadhaarNumber,
    this.documents,
  });

  factory Driver.fromJson(Map<String, dynamic> json) {
    // Safely get user - check if it's a Map first
    final user = (json['user'] is Map<String, dynamic>) ? json['user'] as Map<String, dynamic> : null;
    
    // Helper function to safely get string
    String safeString(dynamic value) {
      if (value == null) return '';
      return value.toString();
    }
    
    // Helper function to safely get int
    int safeInt(dynamic value, [int defaultValue = 0]) {
      if (value == null) return defaultValue;
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) {
        return int.tryParse(value) ?? defaultValue;
      }
      return defaultValue;
    }
    
    // Helper function to safely get double
    double safeDouble(dynamic value, [double defaultValue = 0.0]) {
      if (value == null) return defaultValue;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) {
        return double.tryParse(value) ?? defaultValue;
      }
      return defaultValue;
    }
    
    return Driver(
      id: safeString(json['_id'] ?? json['id']),
      driverId: json['driverId']?.toString(),
      name: safeString(json['name'] ?? user?['name']).isEmpty ? 'Unknown' : safeString(json['name'] ?? user?['name']),
      firstName: json['firstName']?.toString(),
      lastName: json['lastName']?.toString(),
      email: safeString(json['email'] ?? user?['email']).isEmpty ? 'unknown@example.com' : safeString(json['email'] ?? user?['email']),
      phone: safeString(json['mobile'] ?? user?['mobile']).isEmpty ? '0000000000' : safeString(json['mobile'] ?? user?['mobile']),
      profilePicture: safeString(json['profilePic'] ?? user?['profilePic']).isEmpty ? null : safeString(json['profilePic'] ?? user?['profilePic']),
      licenseNumber: json['licenseNumber']?.toString(),
      status: safeString(json['status']).isEmpty ? 'offline' : safeString(json['status']),
      rating: safeDouble(json['ratings']),
      totalRides: safeInt(json['numReviews']),
      completedTrips: safeInt(json['completedTrips']),
      cancelledTrips: safeInt(json['cancelledTrips']),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      lastLogin: json['lastLogin'] != null
          ? DateTime.tryParse(json['lastLogin'].toString())
          : null,
      currentLatitude: safeDouble(json['currentLatitude'], 0.0),
      currentLongitude: safeDouble(json['currentLongitude'], 0.0),
      vehicleType: json['vehicleType']?.toString(),
      vehicleNumber: json['vehicleNumber']?.toString(),
      vehicleModel: json['vehicleModel']?.toString(),
      lastUpdated: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
      speed: safeDouble(json['speed']),
      currentAddress: json['currentAddress']?.toString(),
      isOnline: json['isOnline'] as bool? ?? false,
      isBusy: json['isBusy'] as bool? ?? false,
      isApproved: json['isApproved'] as bool? ?? false,
      currentRide: json['currentRide']?.toString(),
      totalEarnings: safeDouble(json['totalEarnings']),
      walletBalance: safeDouble(json['walletBalance']),
      vehicleBrand: json['vehicleBrand']?.toString(),
      todayTrips: safeInt(json['todayTrips']),
      todayEarnings: safeDouble(json['todayEarnings']),
      accountStatus: safeString(json['accountStatus'] ?? json['status']).isEmpty ? 'pending' : safeString(json['accountStatus'] ?? json['status']),
      approvedBy: json['approvedBy']?.toString(),
      approvedAt: json['approvedAt'] != null
          ? DateTime.tryParse(json['approvedAt'].toString())
          : null,
      rejectionReason: json['rejectionReason']?.toString(),
      documentsVerified: json['documentsVerified'] as bool? ?? false,
      approvalStatus: json['approvalStatus']?.toString(),
      city: json['city']?.toString(),
      aadhaarNumber: json['aadhaarNumber']?.toString(),
      documents: json['documents'] as List<dynamic>?,
    );
  }

  // Copy with method for updating individual fields
  Driver copyWith({
    String? id,
    String? driverId,
    String? name,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? profilePicture,
    String? licenseNumber,
    String? status,
    double? rating,
    int? totalRides,
    int? completedTrips,
    int? cancelledTrips,
    DateTime? createdAt,
    DateTime? lastLogin,
    double? currentLatitude,
    double? currentLongitude,
    String? vehicleType,
    String? vehicleNumber,
    String? vehicleModel,
    DateTime? lastUpdated,
    double? speed,
    String? currentAddress,
    bool? isOnline,
    bool? isBusy,
    bool? isApproved,
    String? approvalStatus,
    String? accountStatus,
    String? currentRide,
    double? totalEarnings,
    double? walletBalance,
    String? vehicleBrand,
    int? todayTrips,
    num? todayEarnings,
    String? approvedBy,
    DateTime? approvedAt,
    String? rejectionReason,
    bool? documentsVerified,
    String? city,
    String? aadhaarNumber,
    List<dynamic>? documents,
  }) {
    return Driver(
      id: id ?? this.id,
      driverId: driverId ?? this.driverId,
      name: name ?? this.name,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      profilePicture: profilePicture ?? this.profilePicture,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      status: status ?? this.status,
      rating: rating ?? this.rating,
      totalRides: totalRides ?? this.totalRides,
      completedTrips: completedTrips ?? this.completedTrips,
      cancelledTrips: cancelledTrips ?? this.cancelledTrips,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      currentLatitude: currentLatitude ?? this.currentLatitude,
      currentLongitude: currentLongitude ?? this.currentLongitude,
      vehicleType: vehicleType ?? this.vehicleType,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      vehicleModel: vehicleModel ?? this.vehicleModel,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      speed: speed ?? this.speed,
      currentAddress: currentAddress ?? this.currentAddress,
      isOnline: isOnline ?? this.isOnline,
      isBusy: isBusy ?? this.isBusy,
      isApproved: isApproved ?? this.isApproved,
      approvalStatus: approvalStatus ?? this.approvalStatus,
      accountStatus: accountStatus ?? this.accountStatus,
      currentRide: currentRide ?? this.currentRide,
      totalEarnings: totalEarnings ?? this.totalEarnings,
      walletBalance: walletBalance ?? this.walletBalance,
      vehicleBrand: vehicleBrand ?? this.vehicleBrand,
      todayTrips: todayTrips ?? this.todayTrips,
      todayEarnings: todayEarnings ?? this.todayEarnings,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedAt: approvedAt ?? this.approvedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      documentsVerified: documentsVerified ?? this.documentsVerified,
      city: city ?? this.city,
      aadhaarNumber: aadhaarNumber ?? this.aadhaarNumber,
      documents: documents ?? this.documents,
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
  final int pendingDrivers;
  final int approvedDrivers;
  final int rejectedDrivers;
  final int todayRegistrations;
  final int totalDrivers;
  final int offlineDrivers;
  final int busyDrivers;
  final int suspendedDrivers;

  DashboardStats({
    required this.totalRidesToday,
    required this.totalEarnings,
    required this.activeDrivers,
    required this.onlineVehicles,
    required this.completedRides,
    required this.cancelledRides,
    required this.recentTrips,
    required this.pendingDrivers,
    required this.approvedDrivers,
    required this.rejectedDrivers,
    required this.todayRegistrations,
    this.totalDrivers = 0,
    this.offlineDrivers = 0,
    this.busyDrivers = 0,
    this.suspendedDrivers = 0,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalRidesToday: json['totalRidesToday'] ?? 0,
      totalEarnings: (json['totalEarnings'] ?? 0.0).toDouble(),
      activeDrivers: json['activeDrivers'] ?? 0,
      onlineVehicles: json['onlineVehicles'] ?? 0,
      completedRides: json['completedRides'] ?? 0,
      cancelledRides: json['cancelledRides'] ?? 0,
      recentTrips: (json['recentTrips'] as List?)?.map((x) => Trip.fromJson(x)).toList() ?? [],
      pendingDrivers: json['pendingDrivers'] ?? 0,
      approvedDrivers: json['approvedDrivers'] ?? 0,
      rejectedDrivers: json['rejectedDrivers'] ?? 0,
      todayRegistrations: json['todayRegistrations'] ?? 0,
      totalDrivers: json['totalDrivers'] ?? 0,
      offlineDrivers: json['offlineDrivers'] ?? 0,
      busyDrivers: json['busyDrivers'] ?? 0,
      suspendedDrivers: json['suspendedDrivers'] ?? 0,
    );
  }
}
