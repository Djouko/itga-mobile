import 'package:flutter/material.dart';
import 'package:untitled/utilities/const.dart';

bool jobIsDark(BuildContext context) =>
    MediaQuery.platformBrightnessOf(context) == Brightness.dark;

Color jobSurface(BuildContext context) => jobIsDark(context) ? cDarkBG : cBG;

Color jobCard(BuildContext context) =>
    jobIsDark(context) ? const Color(0xFF1E2130) : cWhite;

Color jobMutedSurface(BuildContext context) =>
    jobIsDark(context) ? const Color(0xFF2A2D3D) : cLightBg;

Color jobMainText(BuildContext context) => jobIsDark(context) ? cWhite : cMainText;

Color jobBodyText(BuildContext context) =>
    jobIsDark(context) ? const Color(0xFFCBD5E1) : cDarkText;

Color jobMutedText(BuildContext context) =>
    jobIsDark(context) ? const Color(0xFF94A3B8) : cLightText;

Color jobBorder(BuildContext context) =>
    jobIsDark(context) ? cWhite.withValues(alpha: 0.08) : cBlack.withValues(alpha: 0.04);

List<BoxShadow> jobCardShadow(BuildContext context) {
  if (jobIsDark(context)) return const [];
  return [
    BoxShadow(
      color: cBlack.withValues(alpha: 0.04),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];
}
