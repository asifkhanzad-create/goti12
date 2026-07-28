import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'animated_press_button.dart';
import 'board_preview.dart';
import 'difficulty_select_screen.dart';
import 'orb_duel_screen.dart';
import 'settings_screen.dart';
import 'how_to_play_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        top: false,
        bottom: false,
        child: Stack(
          children: [
            // ambient glow blobs, top-left teal / bottom-right amber
            Positioned(
              top: -60,
              left: -40,
              child: _GlowBlob(color: AppColors.playerStart),
            ),
            Positioned(
              bottom: -60,
              right: -40,
              child: _GlowBlob(color: AppColors.aiStart),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _TitleBlock(),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: BoardPreview(),
                  ),
                  Column(
                    children: [
                      AnimatedPressButton(
                        label: 'Play vs AI',
                        gradient: AppColors.playerGradient,
                        textColor: AppColors.playerDeep,
                        glowColor: AppColors.playerStart,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const DifficultySelectScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 14),
                      AnimatedPressButton(
                        label: 'Local 2 player',
                        gradient: AppColors.aiGradient,
                        textColor: AppColors.aiDeep,
                        glowColor: AppColors.aiStart,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const OrbDuelScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: AnimatedPressButton(
                              label: 'Settings',
                              gradient: AppColors.playerGradient,
                              textColor: AppColors.playerDeep,
                              glowColor: AppColors.playerStart,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const SettingsScreen(),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: AnimatedPressButton(
                              label: 'How to play',
                              gradient: AppColors.aiGradient,
                              textColor: AppColors.aiDeep,
                              glowColor: AppColors.aiStart,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const HowToPlayScreen(),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TitleBlock extends StatelessWidget {
  const _TitleBlock();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '12 GOTI',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 34,
            fontWeight: FontWeight.w700,
            letterSpacing: 3,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'STRATEGY BOARD GAME',
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 12,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _BrandDot(color: AppColors.playerStart),
            const SizedBox(width: 10),
            _BrandDot(color: AppColors.boardCenterDot, glow: false),
            const SizedBox(width: 10),
            _BrandDot(color: AppColors.aiStart),
          ],
        ),
      ],
    );
  }
}

class _BrandDot extends StatelessWidget {
  const _BrandDot({required this.color, this.glow = true});

  final Color color;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: glow
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.6),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
    );
  }
}

class _GlowBlob extends StatelessWidget {
  const _GlowBlob({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      height: 180,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withValues(alpha: 0.15), Colors.transparent],
        ),
      ),
    );
  }
}
