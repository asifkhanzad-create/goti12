import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'sound_manager.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool _soundEnabled;
  late bool _vibrationEnabled;

  @override
  void initState() {
    super.initState();
    _soundEnabled = SoundManager.instance.soundEnabled;
    _vibrationEnabled = SoundManager.instance.hapticsEnabled;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: const Text(
          'SETTINGS',
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
              top: -40,
              right: -30,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.playerStart.withValues(alpha: 0.12),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                children: [
                  _SettingTile(
                    icon: Icons.volume_up_rounded,
                    title: 'Sound Effects',
                    subtitle: 'Play audio during slides, taps & captures',
                    value: _soundEnabled,
                    gradient: AppColors.playerGradient,
                    textColor: AppColors.playerDeep,
                    glowColor: AppColors.playerStart,
                    onChanged: (v) {
                      setState(() => _soundEnabled = v);
                      SoundManager.instance.soundEnabled = v;
                    },
                  ),
                  const SizedBox(height: 14),
                  _SettingTile(
                    icon: Icons.vibration_rounded,
                    title: 'Haptic Feedback',
                    subtitle: 'Vibrate on piece placement & captures',
                    value: _vibrationEnabled,
                    gradient: AppColors.aiGradient,
                    textColor: AppColors.aiDeep,
                    glowColor: AppColors.aiStart,
                    onChanged: (v) {
                      setState(() => _vibrationEnabled = v);
                      SoundManager.instance.hapticsEnabled = v;
                    },
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceGlass,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.borderGlass),
                    ),
                    child: const Text(
                      '12 GOTI v1.0.0',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingTile extends StatefulWidget {
  const _SettingTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.gradient,
    required this.textColor,
    required this.glowColor,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final Gradient gradient;
  final Color textColor;
  final Color glowColor;
  final ValueChanged<bool> onChanged;

  @override
  State<_SettingTile> createState() => _SettingTileState();
}

class _SettingTileState extends State<_SettingTile> {
  bool _pressed = false;

  void _setPressed(bool v) => setState(() => _pressed = v);

  @override
  Widget build(BuildContext context) {
    final activeColor = widget.glowColor;
    return GestureDetector(
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: () {
        SoundManager.instance.playTap();
        widget.onChanged(!widget.value);
      },
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceGlass,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.value ? activeColor.withValues(alpha: 0.4) : AppColors.borderGlass,
            ),
            boxShadow: [
              if (widget.value)
                BoxShadow(
                  color: activeColor.withValues(alpha: 0.15),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: widget.value ? widget.gradient : null,
                  color: widget.value ? null : AppColors.surfaceGlass,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.icon,
                  color: widget.value ? widget.textColor : AppColors.textMuted,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.subtitle,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: widget.value,
                activeThumbColor: activeColor,
                activeTrackColor: activeColor.withValues(alpha: 0.35),
                inactiveThumbColor: AppColors.textMuted,
                inactiveTrackColor: AppColors.surfaceGlass,
                onChanged: (v) {
                  SoundManager.instance.playTap();
                  widget.onChanged(v);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
