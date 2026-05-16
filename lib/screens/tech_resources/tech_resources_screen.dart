import 'package:figma_squircle_updated/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled/common/extensions/font_extension.dart';
import 'package:untitled/common/managers/navigation.dart';
import 'package:untitled/common/managers/session_manager.dart';
import 'package:untitled/common/utils/achievement_badges.dart';
import 'package:untitled/localization/languages.dart';
import 'package:untitled/screens/extra_views/top_bar.dart';
import 'package:untitled/utilities/const.dart';

class TechResourcesScreen extends StatelessWidget {
  const TechResourcesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = SessionManager.shared.getUser();
    final badges = AchievementBadges.computeBadges(user);
    final earnedCount = badges.where((b) => b.isEarned).length;

    return Scaffold(
      body: Column(
        children: [
          const TopBarForInView(title: LKeys.womenInTech),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: SafeArea(
                top: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _heroCard(earnedCount, badges.length),
                    const SizedBox(height: 24),
                    _sectionTitle(LKeys.achievements.tr),
                    const SizedBox(height: 10),
                    _badgesGrid(badges),
                    const SizedBox(height: 28),
                    _sectionTitle(LKeys.techResources.tr),
                    const SizedBox(height: 10),
                    _resourceCard(
                      icon: Icons.code_rounded,
                      color: cNavy,
                      title: LKeys.resourcesCoding.tr,
                      subtitle: 'freeCodeCamp, Codecademy, The Odin Project',
                      url: 'https://www.freecodecamp.org/',
                    ),
                    _resourceCard(
                      icon: Icons.leaderboard_rounded,
                      color: cMagenta,
                      title: LKeys.resourcesLeadership.tr,
                      subtitle: 'Women Who Code, Lean In, SheLeads',
                      url: 'https://www.womenwhocode.com/',
                    ),
                    _resourceCard(
                      icon: Icons.groups_rounded,
                      color: cOrange,
                      title: LKeys.resourcesNetworking.tr,
                      subtitle: 'WomenTech Network, AnitaB.org, Tech Ladies',
                      url: 'https://www.womentech.net/',
                    ),
                    _resourceCard(
                      icon: Icons.trending_up_rounded,
                      color: cTeal,
                      title: LKeys.resourcesCareer.tr,
                      subtitle: 'LinkedIn, Glassdoor, Built By Girls',
                      url: 'https://www.builtbygirls.com/',
                    ),
                    _resourceCard(
                      icon: Icons.self_improvement_rounded,
                      color: cMagenta,
                      title: LKeys.resourcesWellbeing.tr,
                      subtitle: 'Headspace, Calm, TechWomen Balance',
                      url: 'https://www.headspace.com/',
                    ),
                    _resourceCard(
                      icon: Icons.auto_awesome_rounded,
                      color: cPrimary,
                      title: LKeys.resourcesInspiration.tr,
                      subtitle: 'TED Women, Technovation, Girls Who Code',
                      url: 'https://girlswhocode.com/',
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroCard(int earned, int total) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: ShapeDecoration(
        shape: const SmoothRectangleBorder(
          borderRadius: SmoothBorderRadius.all(SmoothRadius(cornerRadius: 20, cornerSmoothing: cornerSmoothing)),
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [cDarkBG, cNavy.withValues(alpha: 0.85), cNavy],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: cPrimary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.rocket_launch_rounded, color: cPrimary, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      LKeys.womenInTech.tr,
                      style: MyTextStyle.gilroyBold(size: 20, color: cWhite),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      LKeys.careerMilestones.tr,
                      style: MyTextStyle.gilroyRegular(size: 14, color: cWhite.withValues(alpha: 0.6)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _statPill('$earned/$total', LKeys.achievements.tr, cPrimary),
              const SizedBox(width: 10),
              _statPill('${(earned / (total == 0 ? 1 : total) * 100).round()}%', 'Progress', cNavy),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statPill(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: ShapeDecoration(
        shape: const SmoothRectangleBorder(
          borderRadius: SmoothBorderRadius.all(SmoothRadius(cornerRadius: 12, cornerSmoothing: cornerSmoothing)),
        ),
        color: color.withValues(alpha: 0.15),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: MyTextStyle.gilroyBold(size: 16, color: color)),
          const SizedBox(width: 6),
          Text(label, style: MyTextStyle.gilroyRegular(size: 13, color: cWhite.withValues(alpha: 0.7))),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: MyTextStyle.gilroySemiBold(size: 12, color: cLightText.withValues(alpha: 0.5)).copyWith(letterSpacing: 1.2),
    );
  }

  Widget _badgesGrid(List<AchievementBadge> badges) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: badges.map((badge) => _badgeTile(badge)).toList(),
    );
  }

  Widget _badgeTile(AchievementBadge badge) {
    final width = (Get.width - 52) / 2;
    return Container(
      width: width,
      padding: const EdgeInsets.all(14),
      decoration: ShapeDecoration(
        shape: const SmoothRectangleBorder(
          borderRadius: SmoothBorderRadius.all(SmoothRadius(cornerRadius: 16, cornerSmoothing: cornerSmoothing)),
        ),
        color: badge.isEarned ? badge.color.withValues(alpha: 0.1) : cLightBg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: badge.isEarned ? badge.color.withValues(alpha: 0.2) : cLightText.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  badge.icon,
                  color: badge.isEarned ? badge.color : cLightText.withValues(alpha: 0.4),
                  size: 20,
                ),
              ),
              const Spacer(),
              if (badge.isEarned)
                const Icon(Icons.check_circle_rounded, color: cPrimary, size: 18),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            badge.title(),
            style: MyTextStyle.gilroyBold(
              size: 15,
              color: badge.isEarned ? cDarkText : cLightText.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            badge.subtitle,
            style: MyTextStyle.gilroyRegular(
              size: 11,
              color: badge.isEarned ? cDarkText.withValues(alpha: 0.6) : cLightText.withValues(alpha: 0.4),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: badge.progress,
              backgroundColor: cLightText.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation(badge.isEarned ? badge.color : cLightText.withValues(alpha: 0.3)),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _resourceCard({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required String url,
  }) {
    return GestureDetector(
      onTap: () => Navigate.openURLSheet(title: title, url: url),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: ShapeDecoration(
          shape: const SmoothRectangleBorder(
            borderRadius: SmoothBorderRadius.all(SmoothRadius(cornerRadius: 14, cornerSmoothing: cornerSmoothing)),
          ),
          color: cLightBg,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: MyTextStyle.gilroySemiBold(size: 15, color: cDarkText)),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: MyTextStyle.gilroyRegular(size: 12, color: cLightText),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: cLightText.withValues(alpha: 0.4), size: 22),
          ],
        ),
      ),
    );
  }
}
