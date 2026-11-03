import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:xrinet/core/resources/assets_manager.dart';
import 'package:xrinet/core/resources/color_manager.dart';
import 'package:xrinet/core/utility/injector.dart';

import 'package:xrinet/presentation/cubit/postInfoCubit/post_cubit.dart';
import 'package:xrinet/presentation/pages/profile/personal_profile_page.dart';
import 'package:xrinet/presentation/pages/time_line/all_user_time_line/all_users_time_line.dart';
import 'package:xrinet/presentation/pages/time_line/my_own_time_line/home_page.dart';
import 'package:xrinet/presentation/pages/video/videos_page.dart';
import 'package:xrinet/presentation/pages/gallery/create_gallery_page.dart';

import 'package:xrinet/presentation/widgets/global/screens_w.dart';

class MobileScreenLayout extends StatefulWidget {
  final String userId;

  const MobileScreenLayout(this.userId, {super.key});

  @override
  State<MobileScreenLayout> createState() => _MobileScreenLayoutState();
}

class _MobileScreenLayoutState extends State<MobileScreenLayout> {
  final ValueNotifier<bool> playHomeVideo = ValueNotifier(false);
  final ValueNotifier<bool> playMainReelVideos = ValueNotifier(false);

  final CupertinoTabController controller = CupertinoTabController();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: playMainReelVideos,
      builder: (BuildContext context, bool value, _) {
        return CupertinoTabScaffold(
          controller: controller,
          tabBar: CupertinoTabBar(
            backgroundColor: value
                ? ColorManager.black
                : Theme.of(context).primaryColor,
            height: 45,
            border: Border.all(
              color: ColorManager.transparent,
            ),
            items: [
              navigationBarItem(IconsAssets.home, value),
              navigationBarItem(
                IconsAssets.video,
                value,
                smallIcon: true,
              ),
              const BottomNavigationBarItem(
                icon: Icon(
                  CupertinoIcons.plus_app,
                  size: 27,
                ),
              ),
              navigationBarItem(IconsAssets.search, value),
              personalImageItem(),
            ],
          ),
          tabBuilder: (context, index) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;

              playMainReelVideos.value = controller.index == 1;
              playHomeVideo.value = controller.index == 0;
            });

            switch (index) {
              case 0:
                return homePage();

              case 1:
                return videoPage(value);

              case 2:
                return galleryPage();

              case 3:
                return allUsersTimLinePage();

              case 4:
                return personalProfilePage();

              default:
                return homePage();
            }
          },
        );
      },
    );
  }

  CupertinoTabView galleryPage() => CupertinoTabView(
        builder: (context) => const CupertinoPageScaffold(
          child: CreateGalleryPage(),
        ),
      );

  CupertinoTabView allUsersTimLinePage() => CupertinoTabView(
        builder: (context) => CupertinoPageScaffold(
          child: AllUsersTimeLinePage(),
        ),
      );

  CupertinoTabView personalProfilePage() => CupertinoTabView(
        builder: (context) => CupertinoPageScaffold(
          child: BlocProvider<PostCubit>(
            create: (context) => injector<PostCubit>(),
            child: PersonalProfilePage(
              personalId: widget.userId,
            ),
          ),
        ),
      );

  Widget videoPage(bool value) => CupertinoTabView(
        builder: (context) => CupertinoPageScaffold(
          child: BlocProvider<PostCubit>(
            create: (context) => injector<PostCubit>(),
            child: VideosPage(
              stopVideo: playMainReelVideos,
            ),
          ),
        ),
      );

  Widget homePage() => CupertinoTabView(
        builder: (context) => CupertinoPageScaffold(
          child: BlocProvider<PostCubit>(
            create: (context) => injector<PostCubit>(),
            child: ValueListenableBuilder(
              valueListenable: playHomeVideo,
              builder: (context, bool playVideoValue, child) => HomePage(
                userId: widget.userId,
                playVideo: playVideoValue,
              ),
            ),
          ),
        ),
      );

  BottomNavigationBarItem personalImageItem() =>
      const BottomNavigationBarItem(
        icon: PersonalImageIcon(),
      );

  BottomNavigationBarItem navigationBarItem(
    String icon,
    bool value, {
    bool smallIcon = false,
  }) {
    return BottomNavigationBarItem(
      icon: SvgPicture.asset(
        icon,
        height: smallIcon ? 23 : 25,
        colorFilter: ColorFilter.mode(
          value ? ColorManager.white : Theme.of(context).focusColor,
          BlendMode.srcIn,
        ),
      ),
    );
  }

  @override
  void dispose() {
    playHomeVideo.dispose();
    playMainReelVideos.dispose();
    controller.dispose();
    super.dispose();
  }
}
