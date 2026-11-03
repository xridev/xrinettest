import 'package:firebase_auth/firebase_auth.dart';
import 'package:xrinet/domain/entities/registered_user.dart';

abstract class FirebaseAuthRepository {
  Future<User> signUp(RegisteredUser userInfo);

  Future<User> logIn(RegisteredUser userInfo);

  Future<void> signOut(String userId);

  Future<void> sendEmailVerification();
  Future<bool> isEmailVerified();
}
