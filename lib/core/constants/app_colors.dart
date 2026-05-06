import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF111111);
  static const Color background = Color(0xFFF7F8FA);
  static const Color accent = Color(0xFF007AFF);
  static const Color accentLight = Color(0xFFE8F2FF);

  static const Color grey50 = Color(0xFFF5F6F8);
  static const Color grey100 = Color(0xFFE9EBEF);
  static const Color grey200 = Color(0xFFD8DCE2);
  static const Color grey300 = Color(0xFFB8BEC8);
  static const Color grey400 = Color(0xFF8E95A3);
  static const Color grey500 = Color(0xFF667085);
  static const Color grey700 = Color(0xFF344054);

  static const Color success = Color(0xFF22A06B);
  static const Color warning = Color(0xFFFFB020);
  static const Color error = Color(0xFFE5484D);
  static const Color info = Color(0xFF3E7BFA);

  static const Color clientRole = Color(0xFF007AFF);
  static const Color driverRole = Color(0xFF22A06B);
  static const Color adminRole = Color(0xFF111111);

  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color page(BuildContext context) =>
      isDark(context) ? const Color(0xFF101418) : background;

  static Color surface(BuildContext context) =>
      isDark(context) ? const Color(0xFF171C22) : white;

  static Color surfaceAlt(BuildContext context) =>
      isDark(context) ? const Color(0xFF202630) : grey50;

  static Color border(BuildContext context) =>
      isDark(context) ? const Color(0xFF2A323D) : grey100;

  static Color textPrimary(BuildContext context) =>
      isDark(context) ? const Color(0xFFF5F7FA) : black;

  static Color textSecondary(BuildContext context) =>
      isDark(context) ? const Color(0xFFAAB2C0) : grey500;
}
