import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'animated_press_button.dart';
import 'ai_engine.dart';
import 'orb_duel_screen.dart';

/// Shown after "Play vs AI" — lets the player pick a difficulty before
/// starting the game. Reuses the same button widgets/theme as the home
/// screen so it feels like part of the same flow, not a separate screen.
class DifficultySelectScreen extends StatelessWidget {
  const DifficultySelectScreen({super.key});

  void _start(BuildContext context, Difficulty difficulty) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => OrbDuelScreen(difficulty: difficulty)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
        title: Text(
          'SELECT DIFFICULTY',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Choose how sharp the AI plays.',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 13,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 32),
              AnimatedPressButton(
                label: 'Easy',
                gradient: AppColors.playerGradient,
                textColor: AppColors.playerDeep,
                glowColor: AppColors.playerStart,
                onTap: () => _start(context, Difficulty.easy),
              ),
              const SizedBox(height: 14),
              AnimatedPressButton(
                label: 'Medium',
                gradient: AppColors.playerGradient,
                textColor: AppColors.playerDeep,
                glowColor: AppColors.playerStart,
                onTap: () => _start(context, Difficulty.medium),
              ),
              const SizedBox(height: 14),
              AnimatedPressButton(
                label: 'Hard',
                gradient: AppColors.aiGradient,
                textColor: AppColors.aiDeep,
                glowColor: AppColors.aiStart,
                onTap: () => _start(context, Difficulty.hard),
              ),
              const SizedBox(height: 14),
              AnimatedPressButton(
                label: 'Master',
                gradient: AppColors.aiGradient,
                textColor: AppColors.aiDeep,
                glowColor: AppColors.aiStart,
                onTap: () => _start(context, Difficulty.master),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
