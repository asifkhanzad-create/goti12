import 'dart:math';
import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'animated_press_button.dart';
import 'ai_engine.dart';
import 'game_state.dart';
import 'game_board_screen.dart';

/// Orb Duel — decides who moves first before a game starts.
///
/// The winner is picked the instant this screen opens (genuinely random,
/// via [Random], not tied to the animation at all) — "Skip" just jumps
/// straight to the already-decided result instead of re-rolling anything.
///
/// Used for both flows:
///  - Play vs AI: difficulty != null
///  - Local 2 player: difficulty == null
class OrbDuelScreen extends StatefulWidget {
  const OrbDuelScreen({super.key, this.difficulty});

  /// Null means local 2-player (no AI).
  final Difficulty? difficulty;

  @override
  State<OrbDuelScreen> createState() => _OrbDuelScreenState();
}

class _OrbDuelScreenState extends State<OrbDuelScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Owner _winner;
  bool _revealed = false;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _winner = Random().nextBool() ? Owner.player : Owner.ai;
    _controller =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 1600),
        )..addStatusListener((status) {
          if (status == AnimationStatus.completed) {
            setState(() => _revealed = true);
          }
        });
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _skip() {
    if (_revealed) return;
    _controller.stop();
    setState(() => _revealed = true);
  }

  void _continue() {
    if (_navigated) return;
    _navigated = true;
    final difficulty = widget.difficulty;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => difficulty != null
            ? GameBoardScreen(difficulty: difficulty, firstTurn: _winner)
            : GameBoardScreen.local(firstTurn: _winner),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    return _OrbDuelVisual(
                      progress: _controller.value,
                      winner: _winner,
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: _revealed
                  ? Column(
                      children: [
                        Text(
                          _winner == Owner.player
                              ? 'YOU GO FIRST'
                              : 'AI GOES FIRST',
                          style: TextStyle(
                            color: _winner == Owner.player
                                ? AppColors.playerStart
                                : AppColors.aiStart,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 20),
                        AnimatedPressButton(
                          label: 'Continue',
                          gradient: _winner == Owner.player
                              ? AppColors.playerGradient
                              : AppColors.aiGradient,
                          textColor: _winner == Owner.player
                              ? AppColors.playerDeep
                              : AppColors.aiDeep,
                          glowColor: _winner == Owner.player
                              ? AppColors.playerStart
                              : AppColors.aiStart,
                          onTap: _continue,
                        ),
                      ],
                    )
                  : GlassButton(label: 'Skip', onTap: _skip),
            ),
          ],
        ),
      ),
    );
  }
}

/// Two orbs charge, clash at the center, then the winner flares while the
/// loser fades out.
class _OrbDuelVisual extends StatelessWidget {
  const _OrbDuelVisual({required this.progress, required this.winner});

  final double progress;
  final Owner winner;

  // Phase boundaries within the overall 0..1 controller progress.
  static const _chargeEnd = 0.35;
  static const _clashEnd = 0.65;

  @override
  Widget build(BuildContext context) {
    const spread = 90.0;
    const orbSize = 56.0;

    double travel; // 0 = starting spread apart, 1 = met at center
    double reveal; // 0 = just met, 1 = fully resolved
    double charge; // 0..1..0 pulsing during the charge phase

    if (progress <= _chargeEnd) {
      final t = progress / _chargeEnd;
      charge = (sin(t * pi * 3) + 1) / 2; // a few quick pulses
      travel = 0.0;
      reveal = 0.0;
    } else if (progress <= _clashEnd) {
      final t = (progress - _chargeEnd) / (_clashEnd - _chargeEnd);
      charge = 0.0;
      travel = Curves.easeIn.transform(t);
      reveal = 0.0;
    } else {
      final t = (progress - _clashEnd) / (1 - _clashEnd);
      charge = 0.0;
      travel = 1.0;
      reveal = Curves.easeOut.transform(t);
    }

    final playerIsWinner = winner == Owner.player;

    final playerDx = -spread * (1 - travel);
    final aiDx = spread * (1 - travel);

    final playerScale =
        1.0 + charge * 0.15 + (playerIsWinner ? reveal * 0.7 : 0.0);
    final aiScale =
        1.0 + charge * 0.15 + (!playerIsWinner ? reveal * 0.7 : 0.0);

    final playerOpacity = playerIsWinner ? 1.0 : (1.0 - reveal).clamp(0.0, 1.0);
    final aiOpacity = !playerIsWinner ? 1.0 : (1.0 - reveal).clamp(0.0, 1.0);

    return SizedBox(
      width: 260,
      height: 160,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.translate(
            offset: Offset(playerDx, 0),
            child: Opacity(
              opacity: playerOpacity,
              child: Transform.scale(
                scale: playerScale,
                child: _Orb(color: AppColors.playerStart, size: orbSize),
              ),
            ),
          ),
          Transform.translate(
            offset: Offset(aiDx, 0),
            child: Opacity(
              opacity: aiOpacity,
              child: Transform.scale(
                scale: aiScale,
                child: _Orb(color: AppColors.aiStart, size: orbSize),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Orb extends StatelessWidget {
  const _Orb({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.withValues(alpha: 0.6)]),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.6),
            blurRadius: 28,
            spreadRadius: 4,
          ),
        ],
      ),
    );
  }
}
