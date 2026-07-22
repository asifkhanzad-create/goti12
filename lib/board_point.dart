/// Represents one of the 25 points on the 12 Goti board, addressed by
/// (col, row) with col/row each 0..4.
class BoardPoint {
  const BoardPoint(this.col, this.row);

  final int col;
  final int row;

  /// Stable index 0..24, row-major. Handy as a map key.
  int get index => row * 5 + col;

  bool get isCenter => col == 2 && row == 2;

  @override
  bool operator ==(Object other) => other is BoardPoint && other.col == col && other.row == row;

  @override
  int get hashCode => Object.hash(col, row);

  @override
  String toString() => 'BoardPoint($col, $row)';
}

/// Static graph describing which points connect to which — this mirrors the
/// exact pattern drawn in board_preview.dart: full grid lines, plus the two
/// diagonals through the center of each 2x2 block (NOT every small cell).
class BoardGraph {
  BoardGraph._();

  static final List<BoardPoint> points = [
    for (var row = 0; row < 5; row++)
      for (var col = 0; col < 5; col++) BoardPoint(col, row),
  ];

  /// point index -> list of adjacent point indices
  static final Map<int, List<int>> _adjacency = _buildAdjacency();

  static List<int> neighborsOf(BoardPoint p) => _adjacency[p.index] ?? const [];

  static bool areAdjacent(BoardPoint a, BoardPoint b) => neighborsOf(a).contains(b.index);

  static Map<int, List<int>> _buildAdjacency() {
    final adj = <int, Set<int>>{
      for (final p in points) p.index: <int>{},
    };

    void link(BoardPoint a, BoardPoint b) {
      adj[a.index]!.add(b.index);
      adj[b.index]!.add(a.index);
    }

    BoardPoint at(int col, int row) => BoardPoint(col, row);

    // Horizontal + vertical grid lines (every adjacent pair of the 5x5 grid)
    for (var row = 0; row < 5; row++) {
      for (var col = 0; col < 5; col++) {
        if (col < 4) link(at(col, row), at(col + 1, row));
        if (row < 4) link(at(col, row), at(col, row + 1));
      }
    }

    // 4 big X's — one per 2x2 block, diagonals through that block's center.
    // Each diagonal is split into two edges via the block's center point, so
    // the center is a real stop: occupiable, blockable, and capturable, same
    // as every other point on the board.
    for (var blockCol = 0; blockCol < 2; blockCol++) {
      for (var blockRow = 0; blockRow < 2; blockRow++) {
        final c0 = blockCol * 2;
        final r0 = blockRow * 2;
        final mid = at(c0 + 1, r0 + 1);
        link(at(c0, r0), mid);
        link(mid, at(c0 + 2, r0 + 2));
        link(at(c0 + 2, r0), mid);
        link(mid, at(c0, r0 + 2));
      }
    }

    return {for (final e in adj.entries) e.key: e.value.toList()..sort()};
  }
}