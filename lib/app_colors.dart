import 'package:flutter/material.dart';
import 'appearance_manager.dart';

/// Central app palette. Board-specific colours live in game_theme.dart.
class AppColors {
  AppColors._();

  static Color get background => AppearanceManager.isLight
      ? const Color(0xFFF4F7FC)
      : const Color(0xFF0A0E1A);
  static Color get surfaceGlass => AppearanceManager.isLight
      ? const Color(0xFFE5EAF3)
      : const Color(0x0FFFFFFF);
  static Color get borderGlass => AppearanceManager.isLight
      ? const Color(0xFFCCD5E3)
      : const Color(0x1AFFFFFF);

  static const Color playerStart = Color(0xFF5EEAD4);
  static const Color playerEnd = Color(0xFF22D3EE);
  static const Color playerDeep = Color(0xFF062824);
  static const Color aiStart = Color(0xFFFFB84D);
  static const Color aiEnd = Color(0xFFFF8C1A);
  static const Color aiDeep = Color(0xFF2A1B06);
  static const Color boardLine = Color(0xFF2A3550);
  static const Color boardCenterDot = Color(0xFF3A4568);

  static Color get textPrimary => AppearanceManager.isLight
      ? const Color(0xFF15223A)
      : const Color(0xFFF0F2FA);
  static Color get textSecondary => AppearanceManager.isLight
      ? const Color(0xFF53627A)
      : const Color(0xFF9AA2BA);
  static Color get textMuted => AppearanceManager.isLight
      ? const Color(0xFF68768C)
      : const Color(0xFF6B7490);

  static const LinearGradient playerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [playerStart, playerEnd],
  );
  static const LinearGradient aiGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [aiStart, aiEnd],
  );
}
