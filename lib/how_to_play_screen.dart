import 'package:flutter/material.dart';
import 'app_colors.dart';

class HowToPlayScreen extends StatelessWidget {
  const HowToPlayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
        title: Text(
          'HOW TO PLAY',
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
        child: Stack(
          children: [
            // Ambient glow blob
            Positioned(
              bottom: -40,
              left: -30,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.aiStart.withValues(alpha: 0.12),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  _RuleCard(
                    icon: Icons.grid_4x4_rounded,
                    title: 'Objective',
                    description:
                        '12 Goti (Barah Guti) is a classic strategy board game. Capture all 12 of your opponent’s pieces to win.',
                    accentColor: AppColors.playerStart,
                  ),
                  SizedBox(height: 14),
                  _RuleCard(
                    icon: Icons.open_with_rounded,
                    title: 'Basic Movement',
                    description:
                        'Take turns sliding one piece along a grid line to an adjacent empty point.',
                    accentColor: AppColors.playerStart,
                  ),
                  SizedBox(height: 14),
                  _RuleCard(
                    icon: Icons.sports_score_rounded,
                    title: 'Capturing Pieces',
                    description:
                        'Jump over an opponent’s adjacent piece into an empty point behind it to capture it.',
                    accentColor: AppColors.aiStart,
                  ),
                  SizedBox(height: 14),
                  _RuleCard(
                    icon: Icons.alt_route_rounded,
                    title: 'Multi-Hop Chain Jumps',
                    description:
                        'If your piece lands in a position where another jump exists, keep hopping in the same turn!',
                    accentColor: AppColors.aiStart,
                  ),
                  SizedBox(height: 14),
                  _RuleCard(
                    icon: Icons.emoji_events_rounded,
                    title: 'Winning Condition',
                    description:
                        'Eliminate all 12 enemy pieces or block your opponent so they have no legal moves.',
                    accentColor: AppColors.playerStart,
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

class _RuleCard extends StatelessWidget {
  const _RuleCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.accentColor,
  });

  final IconData icon;
  final String title;
  final String description;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceGlass,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderGlass),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: accentColor, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
