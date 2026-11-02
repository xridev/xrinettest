import 'package:xrinet/core/use_case/use_case.dart';
import 'package:xrinet/data/models/parent_classes/without_sub_classes/user_personal_info.dart';
import 'package:xrinet/domain/repositories/user_repository.dart';

class GetMyInfoUseCase implements StreamUseCase<UserPersonalInfo, void> {
  final FirestoreUserRepository _getMyInfoRepository;

  GetMyInfoUseCase(this._getMyInfoRepository);

  @override
  Stream<UserPersonalInfo> call({required void params}) {
    return _getMyInfoRepository.getMyPersonalInfo();
  }
}
