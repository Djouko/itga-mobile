import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled/common/extensions/font_extension.dart';
import 'package:untitled/localization/languages.dart';
import 'package:untitled/utilities/const.dart';

class NoDataView extends StatelessWidget {
  const NoDataView({
    super.key,
    this.title = LKeys.noDataFound,
    this.description,
    this.child,
    this.showShow = true,
    this.icon,
  });

  final String title;
  final String? description;
  final Widget? child;
  final bool showShow;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    if (showShow) {
      final brightness = Theme.of(context).brightness;
      final isDark = brightness == Brightness.dark;
      final titleColor = isDark ? cWhite : cMainText;
      final subtitleColor = isDark ? cLightText : cDarkText;
      final circleBg = isDark
          ? cPrimary.withValues(alpha: 0.08)
          : cPrimary.withValues(alpha: 0.06);
      return Center(
        child: SafeArea(
          top: false,
          child: Container(
            constraints: BoxConstraints(minHeight: Get.height / 3),
            margin: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: circleBg,
                  ),
                  child: Icon(
                    icon ?? Icons.inbox_outlined,
                    size: 36,
                    color: cPrimary.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  title.tr,
                  style: MyTextStyle.gilroySemiBold(
                    color: titleColor,
                    size: 17,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (description != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    description!.tr,
                    style: MyTextStyle.gilroyRegular(
                      size: 14,
                      color: subtitleColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }
    return child ?? Container();
  }
}
