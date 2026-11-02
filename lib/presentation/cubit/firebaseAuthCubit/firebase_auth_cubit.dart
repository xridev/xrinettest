import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:instagram/domain/entities/registered_user.dart';
import 'package:instagram/domain/use_cases/auth/email_verification_usecase.dart';
import 'package:instagram/domain/use_cases/auth/log_in_auth_usecase.dart';
import '../../../domain/use_cases/auth/sign_out_auth_usecase.dart';
import '../../../domain/use_cases/auth/sign_up_auth_usecase.dart';
part 'firebase_auth_state.dart';

class FirebaseAuthCubit extends Cubit<FirebaseAuthCubitState> {
  SignUpAuthUseCase signUpAuthUseCase;
  LogInAuthUseCase logInAuthUseCase;
  SignOutAuthUseCase signOutAuthUseCase;
  EmailVerificationUseCase emailVerificationUseCase;
  User? user;

  FirebaseAuthCubit(this.signUpAuthUseCase, this.logInAuthUseCase,
      this.emailVerificationUseCase, this.signOutAuthUseCase)
      : super(CubitInitial());

  static FirebaseAuthCubit get(BuildContext context) =>
      BlocProvider.of(context);

  Future<User?> signUp(RegisteredUser newUserInfo) async {
    emit(CubitAuthConfirming());
    try {
      var newUser = await signUpAuthUseCase(params: newUserInfo);
      emit(CubitAuthConfirmed(newUser));
      user = newUser;
    } catch (e) {
      print("SIGNUP ERROR EXCEPTION: $e"); // Codemagic log-e asol error dekhar jonno
      emit(CubitAuthFailed(e.toString()));
    }
    return user;
  }

  Future<void> logIn(RegisteredUser userInfo) async {
    emit(CubitAuthConfirming());
    try {
      var user = await logInAuthUseCase(params: userInfo);
      emit(CubitAuthConfirmed(user));
      this.user = user;
    } catch (e) {
      print("LOGIN ERROR EXCEPTION: $e");
      emit(CubitAuthFailed(e.toString()));
    }
  }

  Future<void> signOut({required String userId}) async {
    emit(CubitAuthConfirming());
    try {
      await signOutAuthUseCase.call(params: userId);
      emit(CubitAuthSignOut());
    } catch (e) {
      emit(CubitAuthFailed(e.toString()));
    }
  }

  Future<void> isThisEmailToken({required String email}) async {
    if (email.isEmpty) return;

    emit(CubitEmailVerificationLoading());
    try {
      var value = await emailVerificationUseCase.call(params: email);
      emit(CubitEmailVerificationLoaded(value));
    } catch (e) {
      // ekhane unnecessary error emission avoid korar jonno print rakha holo
      print("EMAIL CHECK ERROR: $e");
      // Jode email verification fail korle sign up block na korte chan, eta handle korte paren
    }
  }
}
