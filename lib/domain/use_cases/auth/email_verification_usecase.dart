import 'package:xrinet/core/use_case/use_case.dart';
import 'package:xrinet/domain/repositories/auth_repository.dart';

class EmailVerificationUseCase
    implements UseCase<bool, NoParams> {
  final FirebaseAuthRepository _firebaseAuthRepository;

  EmailVerificationUseCase(this._firebaseAuthRepository);

  @override
  Future<bool> call({required NoParams params}) {
    return _firebaseAuthRepository.isEmailVerified();
  }
}
