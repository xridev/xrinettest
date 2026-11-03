
part of 'firebase_auth_cubit.dart';

abstract class FirebaseAuthCubitState {}

class CubitInitial extends FirebaseAuthCubitState {}

class CubitAuthConfirming extends FirebaseAuthCubitState {}

class CubitAuthConfirmed extends FirebaseAuthCubitState {
  final User user;

  CubitAuthConfirmed(this.user);
}

class CubitEmailVerificationLoaded extends FirebaseAuthCubitState {
  final String email;
  final bool isThisEmailToken;

  CubitEmailVerificationLoaded({
    required this.email,
    required this.isThisEmailToken,
  });
}

class CubitEmailVerificationLoading extends FirebaseAuthCubitState {}

class CubitEmailVerificationFailed extends FirebaseAuthCubitState {
  final String email;
  final String error;

  CubitEmailVerificationFailed({
    required this.email,
    required this.error,
  });
}

class CubitAuthSignOut extends FirebaseAuthCubitState {}

class CubitAuthFailed extends FirebaseAuthCubitState {
  final String error;

  CubitAuthFailed(this.error);
}
