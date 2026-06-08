import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import '../../data/datasources/vendor_remote_datasource.dart';
import '../../data/repositories/vendor_repository_impl.dart';
import '../../domain/repositories/vendor_repository.dart';
import '../../domain/usecases/login_usecase.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // Use Cases
  sl.registerLazySingleton(() => LoginUseCase(repository: sl()));

  // Repositories
  sl.registerLazySingleton<VendorRepository>(
    () => VendorRepositoryImpl(remoteDataSource: sl()),
  );

  // Data Sources
  sl.registerLazySingleton<VendorRemoteDataSource>(
    () => VendorRemoteDataSourceImpl(dio: sl()),
  );

  // External
  sl.registerLazySingleton(() => Dio());
}
