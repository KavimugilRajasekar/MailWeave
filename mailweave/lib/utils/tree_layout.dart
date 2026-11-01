import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/email_tree_node.dart';

/// A card placed on the conversation canvas, with its top-left [position].
class PlacedCard {
  const PlacedCard({
    required this.key,
    required this.node,
    required this.position,
    required this.isRoot,
  });

  final String key;
  final EmailTreeNode node;

  /// Top-left of the card on the canvas.
  final Offset position;

  final bool isRoot;
}

/// A connector between a parent card's bottom-centre and a child card's
/// top-centre.
class TreeEdge {
  const TreeEdge({required this.from, required this.to});

  final Offset from;
  final Offset to;
}

/// The computed layout of a conversation tree on a 2D canvas.
class TreeLayoutResult {
  const TreeLayoutResult({
    required this.cards,
    required this.edges,
    required this.size,
  });

  final List<PlacedCard> cards;
  final List<TreeEdge> edges;
  final Size size;
}

/// Pure tree-layout calculator — no UI, no network.
///
/// Lays out the reply forest so each card keeps a fixed size, siblings spread
/// horizontally, each parent is centred over its children, and every depth sits
/// on its own row. Positions are derived dynamically from the tree structure
/// (no manually assigned coordinates, no fixed number of levels). Nodes whose
/// [EmailTreeNode.key] is in [collapsed] are rendered as leaves so the user can
/// fold branches away.
class TreeLayout {
  const TreeLayout._();

  static TreeLayoutResult compute({
    required List<EmailTreeNode> roots,
    required Set<String> collapsed,
    required double cardWidth,
    required double cardHeight,
    required double horizontalGap,
    required double verticalGap,
  }) {
    if (roots.isEmpty) {
      return const TreeLayoutResult(cards: [], edges: [], size: Size.zero);
    }

    // Pass 1 — memoise the width each subtree occupies.
    final widths = <String, double>{};
    double widthOf(EmailTreeNode n) {
      final folded = collapsed.contains(n.key);
      final kids = folded ? const <EmailTreeNode>[] : n.children;
      final w = kids.isEmpty
          ? cardWidth
          : math.max(cardWidth, _sumWidths(kids, horizontalGap, widthOf));
      widths[n.key] = w;
      return w;
    }

    for (final r in roots) {
      widthOf(r);
    }

    // Pass 2 — assign positions and emit connectors.
    final cards = <PlacedCard>[];
    final edges = <TreeEdge>[];

    Offset place(EmailTreeNode n, double x, int depth) {
      final sw = widths[n.key]!;
      final y = depth * (cardHeight + verticalGap);
      final pos = Offset(x + (sw - cardWidth) / 2, y);
      cards.add(PlacedCard(key: n.key, node: n, position: pos, isRoot: depth == 0));

      final folded = collapsed.contains(n.key);
      final kids = folded ? const <EmailTreeNode>[] : n.children;
      if (kids.isNotEmpty) {
        final childrenTotal =
            _sumWidths(kids, horizontalGap, (c) => widths[c.key]!);
        var cursor = x + (sw - childrenTotal) / 2;
        for (var i = 0; i < kids.length; i++) {
          if (i > 0) cursor += horizontalGap;
          final childPos = place(kids[i], cursor, depth + 1);
          cursor += widths[kids[i].key]!;
          edges.add(TreeEdge(
            from: Offset(pos.dx + cardWidth / 2, pos.dy + cardHeight),
            to: Offset(childPos.dx + cardWidth / 2, childPos.dy),
          ));
        }
      }
      return pos;
    }

    var x = 0.0;
    for (var i = 0; i < roots.length; i++) {
      if (i > 0) x += horizontalGap;
      place(roots[i], x, 0);
      x += widths[roots[i].key]!;
    }

    // Canvas bounds — every card plus a margin so connectors don't clip.
    var maxX = 0.0;
    var maxY = 0.0;
    for (final c in cards) {
      maxX = math.max(maxX, c.position.dx + cardWidth);
      maxY = math.max(maxY, c.position.dy + cardHeight);
    }
    const padding = 24.0;
    return TreeLayoutResult(
      cards: cards,
      edges: edges,
      size: Size(maxX + padding, maxY + padding),
    );
  }

  static double _sumWidths(
    List<EmailTreeNode> kids,
    double gap,
    double Function(EmailTreeNode) widthOf,
  ) {
    var total = 0.0;
    for (var i = 0; i < kids.length; i++) {
      if (i > 0) total += gap;
      total += widthOf(kids[i]);
    }
    return total;
  }
}
