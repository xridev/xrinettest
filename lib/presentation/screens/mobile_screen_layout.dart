import 'dart:async';

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
  static const String _reelsWatchedMsKey = 'reels_watched_ms';

  static const Duration _reelsResumeDuration =
      Duration(minutes: 15);

  static const Duration _checkpointInterval =
      Duration(seconds: 10);

  final ValueNotifier<bool> playHomeVideo = ValueNotifier(false);
  final ValueNotifier<bool> playMainReelVideos = ValueNotifier(false);

  final CupertinoTabController controller = CupertinoTabController();

  Duration _reelsWatchedDuration = Duration.zero;

  DateTime? _reelsSessionStartedAt;

  Timer? _reelsCheckpointTimer;

  bool _isReady = false;
  bool _appInForeground = true;

  Future<void> _saveQueue = Future<void>.value();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);
    controller.addListener(_onTabChanged);

    _restoreInitialTab();
  }

  // Restore Reels only if the previous app session reached 15 minutes.
  // Otherwise, start from Home.
  Future<void> _restoreInitialTab() async {
    final prefs = await SharedPreferences.getInstance();

    final int watchedMs = prefs.getInt(_reelsWatchedMsKey) ?? 0;

    final bool shouldResumeReels =
        watchedMs >= _reelsResumeDuration.inMilliseconds;

    // Consume the previous session's saved duration.
    await prefs.remove(_reelsWatchedMsKey);

    if (!mounted) return;

    _reelsWatchedDuration = Duration.zero;

    controller.index = shouldResumeReels ? 1 : 0;

    _updateVideoPlayback();

    setState(() {
      _isReady = true;
    });

    if (controller.index == 1 && _appInForeground) {
      _startReelsTimer();
    }
  }

  // Handle tab changes.
  void _onTabChanged() {
    if (!mounted || !_isReady) return;

    _updateVideoPlayback();

    if (controller.index == 1 && _appInForeground) {
      _startReelsTimer();
    } else {
      _pauseReelsTimer();
    }
  }

  void _updateVideoPlayback() {
    final int currentIndex = controller.index;

    playMainReelVideos.value = currentIndex == 1;
    playHomeVideo.value = currentIndex == 0;
  }

  // Start counting foreground Reels viewing time.
  void _startReelsTimer() {
    if (_reelsSessionStartedAt != null || !_appInForeground) {
      return;
    }

    _reelsSessionStartedAt = DateTime.now();

    _reelsCheckpointTimer?.cancel();

    _reelsCheckpointTimer = Timer.periodic(
      _checkpointInterval,
      (_) => _persistReelsDuration(),
    );
  }

  // Stop counting and add the current foreground interval.
  void _pauseReelsTimer() {
    final startedAt = _reelsSessionStartedAt;

    if (startedAt != null) {
      _reelsWatchedDuration += DateTime.now().difference(startedAt);
      _reelsSessionStartedAt = null;
    }

    _reelsCheckpointTimer?.cancel();
    _reelsCheckpointTimer = null;

    _persistReelsDuration();
  }

  // Save the accumulated foreground viewing duration.
  Future<void> _persistReelsDuration() {
    Duration totalDuration = _reelsWatchedDuration;

    final startedAt = _reelsSessionStartedAt;

    if (startedAt != null) {
      totalDuration += DateTime.now().difference(startedAt);
    }

    final int watchedMs = totalDuration.inMilliseconds;

    // Queue writes to prevent older saves overwriting newer values.
    _saveQueue = _saveQueue.then((_) async {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setInt(
        _reelsWatchedMsKey,
        watchedMs,
      );
    }).catchError((Object error) {
      debugPrint('REELS TIMER SAVE ERROR: $error');
    });

    return _saveQueue;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _appInForeground = false;

      _pauseReelsTimer();
      return;
    }

    if (state == AppLifecycleState.resumed) {
      _appInForeground = true;

      if (_isReady && controller.index == 1) {
        _startReelsTimer();
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
    _pauseReelsTimer();

    WidgetsBinding.instance.removeObserver(this);
    controller.removeListener(_onTabChanged);

    playHomeVideo.dispose();
    playMainReelVideos.dispose();
    controller.dispose();

    super.dispose();
  }
}
