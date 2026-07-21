import 'package:flutter/material.dart';
import 'app_colors.dart';

/// A button that visibly "presses" inward when tapped — scales down slightly,
/// softens its glow/shadow, and springs back on release.
///
/// Used for the primary "Play vs AI" CTA on the home screen, and reusable
/// for any other important tap target (board pieces, secondary buttons)
/// later so the whole app feels tactile and consistent.
class AnimatedPressButton extends StatefulWidget {
  const AnimatedPressButton({
    super.key,
    required this.label,
    required this.onTap,
    this.gradient = AppColors.playerGradient,
    this.textColor = AppColors.playerDeep,
    this.glowColor = AppColors.playerStart,
  });

  final String label;
  final VoidCallback onTap;
  final Gradient gradient;
  final Color textColor;
  final Color glowColor;

  @override
  State<AnimatedPressButton> createState() => _AnimatedPressButtonState();
}

class _AnimatedPressButtonState extends State<AnimatedPressButton> {
  bool _pressed = false;

  void _setPressed(bool value) => setState(() => _pressed = value);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: widget.gradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: _pressed
                ? [
                    // pressed: glow tucks in close, feels flatter
                    BoxShadow(
                      color: widget.glowColor.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [
                    // resting: soft outer glow lifts the button off the bg
                    BoxShadow(
                      color: widget.glowColor.withValues(alpha: 0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
          ),
          child: Center(
            child: Text(
              widget.label,
              style: TextStyle(
                color: widget.textColor,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Softer glass-style secondary button (e.g. "Local 2 player", "Settings").
class GlassButton extends StatefulWidget {
  const GlassButton({
    super.key,
    required this.label,
    required this.onTap,
    this.fontSize = 15,
  });

  final String label;
  final VoidCallback onTap;
  final double fontSize;

  @override
  State<GlassButton> createState() => _GlassButtonState();
}

class _GlassButtonState extends State<GlassButton> {
  bool _pressed = false;

  void _setPressed(bool value) => setState(() => _pressed = value);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: _pressed ? AppColors.surfaceGlass.withValues(alpha: 0.2) : AppColors.surfaceGlass,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderGlass),
          ),
          child: Center(
            child: Text(
              widget.label,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: widget.fontSize,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
