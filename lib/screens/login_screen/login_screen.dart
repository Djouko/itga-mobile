import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled/common/extensions/font_extension.dart';
import 'package:untitled/common/extensions/image_extension.dart';
import 'package:untitled/common/managers/navigation.dart';
import 'package:untitled/localization/languages.dart';
import 'package:untitled/screens/company/company_auth_screen.dart';
import 'package:untitled/screens/extra_views/logo_tag.dart';
import 'package:untitled/screens/login_screen/login_button.dart';
import 'package:untitled/screens/login_screen/login_controller.dart';
import 'package:untitled/utilities/const.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var controller = Get.put(LoginController());
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0.0, 0.35, 1.0],
            colors: [cNavy, cBG, cBG],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 24),
                const LogoTag(width: 160),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    LKeys.signInDesc.tr,
                    textAlign: TextAlign.center,
                    style: MyTextStyle.gilroyLight(color: cDarkText, size: 16),
                  ),
                ),
                const SizedBox(height: 44),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      Text(
                        '${LKeys.signInTo.tr} ${LKeys.continue1.tr}',
                        style: MyTextStyle.gilroySemiBold(
                            color: cMainText, size: 20),
                      ),
                      const SizedBox(height: 20),
                      LoginButton(
                        text: LKeys.signInWithGoogle,
                        assetName: MyImages.google,
                        onTap: () => controller.googleLogin(),
                      ),
                      LoginButton(
                        text: LKeys.signInWithEmail,
                        assetName: MyImages.email,
                        onTap: () => controller.emailLogin(),
                      ),
                      if (GetPlatform.isIOS)
                        LoginButton(
                          text: LKeys.signInWithApple,
                          assetName: MyImages.apple,
                          onTap: () => controller.appleLogin(),
                        ),
                      const SizedBox(height: 18),
                      const _CompanyAuthEntryCard(),
                    ],
                  ),
                ),
                const SizedBox(height: 34),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 4,
                    runSpacing: 2,
                    children: [
                      Text(
                        LKeys.iAgreeTo.tr,
                        style: MyTextStyle.gilroyLight(
                            color: cLightText, size: 13),
                      ),
                      GestureDetector(
                        onTap: () => Navigate.openURLSheet(
                            title: LKeys.termsOfUse.tr, url: termsURL),
                        child: Text(
                          LKeys.termsOfUse.tr,
                          style: MyTextStyle.gilroySemiBold(
                              color: cPrimary, size: 13),
                        ),
                      ),
                      Text(
                        LKeys.and.tr,
                        style: MyTextStyle.gilroyLight(
                            color: cLightText, size: 13),
                      ),
                      GestureDetector(
                        onTap: () => Navigate.openURLSheet(
                            title: LKeys.privacyPolicy.tr, url: privacyURL),
                        child: Text(
                          LKeys.privacyPolicy.tr,
                          style: MyTextStyle.gilroySemiBold(
                              color: cPrimary, size: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CompanyAuthEntryCard extends StatelessWidget {
  const _CompanyAuthEntryCard();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.to(() => const CompanyAuthScreen()),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cWhite,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: cPrimary.withValues(alpha: 0.18)),
          boxShadow: [
            BoxShadow(
              color: cNavy.withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [cTeal, cNavy],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.business_center_rounded,
                  color: cWhite, size: 21),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    LKeys.companyPortal.tr,
                    style: MyTextStyle.gilroyBold(color: cMainText, size: 14),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    LKeys.companyLoginDesc.tr,
                    style:
                        MyTextStyle.gilroyRegular(color: cLightText, size: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: cPrimary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_forward_rounded,
                  color: cPrimary, size: 17),
            ),
          ],
        ),
      ),
    );
  }
}
