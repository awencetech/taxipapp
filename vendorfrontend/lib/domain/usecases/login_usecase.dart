import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../../core/usecases/usecase.dart';
import '../repositories/vendor_repository.dart';
import '../../models/vendor_models.dart';

class LoginParams {
  final String email;
  final String password;

  LoginParams({required this.email, required this.password});
}

class LoginUseCase implements UseCase<Vendor, LoginParams> {
  final VendorRepository repository;

  LoginUseCase({required this.repository});

  @override
  Future<Either<Failure, Vendor>> call(LoginParams params) async {
    return await repository.login(params.email, params.password);
  }
}
