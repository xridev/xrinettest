import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:xrinet/core/functions/toast_show.dart';
import 'package:xrinet/core/utility/constant.dart';
import 'package:xrinet/core/utility/saved_account_storage.dart';
import 'package:xrinet/presentation/cubit/firestoreUserInfoCubit/user_info_cubit.dart';
import 'package:xrinet/presentation/screens/responsive_layout.dart';
import 'package:xrinet/presentation/screens/web_screen_layout.dart';
import 'package:xrinet/presentation/pages/register/widgets/popup_calling.dart';

class GetMyPersonalInfo extends StatefulWidget {
  final String myPersonalId;

  const GetMyPersonalInfo({super.key, required this.myPersonalId});

  @override
  State<GetMyPersonalInfo> createState() => _GetMyPersonalInfoState();
}

class _GetMyPersonalInfoState extends State<GetMyPersonalInfo> {
  bool isHeMovedToHome = false;

  @override
  Widget build(BuildContext context) {
    return BlocListener<UserInfoCubit, UserInfoState>(
      bloc: UserInfoCubit.get(context)
        ..getUserInfo(widget.myPersonalId, getDeviceToken: true),
      listenWhen: (previous, current) => previous != current,
      listener: (context, userState) async {
        if (isHeMovedToHome) return;

        if (userState is CubitMyPersonalInfoLoaded) {
          isHeMovedToHome = true;

          final info = userState.userPersonalInfo;

          await SavedAccountStorage.saveAccount(
            userId: info.userId.toString(),
            email: info.email,
            name: info.name,
            userName: info.userName,
            profileImageUrl: info.profileImageUrl,
          );

          if (!mounted) return;

          myPersonalId = widget.myPersonalId;

          Get.offAll(
            ResponsiveLayout(
              mobileScreenLayout: PopupCalling(myPersonalId),
              webScreenLayout: const WebScreenLayout(),
            ),
          );
        } else if (userState is CubitGetUserInfoFailed) {
          isHeMovedToHome = true;
          ToastShow.toastStateError(userState);
        }
      },
      child: Container(color: Theme.of(context).primaryColor),
    );
  }
}
