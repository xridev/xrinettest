import 'package:xrinet/domain/repositories/calling_rooms_repository.dart';
import 'package:xrinet/core/use_case/use_case.dart';

class CancelJoiningToRoomUseCase
    extends UseCaseThreeParams<void, String, String, bool> {
  final CallingRoomsRepository _cancelJoiningToRoomRepo;
  CancelJoiningToRoomUseCase(this._cancelJoiningToRoomRepo);
  @override
  Future<void> call(
      {required String paramsOne,
      required String paramsTwo,
      required bool paramsThree}) async {
    return _cancelJoiningToRoomRepo.leaveTheRoom(
        userId: paramsOne,
        channelId: paramsTwo,
        isThatAfterJoining: paramsThree);
  }
}
