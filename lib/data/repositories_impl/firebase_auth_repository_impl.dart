import 'package:firebase_auth/firebase_auth.dart';
import 'package:xrinet/data/data_sources/remote/firebase_auth.dart' as auth;
import 'package:xrinet/data/data_sources/remote/notification/firebase_notification.dart';
import 'package:xrinet/domain/entities/registered_user.dart';
import 'package:xrinet/domain/repositories/auth_repository.dart';
class FirebaseAuthRepositoryImpl implements FirebaseAuthRepository {
  @override
  Future<User> logIn(RegisteredUser userInfo) async {
    return await auth.FirebaseAuthAuthentication.logIn(
      email: userInfo.email,
      password: userInfo.password,
    );
  }

  @override
  Future<void> signOut(String userId) async {
    await auth.FirebaseAuthAuthentication.signOut();

    await FireStoreNotification.deleteDeviceToken(
      userId: userId,
    );
  }

  @override
  Future<User> signUp(RegisteredUser userInfo) async {
    return await auth.FirebaseAuthAuthentication.signUp(
      email: userInfo.email,
      password: userInfo.password,
    );
  }

  @override
  Future<void> sendEmailVerification() async {
    await auth.FirebaseAuthAuthentication.sendEmailVerification();
  }

  @override
  Future<bool> isEmailVerified() async {
    return await auth.FirebaseAuthAuthentication.isEmailVerified();
  }
}
