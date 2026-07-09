class AppConstants {
  static const String appName = 'Taxi Nanban Driver';

  // Local network backend URL
  static const String baseUrl = 'http://192.168.31.100:5000/api/v1';
  static const String socketUrl = 'http://192.168.31.100:5000';

  // Authentication APIs
  static const String loginUrl = '/auth/login';
  static const String registerUrl = '/auth/register';
  static const String googleLoginUrl = '/auth/google-login';
  static const String completeProfileUrl = '/auth/complete-profile';
  static const String changePasswordUrl = '/auth/change-password';

  // Driver APIs
  static const String driverSignupUrl = '/auth/register';
  static const String driverLoginUrl = '/auth/login';
  static const String driverRegisterUrl = '/drivers/register';
  static const String driverStatusUrl = '/driver/status';
  static const String updateLocationUrl = '/drivers/location';
  static const String driverLocationUrl = '/drivers/location';
  static const String driverEarningsUrl = '/drivers/earnings';
  static const String getDriverProfileUrl = '/drivers/profile';
  static const String updateDriverProfileUrl = '/drivers/profile';
  static const String driverProfileCreateUrl = '/driver/profile/create';
  static const String uploadDocumentUrl = '/drivers/documents';
  static const String editDocumentUrl = '/drivers/documents/:docId';
  static const String deleteDocumentUrl = '/drivers/documents/:docId';

  // Ride APIs
  static const String nearbyRidesUrl = '/rides/nearby';
  static const String driverAcceptRideUrl = '/ride/accept';
  static const String driverRejectRideUrl = '/ride/reject';
  static const String driverArrivedUrl = '/ride/arrived';
  static const String driverStartTripUrl = '/ride/start';
  static const String driverCompleteTripUrl = '/ride/complete';
  static const String driverCurrentRideUrl = '/rides/driver/current-ride';
  static const String pendingRidesUrl = '/driver/pending-rides';
  static const String driverHistoryUrl = '/rides/driver/history';
  static const String driverRidesUrl = '/rides/driver/my-rides';

  // Notification APIs
  static const String notificationsUrl = '/drivers/notifications';
  static const String markNotificationReadUrl =
      '/drivers/notifications/:id/read';
  static const String deleteNotificationUrl = '/drivers/notifications/:id';
  static const String markAllNotificationsReadUrl =
      '/drivers/notifications/mark-all-read';

  // Support Ticket APIs
  static const String createSupportTicketsUrl = '/support-tickets';
  static const String mySupportTicketsUrl = '/support-tickets/my-tickets';
  static const String supportTicketUrl = '/support-tickets/:id';
  static const String supportTicketMessagesUrl =
      '/support-tickets/:id/messages';

  static const String tokenKey = 'driver_jwt_token';
  static const String driverIdKey = 'driver_id';
  static const String isOnlineKey = 'is_online';
}
