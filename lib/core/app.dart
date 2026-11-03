import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:xrinet/config/themes/app_theme.dart';
import 'package:xrinet/config/themes/theme_service.dart';
import 'package:xrinet/core/functions/initial_function.dart';
import 'package:xrinet/core/resources/assets_manager.dart';
import 'package:xrinet/core/resources/color_manager.dart';
import 'package:xrinet/core/translations/app_lang.dart';
import 'package:xrinet/core/translations/translations.dart';
import 'package:xrinet/core/utility/constant.dart';
import 'package:xrinet/presentation/pages/register/login_page.dart';
import 'package:xrinet/presentation/pages/register/widgets/get_my_user_info.dart';
import 'package:xrinet/presentation/widgets/global/others/multi_bloc_provider.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    _defineThePlatform(context);

    return MultiBlocs(materialApp(context));
  }

  Widget materialApp(BuildContext context) {
    return GetBuilder<AppLanguage>(
      init: AppLanguage.getInstance(),
      tag: AppLanguage.tag,
      builder: (controller) {
        return GetMaterialApp(
          defaultTransition: Transition.noTransition,
          transitionDuration: const Duration(seconds: 0),
          translations: Translation(),
          locale: Locale(controller.languageSelected),
          fallbackLocale: const Locale('en'),
          debugShowCheckedModeBanner: false,
          title: 'Xrinet',
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: ThemeOfApp.theme,
          home: const XrinetSplashScreen(),
        );
      },
    );
  }
}

class XrinetSplashScreen extends StatefulWidget {
  const XrinetSplashScreen({super.key});

  @override
  State<XrinetSplashScreen> createState() =>
      _XrinetSplashScreenState();
}

class _XrinetSplashScreenState extends State<XrinetSplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _glowOpacity;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _logoScale = Tween<double>(
      begin: 0.65,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
      ),
    );

    _logoOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(
        0.0,
        0.65,
        curve: Curves.easeIn,
      ),
    );

    _glowOpacity = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    _startApp();
  }

  Future<void> _startApp() async {
    final minimumSplashDuration = Future<void>.delayed(
      const Duration(milliseconds: 1800),
    );

    final initialization = initializeDefaultValues();

    await _controller.forward();

    final String? myId = await initialization;

    await minimumSplashDuration;

    if (!mounted) return;

    Get.offAll(
      () => myId == null
          ? const LoginPage()
          : GetMyPersonalInfo(myPersonalId: myId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorManager.black,
      body: SizedBox.expand(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Stack(
              alignment: Alignment.center,
              children: [
                // Full-screen background
                Container(
                  decoration: const BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 1.1,
                      colors: [
                        Color(0xFF17131F),
                        Color(0xFF0B0B10),
                        ColorManager.black,
                      ],
                    ),
                  ),
                ),

                // Cyan glow
                Opacity(
                  opacity: _glowOpacity.value * 0.35,
                  child: Container(
                    width: 260,
                    height: 260,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00D9D8),
                          blurRadius: 100,
                          spreadRadius: 15,
                        ),
                      ],
                    ),
                  ),
                ),

                // Purple glow
                Opacity(
                  opacity: _glowOpacity.value * 0.30,
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFD000FF),
                          blurRadius: 90,
                          spreadRadius: 12,
                        ),
                      ],
                    ),
                  ),
                ),

                // Animated Xrinet logo
                FadeTransition(
                  opacity: _logoOpacity,
                  child: ScaleTransition(
                    scale: _logoScale,
                    child: Image.asset(
                      IconsAssets.splashIcon,
                      width: 260,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

void _defineThePlatform(BuildContext context) {
  final TargetPlatform platform = Theme.of(context).platform;

  isThatMobile = platform == TargetPlatform.iOS ||
      platform == TargetPlatform.android;

  isThatAndroid = platform == TargetPlatform.android;
}
