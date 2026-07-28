import 'package:flutter/material.dart';
import 'animated_press_button.dart';
import 'app_colors.dart';
import 'appearance_manager.dart';
import 'game_theme.dart';
import 'sound_manager.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context) => _SettingsScaffold(
    title: 'SETTINGS',
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedPressButton(
            label: 'Sound & Haptics',
            gradient: AppColors.playerGradient,
            textColor: AppColors.playerDeep,
            glowColor: AppColors.playerStart,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const SoundHapticsSettingsScreen(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          AnimatedPressButton(
            label: 'Themes',
            gradient: AppColors.aiGradient,
            textColor: AppColors.aiDeep,
            glowColor: AppColors.aiStart,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ThemesSettingsScreen()),
            ),
          ),
        ],
      ),
    ),
  );
}

class SoundHapticsSettingsScreen extends StatefulWidget {
  const SoundHapticsSettingsScreen({super.key});
  @override
  State<SoundHapticsSettingsScreen> createState() =>
      _SoundHapticsSettingsScreenState();
}

class _SoundHapticsSettingsScreenState
    extends State<SoundHapticsSettingsScreen> {
  late bool sound;
  late bool haptics;
  @override
  void initState() {
    super.initState();
    sound = SoundManager.instance.soundEnabled;
    haptics = SoundManager.instance.hapticsEnabled;
  }

  @override
  Widget build(BuildContext context) => _SettingsScaffold(
    title: 'SOUND & HAPTICS',
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ToggleSetting(
            icon: Icons.volume_up_rounded,
            title: 'Sound Effects',
            subtitle: 'Play audio during slides, taps & captures',
            value: sound,
            color: AppColors.playerStart,
            onChanged: (value) {
              setState(() => sound = value);
              SoundManager.instance.soundEnabled = value;
            },
          ),
          const SizedBox(height: 14),
          _ToggleSetting(
            icon: Icons.vibration_rounded,
            title: 'Haptic Feedback',
            subtitle: 'Vibrate on piece placement & captures',
            value: haptics,
            color: AppColors.playerStart,
            onChanged: (value) {
              setState(() => haptics = value);
              SoundManager.instance.hapticsEnabled = value;
            },
          ),
        ],
      ),
    ),
  );
}

class ThemesSettingsScreen extends StatefulWidget {
  const ThemesSettingsScreen({super.key});
  @override
  State<ThemesSettingsScreen> createState() => _ThemesSettingsScreenState();
}

class _ThemesSettingsScreenState extends State<ThemesSettingsScreen> {
  @override
  Widget build(BuildContext context) => _SettingsScaffold(
    title: 'THEMES',
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ThemeSetting(
            icon: AppearanceManager.isLight
                ? Icons.light_mode_rounded
                : Icons.dark_mode_rounded,
            title: 'App Appearance',
            value: AppearanceManager.isLight ? 'Light mode' : 'Dark mode',
            onTap: _showAppearance,
          ),
          const SizedBox(height: 26),
          Text(
            'BOARD THEMES',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              letterSpacing: 1.4,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ValueListenableBuilder<GameBoardTheme>(
              valueListenable: GameThemeManager.selected,
              builder: (context, selected, _) => GridView.builder(
                padding: const EdgeInsets.only(bottom: 12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: .76,
                ),
                itemCount: GameThemes.all.length,
                itemBuilder: (context, index) {
                  final theme = GameThemes.all[index];
                  return _ThemeGalleryCard(
                    theme: theme,
                    selected: theme.id == selected.id,
                    onTap: () {
                      SoundManager.instance.playTap();
                      GameThemeManager.select(theme);
                      setState(() {});
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Future<void> _showAppearance() => showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.background,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => ValueListenableBuilder<AppAppearance>(
      valueListenable: AppearanceManager.selected,
      builder: (context, selected, _) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 22, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final option in AppAppearance.values)
              _ChoiceRow(
                label: option == AppAppearance.light ? 'Light' : 'Dark',
                icon: option == AppAppearance.light
                    ? Icons.light_mode_rounded
                    : Icons.dark_mode_rounded,
                selected: selected == option,
                color: AppColors.aiStart,
                onTap: () {
                  AppearanceManager.select(option);
                  setState(() {});
                },
              ),
          ],
        ),
      ),
    ),
  );
}

class _ThemeGalleryCard extends StatefulWidget {
  const _ThemeGalleryCard({
    required this.theme,
    required this.selected,
    required this.onTap,
  });
  final GameBoardTheme theme;
  final bool selected;
  final VoidCallback onTap;
  @override
  State<_ThemeGalleryCard> createState() => _ThemeGalleryCardState();
}

class _ThemeGalleryCardState extends State<_ThemeGalleryCard> {
  var _pressed = false;
  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? .96 : 1,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: AppColors.surfaceGlass,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: widget.selected ? theme.boardLine : AppColors.borderGlass,
              width: widget.selected ? 2 : 1,
            ),
            boxShadow: [
              if (widget.selected)
                BoxShadow(
                  color: theme.boardLine.withValues(alpha: .22),
                  blurRadius: 16,
                  spreadRadius: 1,
                ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: CustomPaint(
                            painter: _ThemeThumbnailPainter(theme),
                          ),
                        ),
                      ),
                      if (widget.selected)
                        Positioned(
                          top: 7,
                          right: 7,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: theme.boardLine,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.check_rounded,
                              color: theme.background,
                              size: 16,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 9),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Text(
                    theme.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Text(
                    widget.selected ? 'Selected' : theme.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: widget.selected
                          ? theme.boardLine
                          : AppColors.textMuted,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ThemeThumbnailPainter extends CustomPainter {
  _ThemeThumbnailPainter(this.theme);
  final GameBoardTheme theme;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = theme.background);
    if (theme.hasScenery) {
      final mountain = Paint()
        ..color = const Color(0xFF0B3C59).withValues(alpha: .82);
      final horizon = size.height * .63;
      canvas.drawPath(
        Path()
          ..moveTo(0, horizon)
          ..lineTo(size.width * .26, size.height * .28)
          ..lineTo(size.width * .55, horizon)
          ..close(),
        mountain,
      );
      canvas.drawPath(
        Path()
          ..moveTo(size.width * .42, horizon)
          ..lineTo(size.width * .78, size.height * .36)
          ..lineTo(size.width, horizon)
          ..close(),
        mountain,
      );
      final trees = Paint()
        ..color = const Color(0xFF082B45).withValues(alpha: .9);
      for (var x = -8.0; x < size.width + 10; x += 15) {
        canvas.drawPath(
          Path()
            ..moveTo(x, size.height)
            ..lineTo(x + 7, size.height * .71)
            ..lineTo(x + 14, size.height)
            ..close(),
          trees,
        );
      }
    }
    final margin = size.width * .10;
    final span = size.width - margin * 2;
    final line = Paint()
      ..color = theme.boardLine
      ..strokeWidth = theme.lineWidth.clamp(1, 2.5);
    Offset point(int x, int y) =>
        Offset(margin + span * x / 4, margin + span * y / 4);
    for (var i = 0; i <= 4; i++) {
      canvas.drawLine(point(i, 0), point(i, 4), line);
      canvas.drawLine(point(0, i), point(4, i), line);
    }
    for (final block in const [(0, 0), (2, 0), (0, 2), (2, 2)]) {
      canvas.drawLine(
        point(block.$1, block.$2),
        point(block.$1 + 2, block.$2 + 2),
        line,
      );
      canvas.drawLine(
        point(block.$1 + 2, block.$2),
        point(block.$1, block.$2 + 2),
        line,
      );
    }
    void piece(int x, int y, Color color, Color shade) {
      final p = point(x, y);
      canvas.drawCircle(
        p,
        size.width * .065,
        Paint()
          ..color = color
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
      canvas.drawCircle(p, size.width * .045, Paint()..color = shade);
      canvas.drawCircle(
        Offset(p.dx - 1, p.dy - 1),
        size.width * .034,
        Paint()..color = color,
      );
    }

    for (var x = 0; x <= 4; x++) {
      piece(x, 0, theme.opponent, theme.opponentShade);
      piece(x, 4, theme.player, theme.playerShade);
    }
  }

  @override
  bool shouldRepaint(covariant _ThemeThumbnailPainter oldDelegate) =>
      oldDelegate.theme.id != theme.id;
}

class _SettingsScaffold extends StatelessWidget {
  const _SettingsScaffold({required this.title, required this.child});
  final String title;
  final Widget child;
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      iconTheme: IconThemeData(color: AppColors.textPrimary),
      title: Text(
        title,
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
                    AppColors.playerStart.withValues(alpha: .12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          child,
        ],
      ),
    ),
  );
}

class _ToggleSetting extends StatelessWidget {
  const _ToggleSetting({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.color,
    required this.onChanged,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final Color color;
  final ValueChanged<bool> onChanged;
  @override
  Widget build(BuildContext context) => _Card(
    child: Row(
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
            ],
          ),
        ),
        Switch(value: value, activeThumbColor: color, onChanged: onChanged),
      ],
    ),
  );
}

class _ThemeSetting extends StatelessWidget {
  const _ThemeSetting({
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(16),
    child: _Card(
      child: Row(
        children: [
          Icon(icon, color: AppColors.aiStart),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
        ],
      ),
    ),
  );
}

class _ChoiceRow extends StatelessWidget {
  const _ChoiceRow({
    required this.label,
    required this.icon,
    required this.selected,
    required this.color,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: _Card(
        borderColor: selected ? color : AppColors.borderGlass,
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              selected ? Icons.check_circle_rounded : Icons.circle_outlined,
              color: selected ? color : AppColors.textMuted,
            ),
          ],
        ),
      ),
    ),
  );
}

class _Card extends StatelessWidget {
  const _Card({required this.child, this.borderColor});
  final Widget child;
  final Color? borderColor;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.surfaceGlass,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: borderColor ?? AppColors.borderGlass),
    ),
    child: child,
  );
}
