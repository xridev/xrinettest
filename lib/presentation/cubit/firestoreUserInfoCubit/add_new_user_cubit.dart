
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/parent_classes/without_sub_classes/user_personal_info.dart';
import '../../../domain/use_cases/user/add_new_user_usecase.dart';

part 'add_new_user_state.dart';

class FireStoreAddNewUserCubit extends Cubit<FirestoreAddNewUserState> {
  final AddNewUserUseCase _addNewUserUseCase;

  FireStoreAddNewUserCubit(this._addNewUserUseCase)
      : super(CubitInitial());

  static FireStoreAddNewUserCubit get(BuildContext context) =>
      BlocProvider.of(context);

  Future<bool> addNewUser(UserPersonalInfo newUserInfo) async {
    if (isClosed) return false;

    emit(CubitUserAdding());

    try {
      await _addNewUserUseCase.call(params: newUserInfo);

      if (isClosed) return false;

      emit(CubitUserAdded());
      return true;
    } catch (e, stackTrace) {
      debugPrint('ADD USER ERROR: $e');
      debugPrintStack(stackTrace: stackTrace);

      if (!isClosed) {
        emit(CubitAddNewUserFailed(e.toString()));
      }

      return false;
    }
  }
}
