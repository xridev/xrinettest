import 'package:xrinet/core/use_case/use_case.dart';
import 'package:xrinet/data/models/parent_classes/without_sub_classes/comment.dart';
import 'package:xrinet/domain/repositories/post/comment/reply_repository.dart';

class GetRepliesOfThisCommentUseCase implements UseCase<List<Comment>, String> {
  final FirestoreReplyRepository _getRepliesOfThisCommentRepository;

  GetRepliesOfThisCommentUseCase(this._getRepliesOfThisCommentRepository);

  @override
  Future<List<Comment>> call({required String params}) async {
    return await _getRepliesOfThisCommentRepository.getSpecificReplies(
      commentId: params,
    );
  }
}
