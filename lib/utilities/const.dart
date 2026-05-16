import 'package:flutter/material.dart';

const String appName = "ITGA.";
const String baseURL = "https://itga.kekottech.com/";
const String itemBaseURL = "";
const String apiURL = "${baseURL}api/";
const String termsURL = "${baseURL}termsOfUse";
const String privacyURL = "${baseURL}privacyPolicy";
const String helpURL = "http://www.yourHelpURL.com";
const String notificationTopic = "itga"; // Do not change it

const String revenuecatAppleApiKey = '';
const String revenuecatAndroidApiKey = '';

const String agoraAppId = '9bfaecd4e3b34b91a3953ed07f5133b2';
const String agoraCustomerId = '0865e48c18f54126aaa0544e270b1429';

class Limits {
  static int username = 30;
  static int roomDescCount = 120;
  static int bioCount = 120;
  static int interestCount = 5;
  static int pagination = 20;
  static int storyDuration = 3;

  static int sightEngineCropSec = 5;

  static double imageSize = 720;
  static int quality = 50;
}

const List<String> storyQuickReplyEmojis = ['😂', '😮', '😍', '😢', '👏', '🔥'];
const List<int> secondsForMakingReel = [15, 30];

extension O on String {
  String addBaseURL() {
    return itemBaseURL + this;
  }
}

// ─── ITGA Brand Palette ───────────────────────────────────────────
const cPrimary = Color(0xFF2AABAB);      // Teal — main brand color
const cPulsing = Color(0xFF5DCCC6);      // Cyan clair — loading/pulsing
const cHashtagColor = Color(0xFF1B3A5C); // Navy — hashtags, links
const cWhite = Colors.white;
const cBlack = Color(0xFF0E0E0E);
const cBlackSheetBG = Color(0xFF1A1A2E); // Deep navy-black for sheets
const cMainText = Color(0xFF1B2838);     // Near-navy for readable text
const cLightText = Color(0xFF8A95A5);    // Muted blue-grey
const cLightIcon = Color(0xFFAEB8C4);    // Soft blue-grey icons
const cDarkText = Color(0xFF4A5568);     // Mid blue-grey
const cLightBg = Color(0xFFF0F4F8);     // Cool light background
const cDarkBG = Color(0xFF1A1A2E);      // Deep navy dark mode
const cBG = Color(0xFFF5F7FA);          // Cool off-white
const cGreen = Color(0xFF2AABAB);       // Alias for cPrimary (teal)
const cDarkGreen = Color(0xFF1B3A5C);   // Navy — replaces old dark green
const cBlueTick = Color(0xFF1D9BF0);    // Verified badge blue
const cRed = Color(0xFFE53E3E);         // Error/danger red

// ─── ITGA Accent Colors ──────────────────────────────────────────
const cNavy = Color(0xFF1B3A5C);         // Navy — headers, depth
const cTeal = Color(0xFF2AABAB);         // Teal — primary actions
const cCyan = Color(0xFF5DCCC6);         // Cyan — highlights, active
const cMagenta = Color(0xFFC62168);      // Magenta — likes, hearts, CTAs
const cOrange = Color(0xFFE87722);       // Orange — warnings, badges
const cGold = Color(0xFFF5C040);         // Gold — achievements, premium

// ─── Audio Space ─────────────────────────────────────────────────
const cAudioSpaceBG = Color(0xFF1A1A2E);
const cAudioSpaceDarkBG = Color(0xFF141428);
const cAudioSpaceLightBG = Color(0xFF2A2A4A);
const cAudioSpaceText = Color(0xFFD4D4E8);

const refreshIndicatorColor = cWhite;
const refreshIndicatorBgColor = cPrimary;

// Corner Radius-Smoothing
const cornerSmoothing = 1.0;
