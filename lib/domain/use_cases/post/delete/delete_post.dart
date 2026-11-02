import 'package:xrinet/data/models/child_classes/post/post.dart';
import 'package:xrinet/core/use_case/use_case.dart';
import 'package:xrinet/domain/repositories/post/post_repository.dart';

class DeletePostUseCase implements UseCase<void, Post> {
  final FireStorePostRepository _deletePostRepository;

  DeletePostUseCase(this._deletePostRepository);

  @override
  Future<void> call({required Post params}) {
    return _deletePostRepository.deletePost(postInfo: params);
  }
}
