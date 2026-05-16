import 'package:figma_squircle_updated/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled/common/extensions/font_extension.dart';
import 'package:untitled/utilities/const.dart';

class LoginButton extends StatelessWidget {
  final String text;
  final String assetName;
  final Function onTap;

  const LoginButton({Key? key, required this.text, required this.assetName, required this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap(),
      child: Container(
        decoration: ShapeDecoration(
          color: cWhite,
          shape: SmoothRectangleBorder(
            borderRadius: const SmoothBorderRadius.all(SmoothRadius(cornerRadius: 14, cornerSmoothing: cornerSmoothing)),
            side: BorderSide(color: cNavy.withValues(alpha: 0.08), width: 1),
          ),
          shadows: [
            BoxShadow(color: cNavy.withValues(alpha: 0.06), blurRadius: 20, offset: const Offset(0, 6)),
          ],
        ),
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Image.asset(assetName, width: 24, height: 24),
            Expanded(
              child: Text(
                text.tr,
                textAlign: TextAlign.center,
                style: MyTextStyle.gilroySemiBold(color: cMainText, size: 15),
              ),
            ),
            const SizedBox(width: 24),
          ],
        ),
      ),
    );
  }
}
