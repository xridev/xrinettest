import 'package:animated_splash_screen/animated_splash_screen.dart';
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
          home: AnimatedSplashScreen.withScreenFunction(
            screenFunction: screenFunction,
            centered: true,
            splash: IconsAssets.splashIcon,
            backgroundColor: ColorManager.white,
            splashTransition: SplashTransition.scaleTransition,
          ),
        );
      },
    );
  }
}

Future<Widget> screenFunction() async {
  String? myId = await initializeDefaultValues();

  return myId == null
      ? const LoginPage()
      : GetMyPersonalInfo(myPersonalId: myId);
}

void _defineThePlatform(BuildContext context) {
  TargetPlatform platform = Theme.of(context).platform;
  isThatMobile =
      platform == TargetPlatform.iOS || platform == TargetPlatform.android;
  isThatAndroid = platform == TargetPlatform.android;
}
