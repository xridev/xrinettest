import 'package:firebase_auth/firebase_auth.dart';

class FirebaseAuthAuthentication {
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

    final user = result.user;

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

    final user = result.user;

    if (user == null) {
      throw Exception('Login failed.');
    }

    return user;
  }

  // SEND EMAIL VERIFICATION
  static Future<void> sendEmailVerification() async {
    final User? currentUser = _firebaseAuth.currentUser;

    if (currentUser == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'No signed-in user found.',
      );
    }

    await currentUser.sendEmailVerification();
  }

  // CHECK EMAIL VERIFICATION
  static Future<bool> isEmailVerified() async {
    await _firebaseAuth.currentUser?.reload();

    final User? currentUser = _firebaseAuth.currentUser;

    return currentUser?.emailVerified ?? false;
  }

  // SIGN OUT
  static Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }
}
