class AppConstants {
  static const String appName = 'Taxi Nanban Vendor';

  static const String baseUrl = 'http://127.0.0.1:5000/api/v1';
  static const String socketUrl = 'http://127.0.0.1:5000';

  // Vendor APIs
  static const String vendorLoginUrl = '/vendor/login';
  static const String vendorRegisterUrl = '/vendor/register';
  static const String vendorSendOtpUrl = '/vendor/send-otp';
  static const String vendorVerifyOtpUrl = '/vendor/verify-otp';
  static const String vendorDashboardUrl = '/vendor/dashboard';
  static const String vendorProfileUrl = '/vendor/profile';

  // Driver APIs (Vendor)
  static const String vendorDriversUrl = '/vendor/drivers';
  static const String vendorDriverByIdUrl = '/vendor/drivers/:id';
  static const String vendorAddDriverUrl = '/vendor/drivers';
  static const String vendorUpdateDriverUrl = '/vendor/drivers/:id';
  static const String vendorDeleteDriverUrl = '/vendor/drivers/:id';

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
}
