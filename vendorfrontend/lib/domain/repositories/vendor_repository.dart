import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../../models/vendor_models.dart';

abstract class VendorRepository {
  Future<Either<Failure, Vendor>> login(String email, String password);
  Future<Either<Failure, Vendor>> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String companyName,
  });
  Future<Either<Failure, DashboardStats>> getDashboardData(String token);
  Future<Either<Failure, List<Driver>>> getDrivers(String token);
  Future<Either<Failure, List<Vehicle>>> getVehicles(String token);
  Future<Either<Failure, List<Trip>>> getTrips(String token);
  Future<Either<Failure, Earnings>> getEarnings(String token);
}
