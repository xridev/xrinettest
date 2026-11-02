import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xrinet/config/routes/app_routes.dart';
import 'package:xrinet/core/utility/constant.dart';
import 'package:xrinet/presentation/cubit/firestoreUserInfoCubit/users_info_reel_time/users_info_reel_time_bloc.dart';
import 'package:xrinet/presentation/pages/messages/ringing_page.dart';
import 'package:xrinet/presentation/screens/mobile_screen_layout.dart';

class PopupCalling extends StatefulWidget {
  final String userId;

  const PopupCalling(this.userId, {super.key});

  @override
  State<PopupCalling> createState() => _PopupCallingState();
}

class _PopupCallingState extends State<PopupCalling> {
  bool isHeMoved = false;

  @override
  void initState() {
    super.initState();
    // Screen init hoar shomoy data load event trigger hobe
    UsersInfoReelTimeBloc.get(context).add(LoadMyPersonalInfo());
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<UsersInfoReelTimeBloc, UsersInfoReelTimeState>(
      listenWhen: (previous, current) => previous != current,
      listener: (context, state) {
        if (state is MyPersonalInfoLoaded &&
            !amICalling &&
            state.myPersonalInfoInReelTime.channelId.isNotEmpty) {
          if (!isHeMoved) {
            setState(() => isHeMoved = true);
            Go(context).push(
              page: CallingRingingPage(
                channelId: state.myPersonalInfoInReelTime.channelId,
                clearMoving: clearMoving,
              ),
              withoutRoot: false,
            );
          }
        }
      },
      child: MobileScreenLayout(widget.userId),
    );
  }

  void clearMoving() {
    setState(() => isHeMoved = false);
  }
}
