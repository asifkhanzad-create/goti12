import 'package:flutter_test/flutter_test.dart';
import 'package:goti12/ai_engine.dart';
import 'package:goti12/game_state.dart';

void main() {
  test('AI returns a legal move from the opening on every difficulty', () {
    final state = GameState.initial(firstTurn: Owner.ai);
    final legal = state.legalMovesFor(Owner.ai).map((m) => '${m.from}->${m.to}:${m.captured.join(",")}').toSet();

    for (final d in Difficulty.values) {
      final move = AiEngine(d, random: null /* uses Random() */).chooseMove(state);
      expect(move, isNotNull, reason: '$d should find a move');
      final key = '${move!.from}->${move.to}:${move.captured.join(",")}';
      expect(legal.contains(key), isTrue, reason: '$d move $key not in legal set');
    }
  });

  test('Hard/Master chooseMove stays within soft time budget (opening)', () {
    final state = GameState.initial(firstTurn: Owner.ai);

    for (final d in [Difficulty.hard, Difficulty.master]) {
      final engine = AiEngine(d);
      final sw = Stopwatch()..start();
      final move = engine.chooseMove(state);
      sw.stop();
      expect(move, isNotNull);
      // Budget + small overhead for ID bookkeeping; must not multi-second hang.
      expect(
        sw.elapsedMilliseconds,
        lessThan(800),
        reason: '$d took ${sw.elapsedMilliseconds}ms',
      );
    }
  });

  test('isolate entry returns serializable legal move', () {
    final state = GameState.initial(firstTurn: Owner.ai);
    final request = AiChooseRequest(
      difficultyIndex: Difficulty.hard.index,
      snapshot: AiBoardSnapshot.fromState(state),
      seed: 42,
    );
    final raw = aiChooseMoveIsolate(request.toJson());
    expect(raw, isNotNull);
    final move = AiMovePayload.fromJson(raw!).toMove();
    final legal = state.legalMovesFor(Owner.ai);
    expect(
      legal.any((m) => m.from == move.from && m.to == move.to),
      isTrue,
    );
  });
}
