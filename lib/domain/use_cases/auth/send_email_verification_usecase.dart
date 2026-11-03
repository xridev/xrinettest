import 'package:xrinet/core/use_case/use_case.dart';
import 'package:xrinet/domain/repositories/auth_repository.dart';

class SendEmailVerificationUseCase implements UseCase<void, NoParams> {
  final FirebaseAuthRepository _firebaseAuthRepository;

  SendEmailVerificationUseCase(this._firebaseAuthRepository);

  @override
  Future<void> call({required NoParams params}) {
    return _firebaseAuthRepository.sendEmailVerification();
  }
}
