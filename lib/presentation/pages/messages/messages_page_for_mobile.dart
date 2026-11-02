import 'package:flutter/material.dart';
import 'package:xrinet/config/routes/app_routes.dart';
import 'package:xrinet/core/utility/constant.dart';
import 'package:xrinet/presentation/pages/messages/select_for_group_chat.dart';
import 'package:xrinet/presentation/pages/messages/widgets/list_of_messages.dart';

class MessagesPageForMobile extends StatelessWidget {
  const MessagesPageForMobile({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: isThatMobile ? buildAppBar(context) : null,
      body: const ListOfMessages(),
    );
  }

  AppBar buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Theme.of(context).primaryColor,
      actions: [
        IconButton(
          onPressed: () {
            Go(context).push(page: const SelectForGroupChat());
          },
          icon: Icon(
            Icons.add,
            color: Theme.of(context).focusColor,
            size: 30,
          ),
        )
      ],
    );
  }
}
