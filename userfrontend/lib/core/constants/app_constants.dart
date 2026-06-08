class AppConstants {
  // App Information
  static const String appName = 'Taxi Nanban';
  static const String appTagline = 'Your Reliable Taxi Partner';
  
  // Default Coordinates (Coimbatore, Tamil Nadu)
  static const double defaultLatitude = 11.0168;
  static const double defaultLongitude = 76.9558;
  
  // Map Settings
  static const double defaultZoom = 16.0;
  static const double minZoom = 5.0;
  static const double maxZoom = 20.0;
  
  // Animation Durations
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);
  static const Duration longAnimationDuration = Duration(milliseconds: 500);
  
  // Storage Keys
  static const String keyJwtToken = 'jwt_token';
  static const String keyUserId = 'user_id';
  static const String keyOnboardingComplete = 'onboarding_complete';
}
