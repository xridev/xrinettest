import 'dart:io';
import 'dart:typed_data';

import 'package:xrinet/core/use_case/use_case.dart';
import 'package:xrinet/data/models/parent_classes/without_sub_classes/message.dart';
import 'package:xrinet/domain/repositories/group_message.dart';

class AddMessageForGroupChatUseCase
    implements UseCaseThreeParams<Message, Message, Uint8List, File?> {
  final FireStoreGroupMessageRepository _addPostToUserRepository;
  AddMessageForGroupChatUseCase(this._addPostToUserRepository);

  @override
  Future<Message> call(
      {required Message paramsOne,
      Uint8List? paramsTwo,
      required File? paramsThree}) {
    return _addPostToUserRepository.sendMessage(
        messageInfo: paramsOne,
        pathOfPhoto: paramsTwo,
        recordFile: paramsThree);
  }
}
