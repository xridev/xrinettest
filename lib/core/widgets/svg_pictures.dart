import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:xrinet/core/resources/assets_manager.dart';
import 'package:xrinet/presentation/screens/web_screen_layout.dart';

class XrinetLogo extends StatelessWidget {
  final Color? color;
  final bool enableOnTapForWeb;
  const XrinetLogo({super.key, this.color, this.enableOnTapForWeb = false});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: enableOnTapForWeb
            ? () => Get.offAll(const WebScreenLayout())
            : null,
        child: SvgPicture.asset(
          IconsAssets.xrinetLogo,
          height: 32,
          colorFilter: ColorFilter.mode(
              color ?? Theme.of(context).focusColor, BlendMode.srcIn),
        ),
      );
}
