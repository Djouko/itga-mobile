import 'package:figma_squircle_updated/figma_squircle.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled/common/extensions/font_extension.dart';
import 'package:untitled/common/managers/company_mode_controller.dart';
import 'package:untitled/common/managers/navigation.dart';
import 'package:untitled/common/managers/session_manager.dart';
import 'package:untitled/localization/languages.dart';
import 'package:untitled/screens/block_list_screen/blocklist_screen.dart';
import 'package:untitled/screens/edit_profile_screen/edit_profile_screen.dart';
import 'package:untitled/screens/extra_views/logo_tag.dart';
import 'package:untitled/screens/extra_views/top_bar.dart';
import 'package:untitled/screens/faq_screen/faq_screen.dart';
import 'package:untitled/screens/languages_screen/languages_screen.dart';
import 'package:untitled/screens/notification_screen/notification_screen.dart';
import 'package:untitled/screens/profile_verification_screen/profile_verification_screen.dart';
import 'package:untitled/screens/saved_posts_screen/saved_posts_screen.dart';
import 'package:untitled/screens/saved_reels_screen/saved_reels_screen.dart';
import 'package:untitled/screens/setting_screen/setting_controller.dart';
import 'package:untitled/screens/tech_resources/tech_resources_screen.dart';
import 'package:untitled/screens/job_board/job_list_screen.dart';
import 'package:untitled/screens/company/company_auth_screen.dart';
import 'package:untitled/screens/company/company_dashboard_screen.dart';
import 'package:untitled/utilities/const.dart';

class SettingScreen extends StatelessWidget {
  const SettingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    SettingController controller = SettingController();
    final companyMode = CompanyModeController.to;
    return Scaffold(
      body: Column(
        children: [
          const TopBarForInView(title: LKeys.profileSetting),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.only(
                    top: 5, bottom: 20, left: 10, right: 10),
                child: SafeArea(
                  top: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Obx(() {
                        if (!companyMode.isActing)
                          return const SizedBox.shrink();
                        return _activeCompanyIdentityCard(companyMode);
                      }),
                      _sectionHeader(LKeys.account.tr.toUpperCase()),
                      _sectionCard([
                        SettingButton(
                          title: LKeys.editProfile,
                          icon: Icons.person_outline_rounded,
                          iconBgColor: cNavy,
                          onTap: () => Get.to(() => const EditProfileScreen()),
                        ),
                        SettingButton(
                            title: LKeys.roomsYouOwn,
                            icon: Icons.meeting_room_outlined,
                            iconBgColor: cMagenta,
                            onTap: controller.tapRoomsYouOwn),
                        SettingButton(
                            title: LKeys.roomsInvitation,
                            icon: Icons.mail_outline_rounded,
                            iconBgColor: cOrange,
                            onTap: controller.tapRoomInvitation),
                        SettingButton(
                          title: LKeys.notification,
                          icon: Icons.notifications_none_rounded,
                          iconBgColor: cRed,
                          onTap: () => Get.to(() => const NotificationScreen()),
                        ),
                        if (SessionManager.shared.getUser()?.isVerified != 2 &&
                            SessionManager.shared.getUser()?.isVerified != 3)
                          SettingButton(
                            title: LKeys.profileVerification,
                            icon: Icons.verified_outlined,
                            iconBgColor: cTeal,
                            onTap: () {
                              var type =
                                  SessionManager.shared.getUser()?.isVerified;
                              if (type == 0) {
                                Get.to(() => const ProfileVerificationScreen());
                              } else {
                                controller
                                    .showSnackBar(LKeys.verificationPending.tr);
                              }
                            },
                          ),
                        SettingButton(
                          title: LKeys.blockList,
                          icon: Icons.block_rounded,
                          iconBgColor: cDarkText,
                          onTap: () => Get.to(() => const BlockListScreen()),
                        ),
                      ]),
                      const SizedBox(height: 20),
                      _sectionHeader(LKeys.savedItems.tr.toUpperCase()),
                      _sectionCard([
                        SettingButton(
                          title: LKeys.savedReels,
                          icon: Icons.video_library_outlined,
                          iconBgColor: cMagenta,
                          onTap: () => Get.to(() => const SavedReelsScreen()),
                        ),
                        SettingButton(
                          title: LKeys.savedPosts,
                          icon: Icons.bookmark_border_rounded,
                          iconBgColor: cGold,
                          onTap: () => Get.to(() => const SavedPostsScreen()),
                        ),
                      ]),
                      const SizedBox(height: 20),
                      _sectionHeader(LKeys.jobBoard.tr.toUpperCase()),
                      _sectionCard([
                        SettingButton(
                          title: LKeys.jobBoard,
                          icon: Icons.work_outline,
                          iconBgColor: cPrimary,
                          onTap: () => Get.to(() => const JobListScreen()),
                        ),
                        SettingButton(
                          title: LKeys.companyPortal,
                          icon: Icons.business_outlined,
                          iconBgColor: cTeal,
                          onTap: () => Get.to(() => const CompanyAuthScreen()),
                        ),
                      ]),
                      const SizedBox(height: 20),
                      _sectionHeader(LKeys.preferences.tr.toUpperCase()),
                      _sectionCard([
                        SettingButton(
                          title: LKeys.languages,
                          icon: Icons.language_rounded,
                          iconBgColor: cCyan,
                          onTap: () => Get.to(() => const LanguagesScreen()),
                        ),
                      ]),
                      const SizedBox(height: 8),
                      GetBuilder<SettingController>(
                          id: controller.notificationID,
                          init: controller,
                          builder: (context) {
                            return SettingButtonWithSwitch(
                              title: LKeys.pushNotification,
                              desc: LKeys.pushNotificationDesc,
                              isOn: controller.isNotification,
                              onChange: controller.changeOfNotification,
                            );
                          }),
                      GetBuilder<SettingController>(
                          id: controller.getInvitedID,
                          init: controller,
                          builder: (context) {
                            return SettingButtonWithSwitch(
                                title: LKeys.getInvitedToRooms,
                                desc: LKeys.getInvitedToRoomsDesc,
                                isOn: controller.isGetInvited,
                                onChange: controller.changeOfGetInvited);
                          }),
                      const SizedBox(height: 20),
                      _sectionHeader(LKeys.womenInTech.tr.toUpperCase()),
                      _sectionCard([
                        SettingButton(
                          title: LKeys.techResources,
                          icon: Icons.rocket_launch_rounded,
                          iconBgColor: cOrange,
                          onTap: () =>
                              Get.to(() => const TechResourcesScreen()),
                        ),
                      ]),
                      const SizedBox(height: 20),
                      _sectionHeader(LKeys.helpSupport.tr.toUpperCase()),
                      _sectionCard([
                        SettingButton(
                          title: LKeys.privacyPolicy,
                          icon: Icons.privacy_tip_outlined,
                          iconBgColor: cNavy,
                          onTap: () =>
                              openSheetWithURL(privacyURL, LKeys.privacyPolicy),
                        ),
                        SettingButton(
                          title: LKeys.termsOfUse,
                          icon: Icons.description_outlined,
                          iconBgColor: cMagenta,
                          onTap: () =>
                              openSheetWithURL(termsURL, LKeys.termsOfUse),
                        ),
                        SettingButton(
                          title: LKeys.faqS,
                          icon: Icons.help_outline_rounded,
                          iconBgColor: cTeal,
                          onTap: () => Get.to(() => const FAQsScreen()),
                        ),
                      ]),
                      const SizedBox(height: 20),
                      _sectionCard([
                        SettingButton(
                          title: LKeys.logOut,
                          icon: Icons.logout_rounded,
                          isNavigationShow: false,
                          isDestructive: true,
                          onTap: controller.logout,
                        ),
                      ]),
                      const SizedBox(height: 24),
                      Center(
                        child: Column(
                          children: [
                            const LogoTag(width: 100),
                            const SizedBox(height: 4),
                            GetBuilder(
                                init: controller,
                                id: 'version',
                                builder: (context) {
                                  return Text(
                                    "${LKeys.version.tr} ${controller.version}",
                                    style: MyTextStyle.gilroyRegular(
                                        color:
                                            cLightText.withValues(alpha: 0.5),
                                        size: 12),
                                  );
                                }),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      _sectionCard([
                        SettingButton(
                          title: LKeys.deleteMyAcc,
                          icon: Icons.delete_outline_rounded,
                          isNavigationShow: false,
                          isDestructive: true,
                          onTap: controller.deleteAccount,
                        ),
                      ]),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8, top: 4),
      child: Text(
        title,
        style: MyTextStyle.gilroySemiBold(
                size: 11, color: cLightText.withValues(alpha: 0.45))
            .copyWith(letterSpacing: 1.5),
      ),
    );
  }

  Widget _activeCompanyIdentityCard(CompanyModeController companyMode) {
    final companyId = companyMode.actingId.value ?? 0;
    final companyName = companyMode.actingName.value;
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cPrimary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cPrimary.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: cPrimary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(Icons.business_rounded,
                    color: cPrimary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Identité entreprise active',
                      style: MyTextStyle.gilroySemiBold(
                          size: 11, color: cLightText),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      companyName.isEmpty ? 'Entreprise ITGA' : companyName,
                      style: MyTextStyle.gilroyBold(size: 15, color: cDarkText),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Vos publications, tchats, salons et espaces compatibles utilisent cette identité.',
            style: MyTextStyle.gilroyRegular(size: 12, color: cLightText),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: companyId <= 0
                      ? null
                      : () => Get.to(
                          () => CompanyDashboardScreen(companyId: companyId)),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: cWhite,
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: cPrimary.withValues(alpha: 0.18)),
                    ),
                    alignment: Alignment.center,
                    child: Text('Dashboard',
                        style: MyTextStyle.gilroySemiBold(
                            size: 13, color: cPrimary)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: companyMode.deactivate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: cDarkText.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text('Désactiver',
                        style: MyTextStyle.gilroySemiBold(
                            size: 13, color: cDarkText)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionCard(List<Widget> children) {
    final filtered = children.whereType<Widget>().toList();
    return Container(
      decoration: BoxDecoration(
        color: cLightBg,
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: List.generate(filtered.length * 2 - 1, (index) {
          if (index.isOdd) {
            return Padding(
              padding: const EdgeInsets.only(left: 56),
              child: Divider(
                  height: 1,
                  thickness: 0.5,
                  color: cLightText.withValues(alpha: 0.08)),
            );
          }
          return filtered[index ~/ 2];
        }),
      ),
    );
  }

  void openSheetWithURL(String url, String title) {
    Navigate.openURLSheet(title: title, url: url);
  }
}

class SettingButton extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Color? iconBgColor;
  final Function()? onTap;
  final bool isNavigationShow;
  final bool isDestructive;

  const SettingButton({
    Key? key,
    required this.title,
    this.icon,
    this.iconBgColor,
    this.onTap,
    this.isNavigationShow = true,
    this.isDestructive = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final textColor = isDestructive ? cRed : cDarkText;
    final effectiveIconColor = isDestructive ? cRed : cWhite;
    final effectiveIconBg = isDestructive
        ? cRed.withValues(alpha: 0.12)
        : (iconBgColor ?? cLightText);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(
          children: [
            if (icon != null) ...[
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: effectiveIconBg,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Icon(icon,
                    color: isDestructive ? cRed : effectiveIconColor, size: 18),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                title.tr,
                style: MyTextStyle.gilroySemiBold(size: 15, color: textColor),
              ),
            ),
            if (isNavigationShow)
              Icon(
                Icons.chevron_right_rounded,
                color: cLightText.withValues(alpha: 0.3),
                size: 22,
              ),
          ],
        ),
      ),
    );
  }
}

class SettingButtonWithSwitch extends StatelessWidget {
  final String title;
  final String desc;
  final bool isOn;
  final Function(bool) onChange;

  const SettingButtonWithSwitch(
      {Key? key,
      required this.title,
      required this.desc,
      required this.isOn,
      required this.onChange})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const ShapeDecoration(
          shape: SmoothRectangleBorder(
              borderRadius: SmoothBorderRadius.all(SmoothRadius(
                  cornerRadius: 8, cornerSmoothing: cornerSmoothing))),
          color: cLightBg),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.tr,
                  style: MyTextStyle.gilroySemiBold(size: 17, color: cDarkText),
                ),
                Text(
                  desc.tr,
                  style: MyTextStyle.gilroyRegular(size: 15, color: cLightText),
                ),
              ],
            ),
          ),
          const SizedBox(width: 15),
          CupertinoSwitch(
            activeTrackColor: cPrimary,
            value: isOn,
            onChanged: onChange,
          )
        ],
      ),
    );
  }
}
