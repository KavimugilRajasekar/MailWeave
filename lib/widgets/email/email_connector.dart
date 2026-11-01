import 'package:flutter/material.dart';

/// Draws a subtle elbow connector (a short vertical drop + a horizontal stub)
/// that links a reply to its parent. Shown at the top of each non-root node.
class EmailConnector extends StatelessWidget {
  const EmailConnector({super.key, required this.gap, required this.depth});

  /// Horizontal indent per tree level.
  final double gap;

  /// Depth of the node this connector belongs to.
  final int depth;

  static const double lineHeight = 14;

  @override
  Widget build(BuildContext context) {
    if (depth <= 0) return const SizedBox.shrink();
    final color = Theme.of(context).colorScheme.outlineVariant;
    return SizedBox(
      width: depth * gap,
      height: lineHeight,
      child: CustomPaint(painter: _ElbowPainter(gap: gap, depth: depth, color: color)),
    );
  }
}

class _ElbowPainter extends CustomPainter {
  const _ElbowPainter({required this.gap, required this.depth, required this.color});

  final double gap;
  final int depth;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Spine sits where the parent's gutter is: (depth - 0.5) * gap.
    final spineX = (depth - 0.5) * gap;
    final y = size.height;
    final path = Path()
      ..moveTo(spineX, 0)
      ..lineTo(spineX, y)
      ..lineTo(size.width, y);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ElbowPainter old) =>
      old.gap != gap || old.depth != depth || old.color != color;
}
