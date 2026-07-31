import 'package:flutter/foundation.dart';

class AppConstants {
  static const String appName = 'Taxi Nanban Vendor';

  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:5003/api/v1';
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:5003/api/v1';
    }
    return 'http://localhost:5003/api/v1';
  }

  static String get socketUrl {
    if (kIsWeb) {
      return 'http://localhost:5003';
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:5003';
    }
    return 'http://localhost:5003';
  }

  // Vendor APIs
  static const String vendorLoginUrl = '/vendor/login';
  static const String vendorRegisterUrl = '/vendor/register';
  static const String vendorSendOtpUrl = '/vendor/send-otp';
  static const String vendorVerifyOtpUrl = '/vendor/verify-otp';
  static const String vendorRefreshApprovalUrl = '/vendor/refresh-approval';
  static const String vendorDashboardUrl = '/vendor/dashboard';
  static const String vendorProfileUrl = '/vendor/profile';

  // Driver APIs (Vendor)
  static const String vendorDriversUrl = '/vendor/drivers';
  static const String vendorPendingDriversUrl = '/vendor/drivers/pending';
  static const String vendorDriverByIdUrl = '/vendor/drivers/:id';
  static const String vendorAddDriverUrl = '/vendor/drivers';
  static const String vendorUpdateDriverUrl = '/vendor/drivers/:id';
  static const String vendorDeleteDriverUrl = '/vendor/drivers/:id';
  static const String vendorApproveDriverUrl = '/vendor/drivers/:id/approve';
  static const String vendorRejectDriverUrl = '/vendor/drivers/:id/reject';

  // Vehicle APIs (Vendor)
  static const String vendorVehiclesUrl = '/vendor/vehicles';
  static const String vendorAddVehicleUrl = '/vendor/vehicles';
  static const String vendorUpdateVehicleUrl = '/vendor/vehicles/:id';
  static const String vendorDeleteVehicleUrl = '/vendor/vehicles/:id';

  // Trip APIs (Vendor)
  static const String vendorTripsUrl = '/vendor/trips';
  static const String vendorTripDetailsUrl = '/vendor/trips/:id';

  // Earnings APIs (Vendor)
  static const String vendorEarningsUrl = '/vendor/earnings';

  // Notification APIs (Vendor)
  static const String vendorNotificationsUrl = '/vendor/notifications';

  static const String tokenKey = 'vendor_jwt_token';
  static const String vendorIdKey = 'vendor_id';
  static const String vendorEmailKey = 'vendor_email';
  static const String vendorPhoneKey = 'vendor_phone';
}
