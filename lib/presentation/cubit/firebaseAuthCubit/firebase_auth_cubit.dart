import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:xrinet/domain/entities/registered_user.dart';
import 'package:xrinet/domain/use_cases/auth/log_in_auth_usecase.dart';
import '../../../domain/use_cases/auth/sign_out_auth_usecase.dart';
import '../../../domain/use_cases/auth/sign_up_auth_usecase.dart';

part 'firebase_auth_state.dart';

class FirebaseAuthCubit extends Cubit<FirebaseAuthCubitState> {
  final SignUpAuthUseCase signUpAuthUseCase;
  final LogInAuthUseCase logInAuthUseCase;
  final SignOutAuthUseCase signOutAuthUseCase;

  User? user;

  FirebaseAuthCubit(
    this.signUpAuthUseCase,
    this.logInAuthUseCase,
    this.signOutAuthUseCase,
  ) : super(CubitInitial());

  static FirebaseAuthCubit get(BuildContext context) =>
      BlocProvider.of<FirebaseAuthCubit>(context);

  // SIGN UP
  Future<User?> signUp(RegisteredUser newUserInfo) async {
    emit(CubitAuthConfirming());

    try {
      final newUser = await signUpAuthUseCase(
        params: newUserInfo,
      );

      user = newUser;

      emit(CubitAuthConfirmed(newUser));

      return newUser;
    } on FirebaseAuthException catch (e, stackTrace) {
      debugPrint('SIGNUP ERROR CODE: ${e.code}');
      debugPrint('SIGNUP ERROR MESSAGE: ${e.message}');
      debugPrintStack(stackTrace: stackTrace);

      emit(CubitAuthFailed(e.code));

      return null;
    } catch (e, stackTrace) {
      debugPrint('SIGNUP ERROR: $e');
      debugPrintStack(stackTrace: stackTrace);

      emit(CubitAuthFailed(e.toString()));

      return null;
    }
  }

  // LOG IN
  Future<void> logIn(RegisteredUser userInfo) async {
    emit(CubitAuthConfirming());

    try {
      final loggedInUser = await logInAuthUseCase(
        params: userInfo,
      );

      user = loggedInUser;

      emit(CubitAuthConfirmed(loggedInUser));
    } on FirebaseAuthException catch (e, stackTrace) {
      debugPrint('LOGIN ERROR CODE: ${e.code}');
      debugPrint('LOGIN ERROR MESSAGE: ${e.message}');
      debugPrintStack(stackTrace: stackTrace);

      emit(CubitAuthFailed(e.code));
    } catch (e, stackTrace) {
      debugPrint('LOGIN ERROR: $e');
      debugPrintStack(stackTrace: stackTrace);

      emit(CubitAuthFailed(e.toString()));
    }
  }

  // SIGN OUT
  Future<void> signOut({required String userId}) async {
    emit(CubitAuthConfirming());

    try {
      await signOutAuthUseCase.call(params: userId);

      user = null;

      emit(CubitAuthSignOut());
    } catch (e, stackTrace) {
      debugPrint('SIGN OUT ERROR: $e');
      debugPrintStack(stackTrace: stackTrace);

      emit(CubitAuthFailed(e.toString()));
    }
  }
}
