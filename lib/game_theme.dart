import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Visual treatment for the game board. Kept separate from game rules so a
/// theme can change the whole board without affecting play.
class GameBoardTheme {
  const GameBoardTheme({
    required this.id,
    required this.name,
    required this.description,
    required this.background,
    required this.boardSurface,
    required this.hasScenery,
    required this.boardLine,
    required this.centerDot,
    required this.player,
    required this.opponent,
    required this.playerShade,
    required this.opponentShade,
    required this.lineWidth,
    required this.pieceScale,
    required this.pieceGlow,
    required this.pieceRimAlpha,
  });
  final String id;
  final String name;
  final String description;
  final Color background;
  final Color boardSurface;
  final bool hasScenery;
  final Color boardLine;
  final Color centerDot;
  final Color player;
  final Color opponent;
  final Color playerShade;
  final Color opponentShade;
  final double lineWidth;
  final double pieceScale;
  final double pieceGlow;
  final double pieceRimAlpha;
}

class GameThemes {
  GameThemes._();
  static const neon = GameBoardTheme(
    id: 'neon',
    name: 'Neon Arena',
    description: 'The original teal and amber glow.',
    background: Color(0xFF0A0E1A),
    boardSurface: Color(0xFF0A0E1A),
    hasScenery: false,
    boardLine: Color(0xFF2A3550),
    centerDot: Color(0xFF3A4568),
    player: Color(0xFF5EEAD4),
    opponent: Color(0xFFFFB84D),
    playerShade: Color(0xFF14B8A6),
    opponentShade: Color(0xFFF59E0B),
    lineWidth: 1.5,
    pieceScale: 1.0,
    pieceGlow: 1.0,
    pieceRimAlpha: .28,
  );
  static const royal = GameBoardTheme(
    id: 'royal',
    name: 'Royal Court',
    description: 'Parchment, gilt lines, and jewel-toned pieces.',
    background: Color(0xFF1B1722),
    boardSurface: Color(0xFF281F2A),
    hasScenery: false,
    boardLine: Color(0xFFD8B66B),
    centerDot: Color(0xFFF6D98E),
    player: Color(0xFF6E7FEF),
    opponent: Color(0xFFC94F63),
    playerShade: Color(0xFF303E9D),
    opponentShade: Color(0xFF772536),
    lineWidth: 1.5,
    pieceScale: 1.1,
    pieceGlow: 1.22,
    pieceRimAlpha: 0,
  );
  static const classic = GameBoardTheme(
    id: 'classic',
    name: 'Classic Valley',
    description: 'Scenic teal board with bright lines and warm pieces.',
    background: Color(0xFF102B46),
    boardSurface: Color(0xFF166878),
    hasScenery: true,
    boardLine: Color(0xFFF4F7FF),
    centerDot: Color(0xFFF8D984),
    player: Color(0xFFEF1B2D),
    opponent: Color(0xFFFFEA00),
    playerShade: Color(0xFF9B1020),
    opponentShade: Color(0xFFC7B200),
    lineWidth: 1.5,
    pieceScale: 1.1,
    pieceGlow: 1.22,
    pieceRimAlpha: 0,
  );
  static const all = [neon, royal, classic];
}

class GameThemeManager {
  GameThemeManager._();
  static const _storageKey = 'board_theme';
  static final ValueNotifier<GameBoardTheme> selected = ValueNotifier(
    GameThemes.neon,
  );
  static SharedPreferences? _preferences;
  static GameBoardTheme get current => selected.value;
  static Future<void> initialize() async {
    _preferences = await SharedPreferences.getInstance();
    final saved = _preferences!.getString(_storageKey);
    selected.value = GameThemes.all.firstWhere(
      (theme) => theme.id == saved,
      orElse: () => GameThemes.neon,
    );
  }

  static void select(GameBoardTheme theme) {
    if (selected.value.id == theme.id) return;
    selected.value = theme;
    _preferences?.setString(_storageKey, theme.id);
  }
}
