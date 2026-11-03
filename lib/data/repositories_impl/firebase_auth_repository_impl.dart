import 'package:firebase_auth/firebase_auth.dart';
import 'package:xrinet/data/data_sources/remote/notification/firebase_notification.dart';
import 'package:xrinet/domain/entities/registered_user.dart';
import 'package:xrinet/domain/repositories/auth_repository.dart';

import '../data_sources/remote/firebase_auth.dart';

class FirebaseAuthRepositoryImpl implements FirebaseAuthRepository {
  @override
  Future<User> logIn(RegisteredUser userInfo) async {
    try {
      return await FirebaseAuthentication.logIn(
        email: userInfo.email,
        password: userInfo.password,
      );
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> signOut({required String userId}) async {
    try {
      await FirebaseAuthentication.signOut();

      await FireStoreNotification.deleteDeviceToken(
        userId: userId,
      );
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<User> signUp(RegisteredUser newUserInfo) async {
    try {
      return await FirebaseAuthentication.signUp(
        email: newUserInfo.email,
        password: newUserInfo.password,
      );
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<bool> isEmailVerified() async {
    try {
      return await FirebaseAuthentication.isEmailVerified();
    } catch (e) {
      rethrow;
    }
  }
}
