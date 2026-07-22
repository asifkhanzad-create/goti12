import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'board_point.dart';
import 'game_state.dart';
import 'ai_engine.dart';

/// The real, interactive 12 Goti board, driven by [GameState].
///
/// Every move — player or AI, plain or multi-hop capture chain — plays out
/// as a sequence of individual animated hops (slide + fade-out of captured
/// pieces), so it's easy to actually watch and verify what happened, even
/// when the AI resolves a whole chain in one decision.
class GameBoardScreen extends StatefulWidget {
  const GameBoardScreen({super.key, required this.difficulty});

  final Difficulty difficulty;

  @override
  State<GameBoardScreen> createState() => _GameBoardScreenState();
}

class _GameBoardScreenState extends State<GameBoardScreen> with TickerProviderStateMixin {
  late GameState _state;
  late AiEngine _aiEngine;
  int? _selectedIndex;
  // when a capture chain is in progress, only continuing jumps are allowed
  // — no plain moves and no manual stop mid-chain.
  bool _chainInProgress = false;

  late final AnimationController _hopController;
  static const _hopDuration = Duration(milliseconds: 260);

  // Mid-hop animation state: the piece currently sliding, and any pieces
  // fading out as captured on this specific hop. Rendering reads these
  // directly, kept in sync with _hopController's progress.
  int? _animFrom;
  int? _animTo;
  Owner? _animOwner;
  List<int> _animCaptured = const [];

  @override
  void initState() {
    super.initState();
    _state = GameState.initial(firstTurn: Owner.player);
    _aiEngine = AiEngine(widget.difficulty);
    _hopController = AnimationController(vsync: this, duration: _hopDuration);
    _maybeTriggerAi();
  }

  @override
  void dispose() {
    _hopController.dispose();
    super.dispose();
  }

  void _onPointTap(int index) {
    if (_state.phase != GamePhase.playing) return;
    if (_state.turn != Owner.player) return;
    if (_hopController.isAnimating) return; // no input mid-slide

    if (_chainInProgress) {
      // only the next single jump from here is offered — never a shortcut
      // straight to some further point in the chain, and no way to
      // manually cut the chain short either.
      final nextJumps = _state.capturesFrom(_selectedIndex!);
      final match = nextJumps.where((m) => m.to == index);
      if (match.isEmpty) return; // must continue one hop at a time
      _playerCaptureHop(match.first);
      return;
    }

    final owner = _state.ownerAt(index);
    if (owner == Owner.player) {
      setState(() => _selectedIndex = _selectedIndex == index ? null : index);
      return;
    }

    if (_selectedIndex == null) return;

    // plain move: resolves immediately, turn passes right away
    if (_state.plainMovesFrom(_selectedIndex!).contains(index)) {
      _playerPlainMove(_selectedIndex!, index);
      return;
    }

    // first hop of a capture: only a single jump is ever offered here too —
    // no picking a multi-hop chain in one tap.
    final firstJumps = _state.capturesFrom(_selectedIndex!);
    final match = firstJumps.where((m) => m.to == index);
    if (match.isEmpty) return;
    _playerCaptureHop(match.first);
  }

  Future<void> _playerPlainMove(int from, int to) async {
    setState(() {
      _selectedIndex = null;
      _chainInProgress = false;
    });
    await _animateHop(from, MoveStep(to: to));
    setState(() => _state.endTurn());
    _maybeTriggerAi();
  }

  Future<void> _playerCaptureHop(Move singleHop) async {
    final from = singleHop.from;
    await _animateHop(from, MoveStep(to: singleHop.to, captured: singleHop.captured));

    if (_state.phase != GamePhase.playing) {
      setState(() {
        _selectedIndex = null;
        _chainInProgress = false;
      });
      return;
    }

    final landedAt = singleHop.to;
    final more = _state.capturesFrom(landedAt);
    if (more.isNotEmpty) {
      setState(() {
        _selectedIndex = landedAt;
        _chainInProgress = true;
      });
      return; // wait for the next tap — turn not passed yet
    }

    setState(() {
      _state.endTurn();
      _selectedIndex = null;
      _chainInProgress = false;
    });
    _maybeTriggerAi();
  }

  // Kicks off the AI's move (if it's genuinely its turn) after a short delay
  // so it doesn't feel instant/robotic. The AI's chosen Move already carries
  // its full hop-by-hop breakdown (see GameState.captureChainsFrom), so a
  // multi-capture chain plays out one visible hop at a time, same as the
  // player's — nothing about how it's applied is different or hidden.
  void _maybeTriggerAi() {
    if (_state.phase != GamePhase.playing || _state.turn != Owner.ai) return;
    Future.delayed(const Duration(milliseconds: 500), () async {
      if (!mounted) return;
      if (_state.phase != GamePhase.playing || _state.turn != Owner.ai) return;
      final move = _aiEngine.chooseMove(_state);
      if (move == null) return;
      await _animateAndApply(move);
      if (!mounted) return;
      _maybeTriggerAi(); // safety net, shouldn't normally re-fire
    });
  }

  /// Plays every hop of [move] in sequence, then ends the turn.
  Future<void> _animateAndApply(Move move) async {
    int current = move.from;
    for (final step in move.effectiveSteps) {
      await _animateHop(current, step);
      if (_state.phase != GamePhase.playing) return;
      current = step.to;
    }
    setState(() => _state.endTurn());
  }

  /// Slides the piece at [from] to [step.to], fading out anything captured
  /// on this hop, then commits the actual board mutation.
  Future<void> _animateHop(int from, MoveStep step) async {
    setState(() {
      _animFrom = from;
      _animTo = step.to;
      _animOwner = _state.ownerAt(from);
      _animCaptured = step.captured;
    });
    await _hopController.forward(from: 0);
    setState(() {
      _state.applyStep(from, step);
      _animFrom = null;
      _animTo = null;
      _animOwner = null;
      _animCaptured = const [];
    });
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
          'PLAY',
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
        child: Column(
          children: [
            const SizedBox(height: 8),
            _StatusBanner(state: _state),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final boardSize = constraints.maxWidth;
                        return AnimatedBuilder(
                          animation: _hopController,
                          builder: (context, _) {
                            final t = _hopController.value;
                            return Stack(
                              clipBehavior: Clip.none,
                              children: [
                                CustomPaint(
                                  size: Size(boardSize, boardSize),
                                  painter: _BoardLinesPainter(),
                                ),
                                for (final p in BoardGraph.points)
                                  _PositionedPoint(
                                    point: p,
                                    size: boardSize,
                                    owner: p.index == _animFrom ? null : _state.ownerAt(p.index),
                                    isSelected: _selectedIndex == p.index,
                                    fadeProgress: _animCaptured.contains(p.index) ? t : 0.0,
                                    onTap: () => _onPointTap(p.index),
                                  ),
                                if (_animFrom != null && _animOwner != null)
                                  _SlidingPiece(
                                    from: BoardPoint(_animFrom! % 5, _animFrom! ~/ 5),
                                    to: BoardPoint(_animTo! % 5, _animTo! ~/ 5),
                                    boardSize: boardSize,
                                    owner: _animOwner!,
                                    progress: t,
                                  ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pixel center of a board point within a square board of [size], shared by
/// the static grid points and the sliding-piece overlay so they line up.
Offset boardPointCenter(BoardPoint point, double size) {
  const margin = 0.06;
  final left = size * margin;
  final span = size * (1 - 2 * margin);
  return Offset(
    left + span * (point.col / 4),
    left + span * (point.row / 4),
  );
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.state});

  final GameState state;

  @override
  Widget build(BuildContext context) {
    String label;
    Color color;

    switch (state.phase) {
      case GamePhase.playerWon:
        label = 'YOU WON';
        color = AppColors.playerStart;
        break;
      case GamePhase.aiWon:
        label = 'AI WON';
        color = AppColors.aiStart;
        break;
      case GamePhase.playing:
        final isPlayer = state.turn == Owner.player;
        label = isPlayer ? 'YOUR TURN' : "AI IS THINKING…";
        color = isPlayer ? AppColors.playerStart : AppColors.aiStart;
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 13, letterSpacing: 1.5, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _PositionedPoint extends StatelessWidget {
  const _PositionedPoint({
    required this.point,
    required this.size,
    required this.owner,
    required this.isSelected,
    required this.onTap,
    this.fadeProgress = 0.0,
  });

  final BoardPoint point;
  final double size;
  final Owner? owner;
  final bool isSelected;
  final VoidCallback onTap;
  final double fadeProgress; // 0 = normal, 1 = fully faded (being captured)

  @override
  Widget build(BuildContext context) {
    const hitSize = 44.0;
    final c = boardPointCenter(point, size);
    return Positioned(
      left: c.dx - hitSize / 2,
      top: c.dy - hitSize / 2,
      width: hitSize,
      height: hitSize,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: owner == null
            ? const SizedBox.shrink()
            : Opacity(
                opacity: 1.0 - fadeProgress,
                child: Transform.scale(
                  scale: 1.0 - (fadeProgress * 0.4),
                  child: _Piece(owner: owner!, isSelected: isSelected),
                ),
              ),
      ),
    );
  }
}

/// The piece actively mid-hop, drawn on top of the static grid, sliding
/// from [from] to [to] as [progress] goes 0 -> 1.
class _SlidingPiece extends StatelessWidget {
  const _SlidingPiece({
    required this.from,
    required this.to,
    required this.boardSize,
    required this.owner,
    required this.progress,
  });

  final BoardPoint from;
  final BoardPoint to;
  final double boardSize;
  final Owner owner;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final start = boardPointCenter(from, boardSize);
    final end = boardPointCenter(to, boardSize);
    final curved = Curves.easeInOut.transform(progress);
    final center = Offset.lerp(start, end, curved)!;
    const pieceSize = 24.0;
    final baseColor = owner == Owner.player ? AppColors.playerStart : AppColors.aiStart;

    return Positioned(
      left: center.dx - pieceSize / 2,
      top: center.dy - pieceSize / 2,
      width: pieceSize,
      height: pieceSize,
      child: IgnorePointer(
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: baseColor,
            boxShadow: [
              BoxShadow(color: baseColor.withValues(alpha: 0.5), blurRadius: 14, spreadRadius: 2),
            ],
          ),
        ),
      ),
    );
  }
}

class _Piece extends StatefulWidget {
  const _Piece({required this.owner, required this.isSelected});

  final Owner owner;
  final bool isSelected;

  @override
  State<_Piece> createState() => _PieceState();
}

class _PieceState extends State<_Piece> with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.owner == Owner.player ? AppColors.playerStart : AppColors.aiStart;

    if (!widget.isSelected) {
      return Center(
        child: Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: baseColor,
            boxShadow: [
              BoxShadow(color: baseColor.withValues(alpha: 0.35), blurRadius: 10, spreadRadius: 1),
            ],
          ),
        ),
      );
    }

    // Selected piece: slow pulsing size + glow, no static outline.
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, _) {
        final t = _pulseController.value; // 0..1
        final scale = 1.0 + (t * 0.22); // gently grows/shrinks
        final glowAlpha = 0.4 + (t * 0.4);
        return Center(
          child: Transform.scale(
            scale: scale,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: baseColor,
                boxShadow: [
                  BoxShadow(
                    color: baseColor.withValues(alpha: glowAlpha),
                    blurRadius: 18,
                    spreadRadius: 3,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BoardLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = AppColors.boardLine
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const margin = 0.06;
    final left = size.width * margin;
    final right = size.width * (1 - margin);
    final top = size.height * margin;
    final bottom = size.height * (1 - margin);
    final w = right - left;
    final h = bottom - top;

    Offset gridPoint(int col, int row) => Offset(left + w * (col / 4), top + h * (row / 4));

    for (var col = 0; col <= 4; col++) {
      canvas.drawLine(gridPoint(col, 0), gridPoint(col, 4), linePaint);
    }
    for (var row = 0; row <= 4; row++) {
      canvas.drawLine(gridPoint(0, row), gridPoint(4, row), linePaint);
    }

    for (var blockCol = 0; blockCol < 2; blockCol++) {
      for (var blockRow = 0; blockRow < 2; blockRow++) {
        final c0 = blockCol * 2;
        final r0 = blockRow * 2;
        canvas.drawLine(gridPoint(c0, r0), gridPoint(c0 + 2, r0 + 2), linePaint);
        canvas.drawLine(gridPoint(c0 + 2, r0), gridPoint(c0, r0 + 2), linePaint);
      }
    }

    canvas.drawCircle(gridPoint(2, 2), 3, Paint()..color = AppColors.boardCenterDot);
  }

  @override
  bool shouldRepaint(covariant _BoardLinesPainter oldDelegate) => false;
}
