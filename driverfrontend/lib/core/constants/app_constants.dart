class AppConstants {
  static const String appName = 'Taxi Nanban Driver';

  static const String baseUrl = 'http://127.0.0.1:5000/api/v1';
  static const String socketUrl = 'http://127.0.0.1:5000';

  // Authentication APIs
  static const String loginUrl = '/auth/login';
  static const String registerUrl = '/auth/register';
  static const String googleLoginUrl = '/auth/google-login';
  static const String completeProfileUrl = '/auth/complete-profile';

  // Driver APIs
  static const String driverSignupUrl = '/driver/signup';
  static const String driverLoginUrl = '/driver/login';
  static const String driverRegisterUrl = '/drivers/register';
  static const String driverStatusUrl = '/drivers/status';
  static const String updateLocationUrl = '/drivers/location';
  static const String driverLocationUrl = '/drivers/location';
  static const String driverEarningsUrl = '/drivers/earnings';
  static const String getDriverProfileUrl = '/drivers/profile';
  static const String updateDriverProfileUrl = '/drivers/profile';
  static const String driverProfileCreateUrl = '/driver/profile/create';

  static const String nearbyRidesUrl = '/rides/nearby';
  static const String acceptRideUrl = '/rides/accept';
  static const String rejectRideUrl = '/rides/reject';
  static const String startTripUrl = '/trip/start';
  static const String endTripUrl = '/trip/end';
  static const String driverRidesUrl = '/drivers/rides';

  // Notification APIs
  static const String notificationsUrl = '/drivers/notifications';
  static const String markNotificationReadUrl =
      '/drivers/notifications/:id/read';
  static const String deleteNotificationUrl = '/drivers/notifications/:id';
  static const String markAllNotificationsReadUrl =
      '/drivers/notifications/mark-all-read';

  static const String tokenKey = 'driver_jwt_token';
  static const String driverIdKey = 'driver_id';
  static const String isOnlineKey = 'is_online';
}
