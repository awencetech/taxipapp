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

  DriverModel({
    required this.id,
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
  });

  factory DriverModel.fromJson(Map<String, dynamic> json) {
    try {
      debugPrint('DriverModel.fromJson: Input JSON: $json');
      
      // Parse bank accounts
      List<BankAccountModel> accounts = [];
      if (json['bankAccounts'] != null && json['bankAccounts'] is List) {
        accounts = (json['bankAccounts'] as List)
            .where((item) => item is Map)
            .map((item) => BankAccountModel.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
      }
      // If no accounts in JSON, check old single fields and create one
      if (accounts.isEmpty && ((json['bankName'] != null && (json['bankName'] as String).isNotEmpty) || (json['accountNumber'] != null && (json['accountNumber'] as String).isNotEmpty))) {
        accounts = [
          BankAccountModel(
            bankName: (json['bankName'] as String?) ?? '',
            accountHolderName: (json['accountHolderName'] as String?) ?? '',
            accountNumber: (json['accountNumber'] as String?) ?? '',
            ifscCode: (json['ifscCode'] as String?) ?? '',
            branchName: (json['branchName'] as String?) ?? '',
          )
        ];
      }

      // Parse documents
      List<DocumentModel> docs = [];
      if (json['documents'] != null && json['documents'] is List) {
        docs = (json['documents'] as List)
            .where((item) => item is Map)
            .map((item) => DocumentModel.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
      }
      debugPrint('DriverModel.fromJson: Parsed ${docs.length} documents');

      final driverId = json['_id']?.toString() ?? json['id']?.toString() ?? 'unknown';
      debugPrint('DriverModel.fromJson: Extracted driverId: $driverId');
      
      final driver = DriverModel(
        id: driverId,
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
    // Handle case where json might be null or not a map
    if (json is! Map<String, dynamic>) {
      return DocumentModel(
        id: '',
        title: 'Unknown Document',
        category: 'vehicle',
        status: 'Pending',
      );
    }
    
    return DocumentModel(
      id: (json['_id']?.toString() ?? json['id']?.toString()) ?? '',
      title: (json['title'] as String?) ?? 'Unknown',
      category: (json['category'] as String?) ?? 'vehicle',
      url: (json['url'] as String?) ?? (json['filePath'] as String?), // Backward compatibility
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
    required this.status,
    this.createdAt,
  });

  factory RideRequestModel.fromJson(Map<String, dynamic> json) {
    return RideRequestModel(
      id: json['_id'] ?? json['id'] ?? '',
      passengerName: json['passengerName'] ?? json['passenger']?['name'] ?? 'Unknown',
      pickupAddress: json['pickupAddress'] ?? '',
      dropAddress: json['dropAddress'] ?? '',
      pickupCoords: (json['pickupCoords'] as List?)?.map((e) => (e as num).toDouble()).toList() ?? [0.0, 0.0],
      dropCoords: (json['dropCoords'] as List?)?.map((e) => (e as num).toDouble()).toList() ?? [0.0, 0.0],
      fare: (json['fare'] ?? 0.0).toDouble(),
      distance: (json['distance'] ?? 0.0).toDouble(),
      estimatedTime: json['estimatedTime'] ?? 0,
      status: json['status'] ?? 'pending',
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
    );
  }
}
