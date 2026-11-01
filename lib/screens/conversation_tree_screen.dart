import 'dart:async';

import 'package:flutter/material.dart';

import '../models/email_thread.dart';
import '../services/gmail_service.dart';
import '../utils/tree_layout.dart';
import '../widgets/email/tree_message_card.dart';

/// Full-screen visualisation of a single conversation as a dynamically laid-out
/// reply tree on a pannable canvas.
///
/// - The canvas scrolls both vertically and horizontally, so card sizes stay
///   fixed regardless of screen size.
/// - The background is a simple dark "space" with a dotted star grid.
/// - Every 3 seconds the conversation is re-fetched so newly-arrived replies
///   (branch growth) are picked up and the tree is re-laid-out.
/// - Branches can be expanded / collapsed; the layout recomputes accordingly.
class ConversationTreeScreen extends StatefulWidget {
  const ConversationTreeScreen({
    super.key,
    required this.service,
    required this.thread,
  });

  final GmailService service;
  final EmailThread thread;

  @override
  State<ConversationTreeScreen> createState() => _ConversationTreeScreenState();
}

class _ConversationTreeScreenState extends State<ConversationTreeScreen> {
  static const double _cardW = 230;
  static const double _cardH = 150;
  static const double _hGap = 32;
  static const double _vGap = 64;
  static const Duration _pollInterval = Duration(seconds: 3);

  late EmailThread _thread;
  final Set<String> _collapsed = <String>{};
  TreeLayoutResult _layout =
      const TreeLayoutResult(cards: [], edges: [], size: Size.zero);

  Timer? _poll;
  bool _polling = false;

  final ScrollController _vScroll = ScrollController();
  final ScrollController _hScroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _thread = widget.thread;
    _layout = _compute();
    _poll = Timer.periodic(_pollInterval, (_) => _tick());
  }

  @override
  void dispose() {
    _poll?.cancel();
    _vScroll.dispose();
    _hScroll.dispose();
    super.dispose();
  }

  TreeLayoutResult _compute() => TreeLayout.compute(
        roots: _thread.roots,
        collapsed: _collapsed,
        cardWidth: _cardW,
        cardHeight: _cardH,
        horizontalGap: _hGap,
        verticalGap: _vGap,
      );

  /// Re-fetch the conversation and re-layout only when it actually changed,
  /// so the tree visibly grows when new replies arrive (and stays put when the
  /// conversation is halted).
  Future<void> _tick() async {
    if (_polling) return;
    _polling = true;
    try {
      final fresh = await widget.service.fetchThread(_thread.id);
      if (!mounted || fresh == null) return;
      if (_changed(_thread, fresh)) {
        setState(() {
          _thread = fresh;
          _layout = _compute();
        });
      }
    } finally {
      _polling = false;
    }
  }

  bool _changed(EmailThread a, EmailThread b) {
    if (b.messageCount != a.messageCount) return true;
    if (b.latestDate != a.latestDate) return true;
    if (b.hasUnread != a.hasUnread) return true;
    final aIds = a.messages.map((m) => m.id).toSet();
    final bIds = b.messages.map((m) => m.id).toSet();
    return aIds.length != bIds.length || !aIds.containsAll(bIds);
  }

  void _toggleBranch(String key) {
    setState(() {
      if (_collapsed.contains(key)) {
        _collapsed.remove(key);
      } else {
        _collapsed.add(key);
      }
      _layout = _compute();
    });
  }

  @override
  Widget build(BuildContext context) {
    final subject =
        _thread.subject.isEmpty ? '(no subject)' : _thread.subject;

    return Scaffold(
      backgroundColor: const Color(0xFF05070F),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          subject,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.white70),
        ),
        iconTheme: const IconThemeData(color: Colors.white70),
      ),
      body: _layout.cards.isEmpty
          ? const Center(
              child: Text(
                'No messages to display.',
                style: TextStyle(color: Colors.white54),
              ),
            )
          : Scrollbar(
              thumbVisibility: true,
              controller: _vScroll,
              child: SingleChildScrollView(
                controller: _vScroll,
                child: Scrollbar(
                  thumbVisibility: true,
                  controller: _hScroll,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    controller: _hScroll,
                    child: SizedBox(
                      width: _layout.size.width,
                      height: _layout.size.height,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned.fill(
                            child: CustomPaint(painter: _SpaceDottedPainter()),
                          ),
                          Positioned.fill(
                            child: CustomPaint(
                              painter: _ConnectorPainter(_layout.edges),
                            ),
                          ),
                          for (final c in _layout.cards)
                            Positioned(
                              left: c.position.dx,
                              top: c.position.dy,
                              width: _cardW,
                              height: _cardH,
                              child: TreeMessageCard(
                                key: ValueKey(c.key),
                                message: c.node.message,
                                isRoot: c.isRoot,
                                hasChildren: c.node.hasChildren,
                                expanded: !_collapsed.contains(c.key),
                                onToggleExpand: () => _toggleBranch(c.key),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

/// Dark space background with a regular dotted grid and a sparse sprinkling of
/// brighter "stars".
class _SpaceDottedPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF0B1026), Color(0xFF06080F)],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, bg);

    const step = 26.0;
    final gridDot = Paint()..color = Colors.white.withValues(alpha: 0.05);
    final star = Paint()..color = Colors.white.withValues(alpha: 0.45);

    for (double x = step / 2; x < size.width; x += step) {
      for (double y = step / 2; y < size.height; y += step) {
        final ix = (x / step).round();
        final iy = (y / step).round();
        if ((ix * 3 + iy * 7) % 13 == 0) {
          canvas.drawCircle(Offset(x, y), 1.4, star);
        } else {
          canvas.drawCircle(Offset(x, y), 0.7, gridDot);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Draws smooth S-curve connectors between parent and child cards.
class _ConnectorPainter extends CustomPainter {
  _ConnectorPainter(this.edges);

  final List<TreeEdge> edges;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF4A9FE3).withValues(alpha: 0.55)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (final e in edges) {
      final midY = (e.from.dy + e.to.dy) / 2;
      final path = Path()
        ..moveTo(e.from.dx, e.from.dy)
        ..cubicTo(e.from.dx, midY, e.to.dx, midY, e.to.dx, e.to.dy);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ConnectorPainter old) =>
      old.edges.length != edges.length;
}
