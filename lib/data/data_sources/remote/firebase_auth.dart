import 'package:firebase_auth/firebase_auth.dart';

class FirebaseAuthentication {
  static final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  User? get user => _firebaseAuth.currentUser;

  // SIGN UP
  static Future<User> signUp({
    required String email,
    required String password,
  }) async {
    final UserCredential result =
        await _firebaseAuth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final User? user = result.user;

    if (user == null) {
      throw Exception('User creation failed.');
    }

    return user;
  }

  // LOG IN
  static Future<User> logIn({
    required String email,
    required String password,
  }) async {
    final UserCredential result =
        await _firebaseAuth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final User? user = result.user;

    if (user == null) {
      throw Exception('Login failed.');
    }

    return user;
  }

  // SIGN OUT
  static Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }
}
