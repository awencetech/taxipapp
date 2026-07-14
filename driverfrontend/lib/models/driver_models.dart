import 'package:flutter/foundation.dart';

class BankAccountModel {
  final String bankName;
  final String accountHolderName;
  final String accountNumber;
  final String ifscCode;
  final String branchName;

  BankAccountModel({
    required this.bankName,
    required this.accountHolderName,
    required this.accountNumber,
    required this.ifscCode,
    this.branchName = '',
  });

  factory BankAccountModel.fromJson(Map<String, dynamic> json) {
    return BankAccountModel(
      bankName: json['bankName'] ?? '',
      accountHolderName: json['accountHolderName'] ?? '',
      accountNumber: json['accountNumber'] ?? '',
      ifscCode: json['ifscCode'] ?? '',
      branchName: json['branchName'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bankName': bankName,
      'accountHolderName': accountHolderName,
      'accountNumber': accountNumber,
      'ifscCode': ifscCode,
      'branchName': branchName,
    };
  }
}

class DriverModel {
  final String id;
  final String? driverId;
  final String name;
  final String email;
  final String mobile;
  final String vehicleType;
  final String vehicleNumber;
  final String address;
  final bool isOnline;
  final String? profilePic;
  final double rating;
  // Bank Details (backward compatibility)
  final String bankName;
  final String accountHolderName;
  final String accountNumber;
  final String ifscCode;
  final String branchName;
  // New: Multiple bank accounts
  final List<BankAccountModel> bankAccounts;
  // New: Documents
  final List<DocumentModel> documents;
  // New: Stats
  final int totalTrips;
  final int completedTrips;
  final int acceptanceRate;
  final int onTimePercentage;
  final DateTime? memberSince;
  // New: Approval status fields
  final String? status;
  final String? approvalStatus;
  final String? rejectionReason;

  DriverModel({
    required this.id,
    this.driverId,
    required this.name,
    required this.email,
    required this.mobile,
    required this.vehicleType,
    required this.vehicleNumber,
    this.address = '',
    required this.isOnline,
    this.profilePic,
    this.rating = 0.0,
    this.bankName = '',
    this.accountHolderName = '',
    this.accountNumber = '',
    this.ifscCode = '',
    this.branchName = '',
    this.bankAccounts = const [],
    this.documents = const [],
    this.totalTrips = 0,
    this.completedTrips = 0,
    this.acceptanceRate = 100,
    this.onTimePercentage = 96,
    this.memberSince,
    this.status,
    this.approvalStatus,
    this.rejectionReason,
  });

  factory DriverModel.fromJson(Map<String, dynamic> json) {
    try {
      debugPrint('DriverModel.fromJson: Input JSON: $json');

      // Parse bank accounts
      List<BankAccountModel> accounts = [];
      if (json['bankAccounts'] != null && json['bankAccounts'] is List) {
        accounts = (json['bankAccounts'] as List)
            .whereType<Map>()
            .map(
              (item) =>
                  BankAccountModel.fromJson(Map<String, dynamic>.from(item)),
            )
            .toList();
      }
      // If no accounts in JSON, check old single fields and create one
      if (accounts.isEmpty &&
          ((json['bankName'] != null &&
                  (json['bankName'] as String).isNotEmpty) ||
              (json['accountNumber'] != null &&
                  (json['accountNumber'] as String).isNotEmpty))) {
        accounts = [
          BankAccountModel(
            bankName: (json['bankName'] as String?) ?? '',
            accountHolderName: (json['accountHolderName'] as String?) ?? '',
            accountNumber: (json['accountNumber'] as String?) ?? '',
            ifscCode: (json['ifscCode'] as String?) ?? '',
            branchName: (json['branchName'] as String?) ?? '',
          ),
        ];
      }

      // Parse documents
      List<DocumentModel> docs = [];
      if (json['documents'] != null && json['documents'] is List) {
        docs = (json['documents'] as List)
            .whereType<Map>()
            .map(
              (item) => DocumentModel.fromJson(Map<String, dynamic>.from(item)),
            )
            .toList();
      }
      debugPrint('DriverModel.fromJson: Parsed ${docs.length} documents');

      final driverIdFromJson =
          json['_id']?.toString() ?? json['id']?.toString() ?? 'unknown';
      debugPrint('DriverModel.fromJson: Extracted driverId: $driverIdFromJson');

      final driver = DriverModel(
        id: driverIdFromJson,
        driverId: json['driverId'] as String?,
        name: (json['name'] as String?) ?? 'Unknown Driver',
        email: (json['email'] as String?) ?? '',
        mobile: (json['mobile'] as String?) ?? '',
        vehicleType: (json['vehicleType'] as String?) ?? 'Car',
        vehicleNumber: (json['vehicleNumber'] as String?) ?? 'TN 01 AB 1234',
        address: (json['address'] as String?) ?? '',
        isOnline: (json['isOnline'] as bool?) ?? false,
        profilePic: json['profilePic'] as String?,
        rating: _parseRating(json['ratings'] ?? json['rating']),
        // Backward compatibility fields
        bankName: (json['bankName'] as String?) ?? '',
        accountHolderName: (json['accountHolderName'] as String?) ?? '',
        accountNumber: (json['accountNumber'] as String?) ?? '',
        ifscCode: (json['ifscCode'] as String?) ?? '',
        branchName: (json['branchName'] as String?) ?? '',
        // New multiple accounts
        bankAccounts: accounts,
        // New documents
        documents: docs,
        // New stats
        totalTrips: (json['totalTrips'] as num?)?.toInt() ?? 0,
        completedTrips: (json['completedTrips'] as num?)?.toInt() ?? 0,
        acceptanceRate: (json['acceptanceRate'] as num?)?.toInt() ?? 100,
        onTimePercentage: (json['onTimePercentage'] as num?)?.toInt() ?? 96,
        memberSince: json['memberSince'] != null
            ? DateTime.tryParse(json['memberSince'].toString())
            : null,
        // New approval fields
        status: json['status'] as String?,
        approvalStatus: json['approvalStatus'] as String?,
        rejectionReason: json['rejectionReason'] as String?,
      );

      debugPrint('DriverModel.fromJson: Successfully created DriverModel!');
      return driver;
    } catch (e, stackTrace) {
      debugPrint('DriverModel.fromJson: ERROR CAUGHT!');
      debugPrint('DriverModel.fromJson: Error: $e');
      debugPrint('DriverModel.fromJson: Stack trace: $stackTrace');
      // Return a fallback model instead of crashing
      return DriverModel(
        id: json['_id']?.toString() ?? json['id']?.toString() ?? 'unknown',
        name: json['name']?.toString() ?? 'Unknown Driver',
        email: json['email']?.toString() ?? '',
        mobile: json['mobile']?.toString() ?? '',
        vehicleType: 'Car',
        vehicleNumber: '',
        isOnline: false,
      );
    }
  }

  static double _parseRating(dynamic rating) {
    if (rating == null) return 0.0;
    if (rating is num) return rating.toDouble();
    if (rating is String) return double.tryParse(rating) ?? 0.0;
    return 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'driverId': driverId,
      'name': name,
      'email': email,
      'mobile': mobile,
      'vehicleType': vehicleType,
      'vehicleNumber': vehicleNumber,
      'address': address,
      'isOnline': isOnline,
      'profilePic': profilePic,
      'rating': rating,
      'bankName': bankName,
      'accountHolderName': accountHolderName,
      'accountNumber': accountNumber,
      'ifscCode': ifscCode,
      'branchName': branchName,
      'bankAccounts': bankAccounts.map((e) => e.toJson()).toList(),
      'documents': documents.map((e) => e.toJson()).toList(),
      'status': status,
      'approvalStatus': approvalStatus,
      'rejectionReason': rejectionReason,
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

class DocumentModel {
  final String id;
  final String title;
  final String category; // 'vehicle' or 'personal'
  final String? url;
  final String status; // 'Verified', 'Pending', 'Expiring Soon', 'Rejected'
  final DateTime? uploadedAt;
  final DateTime? expiryDate;

  DocumentModel({
    required this.id,
    required this.title,
    required this.category,
    this.url,
    required this.status,
    this.uploadedAt,
    this.expiryDate,
  });

  factory DocumentModel.fromJson(Map<String, dynamic> json) {
    debugPrint('Parsing DocumentModel from: $json');

    return DocumentModel(
      id: (json['_id']?.toString() ?? json['id']?.toString()) ?? '',
      title: (json['title'] as String?) ?? 'Unknown',
      category: (json['category'] as String?) ?? 'vehicle',
      url:
          (json['url'] as String?) ??
          (json['filePath'] as String?), // Backward compatibility
      status: (json['status'] as String?) ?? 'Pending',
      uploadedAt: json['uploadedAt'] != null
          ? DateTime.tryParse(json['uploadedAt'].toString())
          : null,
      expiryDate: json['expiryDate'] != null
          ? DateTime.tryParse(json['expiryDate'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'url': url,
      'status': status,
      'uploadedAt': uploadedAt?.toIso8601String(),
      'expiryDate': expiryDate?.toIso8601String(),
    };
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
  final String vehicleType;
  final String paymentMethod;
  final DateTime? createdAt;
  final String? cancellationReason;
  final String?
  polyline; // New: to store the route polyline from user's booking

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
    required this.status,
    this.vehicleType = 'Auto',
    this.paymentMethod = 'Cash',
    this.createdAt,
    this.cancellationReason,
    this.polyline,
  });

  factory RideRequestModel.fromJson(Map<String, dynamic> json) {
    // Parse pickup coords from location object (from backend)
    List<double> pickupCoords = [0.0, 0.0];
    if (json['pickupLocation']?['coordinates'] != null &&
        json['pickupLocation']['coordinates'] is List) {
      final coords = json['pickupLocation']['coordinates'] as List;
      if (coords.length >= 2) {
        pickupCoords = [
          (coords[1] as num?)?.toDouble() ?? 0.0,
          (coords[0] as num?)?.toDouble() ?? 0.0,
        ];
      }
    }

    // Parse drop coords
    List<double> dropCoords = [0.0, 0.0];
    if (json['dropLocation']?['coordinates'] != null &&
        json['dropLocation']['coordinates'] is List) {
      final coords = json['dropLocation']['coordinates'] as List;
      if (coords.length >= 2) {
        dropCoords = [
          (coords[1] as num?)?.toDouble() ?? 0.0,
          (coords[0] as num?)?.toDouble() ?? 0.0,
        ];
      }
    }

    // Get passenger name from user object
    String passengerName = 'Unknown';
    if (json['user'] != null && json['user'] is Map) {
      passengerName = json['user']['name'] ?? 'Unknown';
    }

    return RideRequestModel(
      id: json['_id'] ?? json['id'] ?? '',
      passengerName: passengerName,
      pickupAddress: json['pickupLocation']?['address'] ?? '',
      dropAddress: json['dropLocation']?['address'] ?? '',
      pickupCoords: pickupCoords,
      dropCoords: dropCoords,
      fare: (json['fare'] as num?)?.toDouble() ?? 0.0,
      distance: (json['distance'] as num?)?.toDouble() ?? 0.0,
      estimatedTime: (json['duration'] as num?)?.toInt() ?? 0,
      status: json['status'] ?? 'pending',
      vehicleType: json['vehicleType'] ?? 'Auto',
      paymentMethod: json['paymentMethod'] ?? 'Cash',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      cancellationReason: json['cancellationReason'],
      polyline: json['polyline']?.toString(),
    );
  }
}

class TicketMessageModel {
  final String senderId;
  final String message;
  final DateTime timestamp;

  TicketMessageModel({
    required this.senderId,
    required this.message,
    required this.timestamp,
  });

  factory TicketMessageModel.fromJson(Map<String, dynamic> json) {
    return TicketMessageModel(
      senderId: json['sender']?.toString() ?? '',
      message: json['message'] ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sender': senderId,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

class SupportTicketModel {
  final String id;
  final String? ticketId;
  final String userId;
  final String? rideId;
  final String category;
  final String subject;
  final String description;
  final String priority;
  final String status;
  final DateTime? createdAt;
  final List<TicketMessageModel> messages;

  SupportTicketModel({
    required this.id,
    this.ticketId,
    required this.userId,
    this.rideId,
    required this.category,
    required this.subject,
    required this.description,
    required this.priority,
    required this.status,
    this.createdAt,
    this.messages = const [],
  });

  factory SupportTicketModel.fromJson(Map<String, dynamic> json) {
    List<TicketMessageModel> messages = [];
    if (json['messages'] != null && json['messages'] is List) {
      messages = (json['messages'] as List)
          .whereType<Map>()
          .map(
            (item) =>
                TicketMessageModel.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList();
    }

    return SupportTicketModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      ticketId: json['ticketId']?.toString(),
      userId: json['user']?.toString() ?? json['userId']?.toString() ?? '',
      rideId: json['ride']?.toString() ?? json['rideId']?.toString(),
      category: json['category']?.toString() ?? 'Other',
      subject: json['subject']?.toString() ?? json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      priority: json['priority']?.toString() ?? 'Medium',
      status: json['status']?.toString() ?? 'Open',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      messages: messages,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ticketId': ticketId,
      'userId': userId,
      'rideId': rideId,
      'category': category,
      'subject': subject,
      'description': description,
      'priority': priority,
      'status': status,
      'createdAt': createdAt?.toIso8601String(),
      'messages': messages.map((e) => e.toJson()).toList(),
    };
  }
}
