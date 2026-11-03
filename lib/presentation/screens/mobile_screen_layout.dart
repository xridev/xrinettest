import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

class _MobileScreenLayoutState extends State<MobileScreenLayout>
    with WidgetsBindingObserver {
  static const String _resumeReelsKey = 'resume_reels_after_app_close';

  static const Duration _reelsResumeDuration =
      Duration(minutes: 15);

  final ValueNotifier<bool> playHomeVideo = ValueNotifier(false);
  final ValueNotifier<bool> playMainReelVideos = ValueNotifier(false);

  final CupertinoTabController controller = CupertinoTabController();

  DateTime? _reelsOpenedAt;

  bool _isReady = false;
  bool _wasBackgrounded = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);
    controller.addListener(_onTabChanged);

    _restoreInitialTab();
  }

  // Restore Reels only when the previous session was eligible.
  // Otherwise, always start from Home.
  Future<void> _restoreInitialTab() async {
    final SharedPreferences prefs =
        await SharedPreferences.getInstance();

    final bool shouldResumeReels =
        prefs.getBool(_resumeReelsKey) ?? false;

    // Consume the saved state so it cannot reopen Reels repeatedly.
    await prefs.setBool(_resumeReelsKey, false);

    if (!mounted) return;

    controller.index = shouldResumeReels ? 1 : 0;

    _updateVideoPlayback();

    if (controller.index == 1) {
      _reelsOpenedAt = DateTime.now();
    }

    setState(() {
      _isReady = true;
    });
  }

  // Detect tab changes.
  void _onTabChanged() {
    if (!mounted) return;

    _updateVideoPlayback();

    if (controller.index == 1) {
      _reelsOpenedAt ??= DateTime.now();
    } else {
      _reelsOpenedAt = null;
    }
  }

  void _updateVideoPlayback() {
    final int currentIndex = controller.index;

    playMainReelVideos.value = currentIndex == 1;
    playHomeVideo.value = currentIndex == 0;
  }

  // Save whether Reels should open on the next app launch.
  Future<void> _saveReelsResumeState() async {
    final SharedPreferences prefs =
        await SharedPreferences.getInstance();

    bool shouldResumeReels = false;

    if (controller.index == 1 && _reelsOpenedAt != null) {
      final Duration watchedDuration =
          DateTime.now().difference(_reelsOpenedAt!);

      shouldResumeReels =
          watchedDuration >= _reelsResumeDuration;
    }

    await prefs.setBool(
      _resumeReelsKey,
      shouldResumeReels,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _wasBackgrounded = true;
      _saveReelsResumeState();
    }

    if (state == AppLifecycleState.resumed && _wasBackgrounded) {
      _wasBackgrounded = false;

      // The user returned to the same running app.
      // Do not keep an old resume flag for the next launch.
      SharedPreferences.getInstance().then((prefs) {
        prefs.setBool(_resumeReelsKey, false);
      });

      if (controller.index == 1) {
        _reelsOpenedAt = DateTime.now();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isReady) {
      return const CupertinoPageScaffold(
        child: Center(
          child: CupertinoActivityIndicator(),
        ),
      );
    }

    return ValueListenableBuilder<bool>(
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
            switch (index) {
              case 0:
                return homePage();

              case 1:
                return videoPage();

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

  Widget videoPage() => CupertinoTabView(
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
            child: ValueListenableBuilder<bool>(
              valueListenable: playHomeVideo,
              builder: (context, bool playVideoValue, child) {
                return HomePage(
                  userId: widget.userId,
                  playVideo: playVideoValue,
                );
              },
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
    WidgetsBinding.instance.removeObserver(this);
    controller.removeListener(_onTabChanged);

    playHomeVideo.dispose();
    playMainReelVideos.dispose();
    controller.dispose();

    super.dispose();
  }
}
