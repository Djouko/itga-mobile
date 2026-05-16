import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:untitled/localization/languages.dart';
import 'package:untitled/models/registration.dart';
import 'package:untitled/utilities/const.dart';

class AchievementBadge {
  final String key;
  final String Function() title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool isEarned;
  final double progress; // 0.0 to 1.0

  const AchievementBadge({
    required this.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.isEarned,
    required this.progress,
  });
}

class AchievementBadges {
  static List<AchievementBadge> computeBadges(User? user, {int postCount = 0, int reelCount = 0}) {
    if (user == null) return [];

    final followers = (user.followers ?? 0).toInt();
    final following = (user.following ?? 0).toInt();
    final hasProfile = (user.profile ?? '').isNotEmpty;
    final hasBio = (user.bio ?? '').isNotEmpty;
    final hasHeadline = (user.headline ?? '').isNotEmpty;
    final hasSkills = (user.skills ?? '').isNotEmpty;
    final hasExperience = (user.experience ?? '').isNotEmpty;
    final hasEducation = (user.education ?? '').isNotEmpty;
    final isVerified = (user.isVerified ?? 0).toInt() >= 2;

    return [
      // Newcomer — joined and set up profile
      AchievementBadge(
        key: 'newcomer',
        title: () => LKeys.badgeNewcomer.tr,
        subtitle: 'Complete your profile setup',
        icon: Icons.emoji_events_rounded,
        color: cTeal,
        isEarned: hasProfile && hasBio,
        progress: _clamp(((hasProfile ? 0.5 : 0) + (hasBio ? 0.5 : 0))),
      ),

      // Contributor — created 5+ posts or reels
      AchievementBadge(
        key: 'contributor',
        title: () => LKeys.badgeContributor.tr,
        subtitle: 'Create 5+ posts or reels',
        icon: Icons.create_rounded,
        color: cNavy,
        isEarned: (postCount + reelCount) >= 5,
        progress: _clamp((postCount + reelCount) / 5),
      ),

      // Influencer — 50+ followers
      AchievementBadge(
        key: 'influencer',
        title: () => LKeys.badgeInfluencer.tr,
        subtitle: 'Reach 50+ followers',
        icon: Icons.trending_up_rounded,
        color: cMagenta,
        isEarned: followers >= 50,
        progress: _clamp(followers / 50),
      ),

      // Mentor — following 20+ people (actively connecting)
      AchievementBadge(
        key: 'mentor',
        title: () => LKeys.badgeMentor.tr,
        subtitle: 'Follow 20+ people & build your network',
        icon: Icons.people_rounded,
        color: cOrange,
        isEarned: following >= 20,
        progress: _clamp(following / 20),
      ),

      // Leader — complete LinkedIn-style profile (headline + skills + experience)
      AchievementBadge(
        key: 'leader',
        title: () => LKeys.badgeLeader.tr,
        subtitle: 'Add headline, skills & experience',
        icon: Icons.workspace_premium_rounded,
        color: cRed,
        isEarned: hasHeadline && hasSkills && hasExperience,
        progress: _clamp(((hasHeadline ? 0.33 : 0) + (hasSkills ? 0.33 : 0) + (hasExperience ? 0.34 : 0))),
      ),

      // Trailblazer — 200+ followers + verified
      AchievementBadge(
        key: 'trailblazer',
        title: () => LKeys.badgeTrailblazer.tr,
        subtitle: 'Get verified & reach 200+ followers',
        icon: Icons.local_fire_department_rounded,
        color: cGold,
        isEarned: isVerified && followers >= 200,
        progress: _clamp(((isVerified ? 0.5 : 0) + (followers >= 200 ? 0.5 : followers / 400))),
      ),

      // Pioneer — all-rounder: profile + education + skills + 500+ followers
      AchievementBadge(
        key: 'pioneer',
        title: () => LKeys.badgePioneer.tr,
        subtitle: 'Complete profile + 500 followers',
        icon: Icons.rocket_launch_rounded,
        color: cPrimary,
        isEarned: hasEducation && hasSkills && hasExperience && followers >= 500,
        progress: _clamp(((hasEducation ? 0.15 : 0) + (hasSkills ? 0.15 : 0) + (hasExperience ? 0.15 : 0) + (followers >= 500 ? 0.55 : followers / 909))),
      ),
    ];
  }

  static double _clamp(double value) => value.clamp(0.0, 1.0);

  static int earnedCount(User? user, {int postCount = 0, int reelCount = 0}) {
    return computeBadges(user, postCount: postCount, reelCount: reelCount).where((b) => b.isEarned).length;
  }
}
