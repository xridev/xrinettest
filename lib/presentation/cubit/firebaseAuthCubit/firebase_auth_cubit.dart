
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xrinet/domain/entities/registered_user.dart';
import 'package:xrinet/domain/use_cases/auth/email_verification_usecase.dart';
import 'package:xrinet/domain/use_cases/auth/log_in_auth_usecase.dart';
import '../../../domain/use_cases/auth/sign_out_auth_usecase.dart';
import '../../../domain/use_cases/auth/sign_up_auth_usecase.dart';

part 'firebase_auth_state.dart';

class FirebaseAuthCubit extends Cubit<FirebaseAuthCubitState> {
  SignUpAuthUseCase signUpAuthUseCase;
  LogInAuthUseCase logInAuthUseCase;
  SignOutAuthUseCase signOutAuthUseCase;
  EmailVerificationUseCase emailVerificationUseCase;

  User? user;

  // Prevents old email requests from overwriting newer results.
  int _emailCheckRequestId = 0;

  FirebaseAuthCubit(
    this.signUpAuthUseCase,
    this.logInAuthUseCase,
    this.emailVerificationUseCase,
    this.signOutAuthUseCase,
  ) : super(CubitInitial());

  static FirebaseAuthCubit get(BuildContext context) =>
      BlocProvider.of(context);

  Future<User?> signUp(RegisteredUser newUserInfo) async {
    emit(CubitAuthConfirming());

    try {
      final newUser = await signUpAuthUseCase(params: newUserInfo);

      user = newUser;
      emit(CubitAuthConfirmed(newUser));

      return newUser;
    } catch (e) {
      debugPrint('SIGNUP ERROR: $e');
      emit(CubitAuthFailed(e.toString()));
      return null;
    }
  }

  Future<void> logIn(RegisteredUser userInfo) async {
    emit(CubitAuthConfirming());

    try {
      final loggedInUser = await logInAuthUseCase(params: userInfo);

      user = loggedInUser;
      emit(CubitAuthConfirmed(loggedInUser));
    } catch (e) {
      debugPrint('LOGIN ERROR: $e');
      emit(CubitAuthFailed(e.toString()));
    }
  }

  Future<void> signOut({required String userId}) async {
    emit(CubitAuthConfirming());

    try {
      await signOutAuthUseCase.call(params: userId);
      user = null;
      emit(CubitAuthSignOut());
    } catch (e) {
      emit(CubitAuthFailed(e.toString()));
    }
  }

  Future<void> isThisEmailToken({
    required String email,
  }) async {
    final normalizedEmail = email.trim();

    // Invalidate any previous request.
    final requestId = ++_emailCheckRequestId;

    if (normalizedEmail.isEmpty) return;

    emit(CubitEmailVerificationLoading());

    try {
      final value = await emailVerificationUseCase.call(
        params: normalizedEmail,
      );

      // Ignore outdated responses.
      if (requestId != _emailCheckRequestId) return;

      emit(
        CubitEmailVerificationLoaded(
          email: normalizedEmail,
          isThisEmailToken: value,
        ),
      );
    } catch (e) {
      if (requestId != _emailCheckRequestId) return;

      debugPrint('EMAIL CHECK ERROR: $e');

      emit(
        CubitEmailVerificationFailed(
          email: normalizedEmail,
          error: e.toString(),
        ),
      );
    }
  }
}
