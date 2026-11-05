import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xrinet/domain/use_cases/follow/follow_this_user.dart';
import 'package:xrinet/domain/use_cases/follow/remove_this_follower.dart';
part 'follow_state.dart';

class FollowCubit extends Cubit<FollowState> {
  FollowThisUserUseCase followThisUserUseCase;
  UnFollowThisUserUseCase unFollowThisUserUseCase;
  FollowCubit(this.followThisUserUseCase, this.unFollowThisUserUseCase)
    : super(FollowInitial());

  static FollowCubit get(BuildContext context) => BlocProvider.of(context);

  Future<bool> followThisUser({
    required String followingUserId,
    required String myPersonalId,
  }) async {
    emit(CubitFollowThisUserLoading());
    try {
      await followThisUserUseCase.call(
        paramsOne: followingUserId,
        paramsTwo: myPersonalId,
      );
      emit(CubitFollowThisUserLoaded());
      return true;
    } catch (e) {
      emit(CubitFollowThisUserFailed(e.toString()));
      return false;
    }
  }

  Future<bool> unFollowThisUser({
    required String followingUserId,
    required String myPersonalId,
  }) async {
    emit(CubitFollowThisUserLoading());
    try {
      await unFollowThisUserUseCase.call(
        paramsOne: followingUserId,
        paramsTwo: myPersonalId,
      );
      emit(CubitFollowThisUserLoaded());
      return true;
    } catch (e) {
      emit(CubitFollowThisUserFailed(e.toString()));
      return false;
    }
  }
}
