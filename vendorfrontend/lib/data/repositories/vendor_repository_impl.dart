import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../../domain/repositories/vendor_repository.dart';
import '../datasources/vendor_remote_datasource.dart';
import '../../models/vendor_models.dart';

class VendorRepositoryImpl implements VendorRepository {
  final VendorRemoteDataSource remoteDataSource;

  VendorRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, Vendor>> login(String email, String password) async {
    try {
      final vendor = await remoteDataSource.login(email, password);
      return Right(vendor);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Vendor>> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String companyName,
  }) async {
    try {
      final vendor = await remoteDataSource.register(
        name: name,
        email: email,
        phone: phone,
        password: password,
        companyName: companyName,
      );
      return Right(vendor);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, DashboardStats>> getDashboardData(String token) async {
    try {
      final data = await remoteDataSource.getDashboardData(token);
      return Right(data);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Driver>>> getDrivers(String token) async {
    try {
      final drivers = await remoteDataSource.getDrivers(token);
      return Right(drivers);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Vehicle>>> getVehicles(String token) async {
    try {
      final vehicles = await remoteDataSource.getVehicles(token);
      return Right(vehicles);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Trip>>> getTrips(String token) async {
    try {
      final trips = await remoteDataSource.getTrips(token);
      return Right(trips);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Earnings>> getEarnings(String token) async {
    try {
      final earnings = await remoteDataSource.getEarnings(token);
      return Right(earnings);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
