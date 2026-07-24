import 'dart:math';

import 'board_point.dart';
import 'game_state.dart';

enum Difficulty { easy, medium, hard, master }

/// Serializable snapshot of the board for isolate transfer.
class AiBoardSnapshot {
  const AiBoardSnapshot({
    required this.cells,
    required this.turnIsAi,
  });

  /// Length 25: 0 = empty, 1 = player, 2 = ai.
  final List<int> cells;
  final bool turnIsAi;

  factory AiBoardSnapshot.fromState(GameState state) {
    final cells = List<int>.filled(25, 0);
    for (final e in state.occupants.entries) {
      final o = e.value;
      if (o == Owner.player) {
        cells[e.key] = 1;
      } else if (o == Owner.ai) {
        cells[e.key] = 2;
      }
    }
    return AiBoardSnapshot(
      cells: cells,
      turnIsAi: state.turn == Owner.ai,
    );
  }

  Map<String, Object?> toJson() => {
        'cells': cells,
        'turnIsAi': turnIsAi,
      };

  factory AiBoardSnapshot.fromJson(Map<String, Object?> json) {
    return AiBoardSnapshot(
      cells: List<int>.from(json['cells']! as List),
      turnIsAi: json['turnIsAi']! as bool,
    );
  }
}

/// Isolate-safe payload for [aiChooseMoveIsolate].
class AiChooseRequest {
  const AiChooseRequest({
    required this.difficultyIndex,
    required this.snapshot,
    this.seed,
  });

  final int difficultyIndex;
  final AiBoardSnapshot snapshot;
  final int? seed;

  Map<String, Object?> toJson() => {
        'difficultyIndex': difficultyIndex,
        'snapshot': snapshot.toJson(),
        'seed': seed,
      };

  factory AiChooseRequest.fromJson(Map<String, Object?> json) {
    return AiChooseRequest(
      difficultyIndex: json['difficultyIndex']! as int,
      snapshot: AiBoardSnapshot.fromJson(
        Map<String, Object?>.from(json['snapshot']! as Map),
      ),
      seed: json['seed'] as int?,
    );
  }
}

/// Isolate-safe move encoding (reconstructed to [Move] on the UI isolate).
class AiMovePayload {
  const AiMovePayload({
    required this.from,
    required this.to,
    required this.captured,
    required this.steps,
  });

  final int from;
  final int to;
  final List<int> captured;
  final List<AiStepPayload> steps;

  Map<String, Object?> toJson() => {
        'from': from,
        'to': to,
        'captured': captured,
        'steps': steps.map((s) => s.toJson()).toList(),
      };

  factory AiMovePayload.fromJson(Map<String, Object?> json) {
    final stepList = (json['steps'] as List?) ?? const [];
    return AiMovePayload(
      from: json['from']! as int,
      to: json['to']! as int,
      captured: List<int>.from(json['captured']! as List),
      steps: stepList
          .map((s) => AiStepPayload.fromJson(Map<String, Object?>.from(s as Map)))
          .toList(),
    );
  }

  Move toMove() => Move(
        from: from,
        to: to,
        captured: captured,
        steps: steps
            .map((s) => MoveStep(to: s.to, captured: s.captured))
            .toList(),
      );

  static AiMovePayload fromMove(Move m) => AiMovePayload(
        from: m.from,
        to: m.to,
        captured: m.captured,
        steps: m.effectiveSteps
            .map((s) => AiStepPayload(to: s.to, captured: s.captured))
            .toList(),
      );
}

class AiStepPayload {
  const AiStepPayload({required this.to, required this.captured});

  final int to;
  final List<int> captured;

  Map<String, Object?> toJson() => {'to': to, 'captured': captured};

  factory AiStepPayload.fromJson(Map<String, Object?> json) => AiStepPayload(
        to: json['to']! as int,
        captured: List<int>.from(json['captured']! as List),
      );
}

/// Top-level isolate entry — only JSON-like maps cross the isolate boundary.
Map<String, Object?>? aiChooseMoveIsolate(Map<String, Object?> requestJson) {
  final request = AiChooseRequest.fromJson(requestJson);
  final difficulty = Difficulty.values[request.difficultyIndex];
  final engine = AiEngine(
    difficulty,
    random: request.seed != null ? Random(request.seed) : Random(),
  );
  final move = engine.chooseMoveFromSnapshot(request.snapshot);
  return move == null ? null : AiMovePayload.fromMove(move).toJson();
}

/// Picks a move for [difficulty] using minimax + alpha-beta pruning.
///
/// Difficulty knobs:
///  - search depth / time budget (iterative deepening)
///  - mistake chance (random legal move)
///  - evaluation richness (material, mobility, center)
class AiEngine {
  AiEngine(this.difficulty, {Random? random}) : _rng = random ?? Random();

  final Difficulty difficulty;
  final Random _rng;

  /// Soft think-time caps so Hard/Master never hang the device.
  Duration get _timeBudget {
    switch (difficulty) {
      case Difficulty.easy:
        return const Duration(milliseconds: 40);
      case Difficulty.medium:
        return const Duration(milliseconds: 80);
      case Difficulty.hard:
        return const Duration(milliseconds: 200);
      case Difficulty.master:
        return const Duration(milliseconds: 350);
    }
  }

  int get _maxDepth {
    switch (difficulty) {
      case Difficulty.easy:
        return 2;
      case Difficulty.medium:
        return 3;
      case Difficulty.hard:
        return 5;
      case Difficulty.master:
        return 7;
    }
  }

  double get _mistakeChance {
    switch (difficulty) {
      case Difficulty.easy:
        return 0.35;
      case Difficulty.medium:
        return 0.20; // 20% easier (higher mistake chance from 0.12 to 0.144)
      case Difficulty.hard:
        return 0.0;
      case Difficulty.master:
        return 0.0;
    }
  }

  bool get _useMobility =>
      difficulty == Difficulty.medium ||
      difficulty == Difficulty.hard ||
      difficulty == Difficulty.master;

  bool get _useCenter => difficulty == Difficulty.master;

  /// UI-path entry: sync search (prefer [chooseMoveAsync] from the board).
  Move? chooseMove(GameState state) {
    return chooseMoveFromSnapshot(AiBoardSnapshot.fromState(state));
  }

  Move? chooseMoveFromSnapshot(AiBoardSnapshot snapshot) {
    final board = _SearchBoard.fromSnapshot(snapshot);
    final moves = board.legalMovesFor(board.turn);
    if (moves.isEmpty) return null;

    if (_rng.nextDouble() < _mistakeChance) {
      return moves[_rng.nextInt(moves.length)].toMove();
    }

    return _searchBest(board, moves);
  }

  Move? _searchBest(_SearchBoard board, List<_SearchMove> rootMoves) {
    final me = board.turn;
    final deadline = DateTime.now().add(_timeBudget);
    final tt = <int, _TtEntry>{};
    _nodes = 0;

    // Captures first at root for better ID seed.
    rootMoves.sort((a, b) => b.captureCount.compareTo(a.captureCount));

    Move? bestMove = rootMoves.first.toMove();

    final maxD = _maxDepth;
    // Iterative deepening: always keep last completed depth's best.
    for (var depth = 1; depth <= maxD; depth++) {
      if (DateTime.now().isAfter(deadline) && depth > 1) break;

      var alpha = double.negativeInfinity;
      const beta = double.infinity;
      Move? depthBest;
      var depthBestScore = double.negativeInfinity;
      var aborted = false;

      // Put previous best first for better pruning.
      if (depth > 1) {
        final prevFrom = bestMove!.from;
        final prevTo = bestMove.to;
        rootMoves.sort((a, b) {
          final aMatch = a.from == prevFrom && a.to == prevTo;
          final bMatch = b.from == prevFrom && b.to == prevTo;
          if (aMatch && !bMatch) return -1;
          if (bMatch && !aMatch) return 1;
          return b.captureCount.compareTo(a.captureCount);
        });
      }

      for (final move in rootMoves) {
        if (DateTime.now().isAfter(deadline) && depth > 1) {
          aborted = true;
          break;
        }
        board.make(move);
        final score = _minimax(
          board,
          depth - 1,
          alpha,
          beta,
          me,
          deadline,
          tt,
          depth > 1,
        );
        board.unmake(move);

        if (score == null) {
          aborted = true;
          break;
        }
        if (depthBest == null || score > depthBestScore) {
          depthBestScore = score;
          depthBest = move.toMove();
        }
        if (score > alpha) alpha = score;
      }

      if (!aborted && depthBest != null) {
        bestMove = depthBest;
      } else if (depth == 1 && depthBest != null) {
        // Always accept depth-1 if we got anything.
        bestMove = depthBest;
      }
      // If aborted mid-depth > 1, keep previous completed depth.
    }

    return bestMove;
  }

  int _nodes = 0;

  /// Returns null if the time budget was exceeded mid-search (caller aborts ID).
  double? _minimax(
    _SearchBoard board,
    int depth,
    double alpha,
    double beta,
    int me,
    DateTime deadline,
    Map<int, _TtEntry> tt,
    bool checkTime,
  ) {
    // Sample the clock only every so often — DateTime.now() every node is costly.
    if (checkTime && (++_nodes & 255) == 0 && DateTime.now().isAfter(deadline)) {
      return null;
    }

    final phase = board.phase;
    if (phase != 0) {
      // 1 = player won, 2 = ai won
      if (phase == 1) return me == _SearchBoard.player ? 1000.0 : -1000.0;
      return me == _SearchBoard.ai ? 1000.0 : -1000.0;
    }

    final hash = board.hash;
    final ttHit = tt[hash];
    if (ttHit != null && ttHit.depth >= depth) {
      return ttHit.score;
    }

    if (depth == 0) {
      final score = _evaluate(board, me);
      tt[hash] = _TtEntry(depth: 0, score: score);
      return score;
    }

    final moves = board.legalMovesFor(board.turn);
    if (moves.isEmpty) {
      // Side to move has no moves → loses.
      final score = board.turn == me ? -1000.0 : 1000.0;
      tt[hash] = _TtEntry(depth: depth, score: score);
      return score;
    }

    // Captures first → stronger alpha-beta pruning.
    moves.sort((a, b) => b.captureCount.compareTo(a.captureCount));

    final maximizing = board.turn == me;
    var best = maximizing ? double.negativeInfinity : double.infinity;

    for (final move in moves) {
      board.make(move);
      final score = _minimax(
        board,
        depth - 1,
        alpha,
        beta,
        me,
        deadline,
        tt,
        checkTime,
      );
      board.unmake(move);

      if (score == null) return null;

      if (maximizing) {
        if (score > best) best = score;
        if (best > alpha) alpha = best;
      } else {
        if (score < best) best = score;
        if (best < beta) beta = best;
      }
      if (beta <= alpha) break;
    }

    tt[hash] = _TtEntry(depth: depth, score: best);
    return best;
  }

  double _evaluate(_SearchBoard board, int me) {
    final opp = me == _SearchBoard.player ? _SearchBoard.ai : _SearchBoard.player;
    final myPieces =
        me == _SearchBoard.player ? board.playerCount : board.aiCount;
    final oppPieces =
        opp == _SearchBoard.player ? board.playerCount : board.aiCount;
    var score = (myPieces - oppPieces) * 10.0;

    if (_useMobility) {
      // Cheap mobility: plain adjacent empties + single-hop captures only
      // (no full chain expansion). Good enough for ranking and far cheaper.
      final myMob = board.quickMobility(me);
      final oppMob = board.quickMobility(opp);
      score += (myMob - oppMob) * 0.5;
    }

    if (_useCenter) {
      for (var i = 0; i < 25; i++) {
        final cell = board.cells[i];
        if (cell == 0) continue;
        final w = _centerWeights[i];
        score += cell == me ? w : -w;
      }
    }

    return score;
  }

  /// Precomputed Manhattan-from-center weights (same formula as before).
  static final List<double> _centerWeights = List<double>.generate(25, (i) {
    final col = i % 5;
    final row = i ~/ 5;
    final dist = (col - 2).abs() + (row - 2).abs();
    return (4 - dist) * 0.3;
  });
}

class _TtEntry {
  const _TtEntry({required this.depth, required this.score});
  final int depth;
  final double score;
}

/// Compact search board: fixed 25-cell array + make/unmake (no Map clones).
class _SearchBoard {
  static const int empty = 0;
  static const int player = 1;
  static const int ai = 2;

  _SearchBoard({
    required this.cells,
    required this.turn,
    required this.playerCount,
    required this.aiCount,
  });

  final List<int> cells; // length 25
  int turn;
  int playerCount;
  int aiCount;

  /// 0 = playing, 1 = player won, 2 = ai won
  int phase = 0;

  /// Simple rolling hash for TT (piece * prime ^ square).
  int hash = 0;

  static const _piecePrime = 3;
  static final List<int> _sqMul = List<int>.generate(25, (i) {
    // 31^i mod large range via iterative multiply
    var v = 1;
    for (var k = 0; k < i; k++) {
      v = (v * 31) & 0x7fffffff;
    }
    return v;
  });

  factory _SearchBoard.fromSnapshot(AiBoardSnapshot snap) {
    final cells = List<int>.from(snap.cells);
    var p = 0;
    var a = 0;
    var h = 0;
    for (var i = 0; i < 25; i++) {
      final c = cells[i];
      if (c == player) {
        p++;
        h ^= c * _sqMul[i] * _piecePrime;
      } else if (c == ai) {
        a++;
        h ^= c * _sqMul[i] * _piecePrime;
      }
    }
    final board = _SearchBoard(
      cells: cells,
      turn: snap.turnIsAi ? ai : player,
      playerCount: p,
      aiCount: a,
    );
    board.hash = h ^ board.turn;
    return board;
  }

  int get opponent => turn == player ? ai : player;

  void _xorCell(int index, int piece) {
    if (piece == 0) return;
    hash ^= piece * _sqMul[index] * _piecePrime;
  }

  void make(_SearchMove move) {
    final owner = cells[move.from];
    _xorCell(move.from, owner);
    cells[move.from] = empty;

    for (final c in move.captured) {
      final cap = cells[c];
      _xorCell(c, cap);
      cells[c] = empty;
      if (cap == player) {
        playerCount--;
      } else if (cap == ai) {
        aiCount--;
      }
    }

    cells[move.to] = owner;
    _xorCell(move.to, owner);

    hash ^= turn; // remove old turn
    turn = turn == player ? ai : player;
    hash ^= turn; // add new turn

    _updatePhaseAfterMove();
  }

  void unmake(_SearchMove move) {
    // Reverse of make: restore turn, piece, captures.
    hash ^= turn;
    turn = turn == player ? ai : player;
    hash ^= turn;

    final owner = cells[move.to];
    _xorCell(move.to, owner);
    cells[move.to] = empty;

    // Captures were opponent pieces.
    final capOwner = owner == player ? ai : player;
    for (final c in move.captured) {
      cells[c] = capOwner;
      _xorCell(c, capOwner);
      if (capOwner == player) {
        playerCount++;
      } else {
        aiCount++;
      }
    }

    cells[move.from] = owner;
    _xorCell(move.from, owner);

    phase = 0; // always was playing when we made a search move from a live node
  }

  void _updatePhaseAfterMove() {
    if (playerCount == 0) {
      phase = 2; // ai won
      return;
    }
    if (aiCount == 0) {
      phase = 1; // player won
      return;
    }
    // Immobility checked by caller via empty legalMovesFor.
    phase = 0;
  }

  List<_SearchMove> legalMovesFor(int owner) {
    final moves = <_SearchMove>[];
    for (var i = 0; i < 25; i++) {
      if (cells[i] != owner) continue;
      _collectMovesFrom(i, owner, moves);
    }
    return moves;
  }

  void _collectMovesFrom(int from, int owner, List<_SearchMove> out) {
    final neighbors = BoardGraph.neighborsOf(BoardPoint(from % 5, from ~/ 5));
    for (final n in neighbors) {
      if (cells[n] == empty) {
        out.add(_SearchMove(from: from, to: n, captured: const [], steps: const []));
      }
    }
    // Seed chain exploration from each single capture off [from].
    for (final jump in _singleCapturesOn(
      from,
      owner,
      pieceAt: from,
      originalFrom: from,
      captured: const {},
    )) {
      _exploreCaptures(
        jump.to,
        owner,
        [jump.capturedSingle],
        [_SearchStep(to: jump.to, captured: [jump.capturedSingle])],
        from,
        out,
      );
    }
  }

  /// Recursively expand optional capture chains without mutating [cells].
  void _exploreCaptures(
    int currentFrom,
    int owner,
    List<int> capturedSoFar,
    List<_SearchStep> stepsSoFar,
    int originalFrom,
    List<_SearchMove> out,
  ) {
    // Stopping after at least one capture is always legal.
    out.add(_SearchMove(
      from: originalFrom,
      to: currentFrom,
      captured: List<int>.from(capturedSoFar),
      steps: List<_SearchStep>.from(stepsSoFar),
    ));

    final capSet = capturedSoFar.toSet();
    final nextJumps = _singleCapturesOn(
      currentFrom,
      owner,
      pieceAt: currentFrom,
      originalFrom: originalFrom,
      captured: capSet,
    );

    for (final jump in nextJumps) {
      _exploreCaptures(
        jump.to,
        owner,
        [...capturedSoFar, jump.capturedSingle],
        [
          ...stepsSoFar,
          _SearchStep(to: jump.to, captured: [jump.capturedSingle]),
        ],
        originalFrom,
        out,
      );
    }
  }

  /// Occupancy under a partial chain: piece sits at [pieceAt], [originalFrom]
  /// is vacated, and every index in [captured] is empty.
  int _cellUnderChain(
    int index, {
    required int pieceAt,
    required int originalFrom,
    required Set<int> captured,
    required int owner,
  }) {
    if (index == pieceAt) return owner;
    if (index == originalFrom) return empty;
    if (captured.contains(index)) return empty;
    return cells[index];
  }

  List<({int to, int capturedSingle})> _singleCapturesOn(
    int from,
    int owner, {
    required int pieceAt,
    required int originalFrom,
    required Set<int> captured,
  }) {
    final opp = owner == player ? ai : player;
    final fromPoint = BoardPoint(from % 5, from ~/ 5);
    final result = <({int to, int capturedSingle})>[];
    for (final midIndex in BoardGraph.neighborsOf(fromPoint)) {
      final midOcc = _cellUnderChain(
        midIndex,
        pieceAt: pieceAt,
        originalFrom: originalFrom,
        captured: captured,
        owner: owner,
      );
      if (midOcc != opp) continue;
      final midPoint = BoardPoint(midIndex % 5, midIndex ~/ 5);
      final landCol = midPoint.col * 2 - fromPoint.col;
      final landRow = midPoint.row * 2 - fromPoint.row;
      if (landCol < 0 || landCol > 4 || landRow < 0 || landRow > 4) continue;
      final landPoint = BoardPoint(landCol, landRow);
      if (!BoardGraph.areAdjacent(midPoint, landPoint)) continue;
      final landOcc = _cellUnderChain(
        landPoint.index,
        pieceAt: pieceAt,
        originalFrom: originalFrom,
        captured: captured,
        owner: owner,
      );
      if (landOcc != empty) continue;
      result.add((to: landPoint.index, capturedSingle: midIndex));
    }
    return result;
  }

  /// Approximate mobility without expanding multi-hop chains.
  int quickMobility(int owner) {
    var count = 0;
    for (var i = 0; i < 25; i++) {
      if (cells[i] != owner) continue;
      final p = BoardPoint(i % 5, i ~/ 5);
      for (final n in BoardGraph.neighborsOf(p)) {
        if (cells[n] == empty) count++;
      }
      count += _singleCapturesOn(
        i,
        owner,
        pieceAt: i,
        originalFrom: i,
        captured: const {},
      ).length;
    }
    return count;
  }
}

class _SearchStep {
  const _SearchStep({required this.to, required this.captured});
  final int to;
  final List<int> captured;
}

class _SearchMove {
  const _SearchMove({
    required this.from,
    required this.to,
    required this.captured,
    required this.steps,
  });

  final int from;
  final int to;
  final List<int> captured;
  final List<_SearchStep> steps;

  int get captureCount => captured.length;

  Move toMove() {
    final moveSteps = steps.isNotEmpty
        ? steps
            .map((s) => MoveStep(to: s.to, captured: s.captured))
            .toList()
        : [MoveStep(to: to, captured: captured)];
    return Move(
      from: from,
      to: to,
      captured: captured,
      steps: moveSteps,
    );
  }
}
