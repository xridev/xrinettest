import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:xrinet/core/resources/strings_manager.dart';
import 'package:xrinet/core/resources/styles_manager.dart';
import 'package:xrinet/core/utility/constant.dart';
import 'package:xrinet/data/models/child_classes/post/post.dart';
import 'package:xrinet/presentation/pages/comments/widgets/comment_of_post.dart';

class CommentsPageForMobile extends StatefulWidget {
  final ValueNotifier<Post> postInfo;

  const CommentsPageForMobile({super.key, required this.postInfo});

  @override
  State<CommentsPageForMobile> createState() => _CommentsPageForMobileState();
}

class _CommentsPageForMobileState extends State<CommentsPageForMobile> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: isThatMobile ? appBar(context) : null,
      body: CommentsOfPost(
        postInfo: widget.postInfo,
        selectedCommentInfo: ValueNotifier(null),
        textController: ValueNotifier(TextEditingController()),
      ),
    );
  }

  AppBar appBar(BuildContext context) {
    return AppBar(
      elevation: 0,
      iconTheme: IconThemeData(color: Theme.of(context).focusColor),
      backgroundColor: Theme.of(context).primaryColor,
      title: Text(
        StringsManager.comments.tr,
        style: getNormalStyle(color: Theme.of(context).focusColor),
      ),
    );
  }
}
