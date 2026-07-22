import 'dart:math';
import 'board_point.dart';
import 'game_state.dart';

enum Difficulty { easy, medium, hard, master }

/// Picks a move for [difficulty] using minimax + alpha-beta pruning.
///
/// Difficulty is tuned via three independent knobs, same idea used by most
/// small-board strategy-game AIs:
///  - search depth (how many plies ahead it looks)
///  - "mistake chance" (chance it ignores the search result and just plays
///    a random legal move instead — mimics a human missing something,
///    including missing whole capture chains, since a chain is itself just
///    one Move in the legal-move list)
///  - evaluation richness (piece count only vs. also weighing mobility and
///    center control)
class AiEngine {
  AiEngine(this.difficulty, {Random? random}) : _rng = random ?? Random();

  final Difficulty difficulty;
  final Random _rng;

  int get _searchDepth {
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
        return 0.12;
      case Difficulty.hard:
        return 0.0;
      case Difficulty.master:
        return 0.0;
    }
  }

  /// Returns the move the AI wants to play for whoever's turn [state] says
  /// it is, or null if there's genuinely nothing legal to play.
  Move? chooseMove(GameState state) {
    final moves = state.legalMovesFor(state.turn);
    if (moves.isEmpty) return null;

    if (_rng.nextDouble() < _mistakeChance) {
      return moves[_rng.nextInt(moves.length)];
    }

    final me = state.turn;
    Move? best;
    double bestScore = double.negativeInfinity;
    double alpha = double.negativeInfinity;
    const beta = double.infinity;

    for (final move in moves) {
      final next = _cloneAndApply(state, move);
      final score = _minimax(next, _searchDepth - 1, alpha, beta, me);
      if (best == null || score > bestScore) {
        bestScore = score;
        best = move;
      }
      if (score > alpha) alpha = score;
    }
    return best;
  }

  GameState _cloneAndApply(GameState state, Move move) {
    final clone = GameState(occupants: state.occupants, turn: state.turn);
    clone.applyMove(move);
    return clone;
  }

  double _minimax(GameState state, int depth, double alpha, double beta, Owner me) {
    if (depth == 0 || state.phase != GamePhase.playing) {
      return _evaluate(state, me);
    }

    final moves = state.legalMovesFor(state.turn);
    if (moves.isEmpty) return _evaluate(state, me);

    final maximizing = state.turn == me;
    double best = maximizing ? double.negativeInfinity : double.infinity;

    for (final move in moves) {
      final next = _cloneAndApply(state, move);
      final score = _minimax(next, depth - 1, alpha, beta, me);
      if (maximizing) {
        if (score > best) best = score;
        if (best > alpha) alpha = best;
      } else {
        if (score < best) best = score;
        if (best < beta) beta = best;
      }
      if (beta <= alpha) break; // prune
    }
    return best;
  }

  double _evaluate(GameState state, Owner me) {
    if (state.phase == GamePhase.playerWon) {
      return me == Owner.player ? 1000.0 : -1000.0;
    }
    if (state.phase == GamePhase.aiWon) {
      return me == Owner.ai ? 1000.0 : -1000.0;
    }

    final opponent = me.opponent;
    final myPieces = state.occupants.values.where((o) => o == me).length;
    final oppPieces = state.occupants.values.where((o) => o == opponent).length;
    double score = (myPieces - oppPieces) * 10.0;

    // Medium and up also care about mobility — being able to move more
    // pieces than the opponent is a real positional edge, not just material.
    if (difficulty == Difficulty.medium ||
        difficulty == Difficulty.hard ||
        difficulty == Difficulty.master) {
      final myMobility = state.legalMovesFor(me).length;
      final oppMobility = state.legalMovesFor(opponent).length;
      score += (myMobility - oppMobility) * 0.5;
    }

    // Master also weighs board position — points nearer the center connect
    // to more of the board (more diagonals pass through them), so holding
    // them is worth a small bonus.
    if (difficulty == Difficulty.master) {
      for (final entry in state.occupants.entries) {
        if (entry.value == null) continue;
        final weight = _centerWeight(entry.key);
        score += entry.value == me ? weight : -weight;
      }
    }

    return score;
  }

  double _centerWeight(int index) {
    final p = BoardPoint(index % 5, index ~/ 5);
    final dist = (p.col - 2).abs() + (p.row - 2).abs();
    // center (dist 0) worth most, falls off toward the edges
    return (4 - dist) * 0.3;
  }
}
