import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static String get apiBaseUrl => dotenv.env['API_BASE_URL'] ?? 'http://localhost:5000/api/v1';
  static String get socketUrl => dotenv.env['SOCKET_URL'] ?? 'http://localhost:5000';
  static String get environment => dotenv.env['ENVIRONMENT'] ?? 'development';
  static String get googleMapsApiKey => dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
  static bool get isProduction => environment == 'production';
  static bool get isDevelopment => environment == 'development';
  static bool get isStaging => environment == 'staging';
}
