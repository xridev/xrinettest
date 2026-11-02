import 'package:xrinet/core/use_case/use_case.dart';
import 'package:xrinet/data/models/parent_classes/without_sub_classes/message.dart';
import 'package:xrinet/domain/repositories/user_repository.dart';

class GetMessagesUseCase implements StreamUseCase<List<Message>, String> {
  final FirestoreUserRepository _addPostToUserRepository;

  GetMessagesUseCase(this._addPostToUserRepository);

  @override
  Stream<List<Message>> call({required String params}) {
    return _addPostToUserRepository.getMessages(receiverId: params);
  }
}
