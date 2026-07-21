import 'package:flutter/material.dart';

/// Central color palette for the 12 Goti app.
/// Keep every screen pulling from here so the theme stays consistent
/// as we add more screens (board, settings, etc).
class AppColors {
  AppColors._();

  // Background
  static const Color background = Color(0xFF0A0E1A);
  static const Color surfaceGlass = Color(0x0FFFFFFF); // frosted glass fill
  static const Color borderGlass = Color(0x1AFFFFFF); // frosted glass border

  // Player (you) — teal/sea-green
  static const Color playerStart = Color(0xFF5EEAD4);
  static const Color playerEnd = Color(0xFF22D3EE);
  static const Color playerDeep = Color(0xFF062824); // text-on-teal / bevel shadow

  // AI opponent — amber
  static const Color aiStart = Color(0xFFFFB84D);
  static const Color aiEnd = Color(0xFFFF8C1A);
  static const Color aiDeep = Color(0xFF2A1B06); // text-on-amber / bevel shadow

  // Board
  static const Color boardLine = Color(0xFF2A3550);
  static const Color boardCenterDot = Color(0xFF3A4568);

  // Text
  static const Color textPrimary = Color(0xFFF0F2FA);
  static const Color textSecondary = Color(0xFF9AA2BA);
  static const Color textMuted = Color(0xFF6B7490);

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
