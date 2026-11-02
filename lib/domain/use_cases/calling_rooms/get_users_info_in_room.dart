import 'package:xrinet/domain/entities/calling_status.dart';
import 'package:xrinet/domain/repositories/calling_rooms_repository.dart';
import 'package:xrinet/core/use_case/use_case.dart';

class GetUsersInfoInRoomUseCase
    extends UseCase<List<UsersInfoInCallingRoom>, String> {
  final CallingRoomsRepository _callingRoomsRepo;
  GetUsersInfoInRoomUseCase(this._callingRoomsRepo);
  @override
  Future<List<UsersInfoInCallingRoom>> call({required String params}) {
    return _callingRoomsRepo.getUsersInfoInThisRoom(channelId: params);
  }
}
