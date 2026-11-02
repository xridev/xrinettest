import 'package:xrinet/core/use_case/use_case.dart';
import 'package:xrinet/data/models/parent_classes/without_sub_classes/user_personal_info.dart';
import 'package:xrinet/domain/repositories/user_repository.dart';

class SearchAboutUserUseCase
    implements StreamUseCaseTwoParams<List<UserPersonalInfo>, String, bool> {
  final FirestoreUserRepository _addPostToUserRepository;

  SearchAboutUserUseCase(this._addPostToUserRepository);

  @override
  Stream<List<UserPersonalInfo>> call(
      {required String paramsOne, required bool paramsTwo}) {
    return _addPostToUserRepository.searchAboutUser(
        name: paramsOne, searchForSingleLetter: paramsTwo);
  }
}
