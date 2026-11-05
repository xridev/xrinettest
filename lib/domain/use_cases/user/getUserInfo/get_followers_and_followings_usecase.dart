import 'package:xrinet/domain/entities/specific_users_info.dart';
import 'package:xrinet/core/use_case/use_case.dart';
import '../../../repositories/user_repository.dart';

class GetFollowersAndFollowingsUseCase
    implements
        UseCaseThreeParams<FollowersAndFollowingsInfo, List<dynamic>, List<dynamic>, String> {
  final FirestoreUserRepository _fireStoreUserRepository;

  GetFollowersAndFollowingsUseCase(this._fireStoreUserRepository);

  @override
  Future<FollowersAndFollowingsInfo> call(
      {required List<dynamic> paramsOne, required List<dynamic> paramsTwo, required String paramsThree}) {
    return _fireStoreUserRepository.getFollowersAndFollowingsInfo(
        followersIds: paramsOne, followingsIds: paramsTwo, userUid: paramsThree);
  }
}
