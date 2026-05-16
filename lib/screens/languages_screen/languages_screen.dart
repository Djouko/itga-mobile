import 'package:figma_squircle_updated/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled/common/extensions/font_extension.dart';
import 'package:untitled/localization/languages.dart';
import 'package:untitled/screens/extra_views/top_bar.dart';
import 'package:untitled/screens/languages_screen/languages_controller.dart';
import 'package:untitled/utilities/const.dart';

class LanguagesScreen extends StatelessWidget {
  const LanguagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    LanguagesController controller = LanguagesController();
    return Scaffold(
      body: GetBuilder(
          init: controller,
          builder: (c) {
            return Column(
              children: [
                TopBarForInView(title: LKeys.languages.tr),
                Expanded(
                  child: SafeArea(
                    top: false,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      itemCount: controller.languages.length,
                      itemBuilder: (context, index) {
                        final lang = controller.languages[index];
                        final isSelected = controller.selectedLan == lang;
                        return GestureDetector(
                          onTap: () => controller.setLang(lang),
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            decoration: ShapeDecoration(
                              color: isSelected
                                  ? cPrimary.withValues(alpha: 0.1)
                                  : Colors.transparent,
                              shape: SmoothRectangleBorder(
                                borderRadius: const SmoothBorderRadius.all(
                                    SmoothRadius(
                                        cornerRadius: 12,
                                        cornerSmoothing: cornerSmoothing)),
                                side: BorderSide(
                                  color: isSelected
                                      ? cPrimary.withValues(alpha: 0.4)
                                      : cLightText.withValues(alpha: 0.08),
                                  width: isSelected ? 1.5 : 1,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        lang.displayName,
                                        style: MyTextStyle.gilroySemiBold(
                                          size: 16,
                                          color:
                                              isSelected ? cPrimary : cDarkText,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        lang.nameInEnglish,
                                        style: MyTextStyle.gilroyRegular(
                                            size: 13, color: cLightText),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: const BoxDecoration(
                                      color: cPrimary,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.check_rounded,
                                        color: cBlack, size: 16),
                                  )
                                else
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color:
                                              cLightText.withValues(alpha: 0.3),
                                          width: 1.5),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                )
              ],
            );
          }),
    );
  }
}
