import 'board_point.dart';

enum Owner { player, ai }

extension OwnerX on Owner {
  Owner get opponent => this == Owner.player ? Owner.ai : Owner.player;
}

/// A single hop within a move: where it lands, and what (if anything) was
/// captured on that specific hop. Used so a multi-jump chain can be replayed
/// one hop at a time for animation, instead of only knowing the final result.
class MoveStep {
  const MoveStep({required this.to, this.captured = const []});

  final int to;
  final List<int> captured;
}

/// A single move: from one point to another, plus any pieces captured
/// along the way (empty if it was a plain, non-capturing move). [steps]
/// breaks a (possibly multi-hop) move into its individual jumps, in order,
/// so the UI can animate/replay them one at a time.
class Move {
  const Move({
    required this.from,
    required this.to,
    this.captured = const [],
    this.steps = const [],
  });

  final int from; // point index
  final int to; // point index
  final List<int> captured; // point indices of jumped-over pieces (all hops)
  final List<MoveStep> steps; // individual hops, in order

  /// Steps to use for animation — falls back to a single implicit hop for
  /// moves that were constructed without an explicit [steps] list.
  List<MoveStep> get effectiveSteps =>
      steps.isNotEmpty ? steps : [MoveStep(to: to, captured: captured)];
}

enum GamePhase { playing, playerWon, aiWon }

/// Holds board occupancy + whose turn it is, and exposes the rules:
/// legal moves, applying a move (with optional chain captures), and
/// win-condition checks. Pure logic — no Flutter/UI here.
class GameState {
  GameState({required Map<int, Owner?> occupants, required this.turn})
      : occupants = Map<int, Owner?>.from(occupants);

  final Map<int, Owner?> occupants; // point index -> owner or null
  Owner turn;
  GamePhase phase = GamePhase.playing;

  factory GameState.initial({required Owner firstTurn}) {
    final map = <int, Owner?>{};
    for (final p in BoardGraph.points) {
      if (p.isCenter) {
        map[p.index] = null;
      } else if (p.row <= 1) {
        map[p.index] = Owner.ai;
      } else if (p.row >= 3) {
        map[p.index] = Owner.player;
      } else {
        map[p.index] = p.col <= 1 ? Owner.player : Owner.ai;
      }
    }
    return GameState(occupants: map, turn: firstTurn);
  }

  Owner? ownerAt(int index) => occupants[index];

  /// Plain (non-capturing) moves available from [from]: adjacent + empty.
  List<int> plainMovesFrom(int from) {
    final owner = occupants[from];
    if (owner == null) return const [];
    return BoardGraph.neighborsOf(BoardPoint(from % 5, from ~/ 5))
        .where((n) => occupants[n] == null)
        .toList();
  }

  /// Single-jump captures available from [from]: an adjacent opponent piece
  /// with an empty landing point directly beyond it, in a straight line
  /// along an existing board connection.
  List<Move> capturesFrom(int from) => _capturesFromWithBoard(
        from,
        occupants[from],
        occupants,
      );

  /// All capture chains starting at [from], fully expanded (each chain step
  /// is optional, so this returns every possible chain length including the
  /// single-jump ones). Each returned Move carries its full hop-by-hop
  /// [Move.steps] so it can be replayed/animated one jump at a time.
  List<Move> captureChainsFrom(int from) {
    final results = <Move>[];

    void explore(
      int currentFrom,
      List<int> capturedSoFar,
      List<MoveStep> stepsSoFar,
      int originalFrom,
    ) {
      final owner = occupants[originalFrom];
      final tempOccupants = Map<int, Owner?>.from(occupants);
      tempOccupants[originalFrom] = null;
      for (final c in capturedSoFar) {
        tempOccupants[c] = null;
      }
      tempOccupants[currentFrom] = owner;

      final nextJumps = _capturesFromWithBoard(currentFrom, owner, tempOccupants);
      if (nextJumps.isEmpty && capturedSoFar.isNotEmpty) {
        results.add(Move(
          from: originalFrom,
          to: currentFrom,
          captured: capturedSoFar,
          steps: stepsSoFar,
        ));
        return;
      }
      if (capturedSoFar.isNotEmpty) {
        // chaining is optional — stopping here is also a valid move
        results.add(Move(
          from: originalFrom,
          to: currentFrom,
          captured: capturedSoFar,
          steps: stepsSoFar,
        ));
      }
      for (final jump in nextJumps) {
        explore(
          jump.to,
          [...capturedSoFar, ...jump.captured],
          [...stepsSoFar, MoveStep(to: jump.to, captured: jump.captured)],
          originalFrom,
        );
      }
    }

    for (final jump in capturesFrom(from)) {
      explore(jump.to, jump.captured, [MoveStep(to: jump.to, captured: jump.captured)], from);
    }
    return results;
  }

  List<Move> _capturesFromWithBoard(int from, Owner? owner, Map<int, Owner?> board) {
    if (owner == null) return const [];
    final fromPoint = BoardPoint(from % 5, from ~/ 5);
    final moves = <Move>[];
    for (final midIndex in BoardGraph.neighborsOf(fromPoint)) {
      if (board[midIndex] != owner.opponent) continue;
      final midPoint = BoardPoint(midIndex % 5, midIndex ~/ 5);
      final landCol = midPoint.col * 2 - fromPoint.col;
      final landRow = midPoint.row * 2 - fromPoint.row;
      if (landCol < 0 || landCol > 4 || landRow < 0 || landRow > 4) continue;
      final landPoint = BoardPoint(landCol, landRow);
      if (!BoardGraph.areAdjacent(midPoint, landPoint)) continue;
      if (board[landPoint.index] != null) continue;
      moves.add(Move(
        from: from,
        to: landPoint.index,
        captured: [midIndex],
        steps: [MoveStep(to: landPoint.index, captured: [midIndex])],
      ));
    }
    return moves;
  }

  /// Every legal move for the piece at [from]: plain moves + all capture
  /// chain options. Captures are optional, so both lists are valid choices.
  List<Move> legalMovesFrom(int from) {
    final plain = plainMovesFrom(from)
        .map((to) => Move(from: from, to: to, steps: [MoveStep(to: to)]))
        .toList();
    final captures = captureChainsFrom(from);
    return [...plain, ...captures];
  }

  /// All legal moves for [owner] across the whole board.
  List<Move> legalMovesFor(Owner owner) {
    final moves = <Move>[];
    for (final entry in occupants.entries) {
      if (entry.value == owner) {
        moves.addAll(legalMovesFrom(entry.key));
      }
    }
    return moves;
  }

  /// Applies [move] atomically in one shot: relocates the piece, removes
  /// captured pieces, passes the turn, and updates win-condition phase.
  /// Used by the AI's search (which needs fast, non-animated simulation) —
  /// the real UI uses [applyStep] + [endTurn] instead so it can animate
  /// each hop of a chain individually.
  void applyMove(Move move) {
    final owner = occupants[move.from];
    occupants[move.from] = null;
    for (final c in move.captured) {
      occupants[c] = null;
    }
    occupants[move.to] = owner;

    turn = turn.opponent;
    _updatePhase();
  }

  /// Mutates the board for a single hop of a move (one jump of a chain, or
  /// a whole plain move). Does NOT flip the turn — call [endTurn] once every
  /// hop of the move has been applied. Lets the UI animate a multi-hop
  /// chain one jump at a time while keeping game state in sync throughout.
  void applyStep(int from, MoveStep step) {
    final owner = occupants[from];
    occupants[from] = null;
    for (final c in step.captured) {
      occupants[c] = null;
    }
    occupants[step.to] = owner;
    _checkWipeout(); // a capture can end the game before the turn even ends
  }

  /// Ends the current turn (flips it and re-checks win conditions). Used
  /// once a move (all its hops already applied via [applyStep]) is fully
  /// done, or when a player deliberately stops a capture chain early.
  void endTurn() {
    turn = turn.opponent;
    _updatePhase();
  }

  void _checkWipeout() {
    final playerPieces = occupants.values.where((o) => o == Owner.player).length;
    final aiPieces = occupants.values.where((o) => o == Owner.ai).length;
    if (playerPieces == 0) {
      phase = GamePhase.aiWon;
    } else if (aiPieces == 0) {
      phase = GamePhase.playerWon;
    }
  }

  void _updatePhase() {
    _checkWipeout();
    if (phase != GamePhase.playing) return;

    final turnHasMoves = legalMovesFor(turn).isNotEmpty;
    if (!turnHasMoves) {
      phase = turn == Owner.player ? GamePhase.aiWon : GamePhase.playerWon;
    }
  }
}
