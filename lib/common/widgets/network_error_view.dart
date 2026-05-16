import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled/common/extensions/font_extension.dart';
import 'package:untitled/localization/languages.dart';
import 'package:untitled/utilities/const.dart';

class NetworkErrorView extends StatelessWidget {
  final VoidCallback onRetry;

  const NetworkErrorView({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? cWhite : cMainText;
    final circleBg = isDark
        ? cOrange.withValues(alpha: 0.10)
        : cOrange.withValues(alpha: 0.08);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: circleBg,
              ),
              child: Icon(
                Icons.wifi_off_rounded,
                size: 40,
                color: cOrange.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              LKeys.noConnection.tr,
              style: MyTextStyle.gilroySemiBold(color: titleColor, size: 19),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              LKeys.noConnectionDesc.tr,
              style: MyTextStyle.gilroyRegular(color: cLightText, size: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: 160,
              height: 46,
              child: ElevatedButton(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: cPrimary,
                  foregroundColor: cWhite,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(23),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  LKeys.retry.tr,
                  style: MyTextStyle.gilroySemiBold(color: cWhite, size: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
