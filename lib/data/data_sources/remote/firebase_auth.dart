
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseAuthentication {
  static final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  User? get user => _firebaseAuth.currentUser;

  static Future<User> signUp({
    required String email,
    required String password,
  }) async {
    final UserCredential result =
        await _firebaseAuth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final user = result.user;

    if (user == null) {
      throw Exception('User creation failed.');
    }

    return user;
  }

  static Future<User> logIn({
    required String email,
    required String password,
  }) async {
    final UserCredential result =
        await _firebaseAuth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final user = result.user;

    if (user == null) {
      throw Exception('Login failed.');
    }

    return user;
  }

  static Future<bool> isThisEmailToken({
    required String email,
  }) async {
    final normalizedEmail = email.trim();

    if (normalizedEmail.isEmpty) {
      return false;
    }

    try {
      final methods = await _firebaseAuth.fetchSignInMethodsForEmail(
        normalizedEmail,
      );

      return methods.isNotEmpty;
    } on FirebaseAuthException {
      rethrow;
    }
  }

  static Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }
}
