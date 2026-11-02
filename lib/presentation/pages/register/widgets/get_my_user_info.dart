import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:xrinet/core/functions/toast_show.dart';
import 'package:xrinet/core/utility/constant.dart';
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
  void initState() {
    super.initState();
    // Screen init hoar shomoy userInfo query trigger hobe
    UserInfoCubit.get(context).getUserInfo(widget.myPersonalId, getDeviceToken: true);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<UserInfoCubit, UserInfoState>(
      listenWhen: (previous, current) => previous != current,
      listener: (context, userState) {
        if (userState is CubitMyPersonalInfoLoaded && !isHeMovedToHome) {
          // Sudhu user info strictly LOAD holei isHeMovedToHome true hobe
          setState(() => isHeMovedToHome = true);
          myPersonalId = widget.myPersonalId;

          Get.offAll(
            ResponsiveLayout(
              mobileScreenLayout: PopupCalling(myPersonalId),
              webScreenLayout: const WebScreenLayout(),
            ),
          );
        } else if (userState is CubitGetUserInfoFailed) {
          // Error ashle toast dekhabe, kintu isHeMovedToHome true hobe na jate retry kora jay
          ToastShow.toastStateError(userState);
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).primaryColor,
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}
