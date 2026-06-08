import 'package:dio/dio.dart';
import '../../core/config/app_config.dart';
import '../../models/vendor_models.dart';

abstract class VendorRemoteDataSource {
  Future<Vendor> login(String email, String password);
  Future<Vendor> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String companyName,
  });
  Future<DashboardStats> getDashboardData(String token);
  Future<List<Driver>> getDrivers(String token);
  Future<List<Vehicle>> getVehicles(String token);
  Future<List<Trip>> getTrips(String token);
  Future<Earnings> getEarnings(String token);
}

class VendorRemoteDataSourceImpl implements VendorRemoteDataSource {
  final Dio dio;

  VendorRemoteDataSourceImpl({required this.dio}) {
    dio.options.baseUrl = AppConfig.apiBaseUrl;
    dio.options.connectTimeout = const Duration(seconds: 30);
    dio.options.receiveTimeout = const Duration(seconds: 30);
  }

  @override
  Future<Vendor> login(String email, String password) async {
    try {
      final response = await dio.post(
        '/vendor/login',
        data: {'email': email, 'password': password},
      );

      if (response.statusCode == 200) {
        return Vendor.fromJson(response.data['vendor']);
      } else {
        throw Exception(response.data['message'] ?? 'Login failed');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? e.message);
    }
  }

  @override
  Future<Vendor> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String companyName,
  }) async {
    try {
      final response = await dio.post(
        '/vendor/register',
        data: {
          'name': name,
          'email': email,
          'phone': phone,
          'password': password,
          'companyName': companyName,
        },
      );

      if (response.statusCode == 201) {
        return Vendor.fromJson(response.data['vendor']);
      } else {
        throw Exception(response.data['message'] ?? 'Registration failed');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? e.message);
    }
  }

  @override
  Future<DashboardStats> getDashboardData(String token) async {
    try {
      final response = await dio.get(
        '/vendor/dashboard',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        return DashboardStats.fromJson(response.data);
      } else {
        throw Exception('Failed to load dashboard');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? e.message);
    }
  }

  @override
  Future<List<Driver>> getDrivers(String token) async {
    try {
      final response = await dio.get(
        '/vendor/drivers',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        return (response.data as List)
            .map((json) => Driver.fromJson(json))
            .toList();
      } else {
        throw Exception('Failed to load drivers');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? e.message);
    }
  }

  @override
  Future<List<Vehicle>> getVehicles(String token) async {
    try {
      final response = await dio.get(
        '/vendor/vehicles',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        return (response.data as List)
            .map((json) => Vehicle.fromJson(json))
            .toList();
      } else {
        throw Exception('Failed to load vehicles');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? e.message);
    }
  }

  @override
  Future<List<Trip>> getTrips(String token) async {
    try {
      final response = await dio.get(
        '/vendor/trips',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        return (response.data as List)
            .map((json) => Trip.fromJson(json))
            .toList();
      } else {
        throw Exception('Failed to load trips');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? e.message);
    }
  }

  @override
  Future<Earnings> getEarnings(String token) async {
    try {
      final response = await dio.get(
        '/vendor/earnings',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        return Earnings.fromJson(response.data);
      } else {
        throw Exception('Failed to load earnings');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? e.message);
    }
  }
}
