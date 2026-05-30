import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../theme/nexus_theme.dart';

/// Animated particle network background - ported from vpn-premium.html drawBg
class CanvasBackground extends StatefulWidget {
  const CanvasBackground({super.key, this.opacity = 0.6});

  final double opacity;

  @override
  State<CanvasBackground> createState() => _CanvasBackgroundState();
}

class _CanvasBackgroundState extends State<CanvasBackground>
    with SingleTickerProviderStateMixin {
  late List<_Node> _nodes;
  late Ticker _ticker;
  final _rng = math.Random();

  @override
  void initState() {
    super.initState();
    _initNodes();
    _ticker = createTicker((_) {
      for (final n in _nodes) {
        n.x += n.vx;
        n.y += n.vy;
        if (n.x < 0 || n.x > 1) n.vx *= -1;
        if (n.y < 0 || n.y > 1) n.vy *= -1;
      }
      if (mounted) setState(() {});
    });
    _ticker.start();
  }

  void _initNodes() {
    _nodes = List.generate(50, (i) {
      return _Node(
        x: _rng.nextDouble(),
        y: _rng.nextDouble(),
        vx: (_rng.nextDouble() - 0.5) * 0.003,
        vy: (_rng.nextDouble() - 0.5) * 0.003,
        r: _rng.nextDouble() * 1.5 + 0.5,
        op: _rng.nextDouble() * 0.5 + 0.1,
      );
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _CanvasBgPainter(
        nodes: _nodes,
        opacity: widget.opacity,
      ),
      size: Size.infinite,
    );
  }
}

class _Node {
  double x;
  double y;
  double vx;
  double vy;
  double r;
  double op;
  _Node({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.r,
    required this.op,
  });
}

class _CanvasBgPainter extends CustomPainter {
  final List<_Node> nodes;
  final double opacity;

  _CanvasBgPainter({
    required this.nodes,
    required this.opacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final maxDist = 130.0;

    // Draw connections
    for (int i = 0; i < nodes.length; i++) {
      for (int j = i + 1; j < nodes.length; j++) {
        final ni = nodes[i];
        final nj = nodes[j];
        final x1 = ni.x * w;
        final y1 = ni.y * h;
        final x2 = nj.x * w;
        final y2 = nj.y * h;
        final dx = x1 - x2;
        final dy = y1 - y2;
        final d = math.sqrt(dx * dx + dy * dy);
        if (d < maxDist) {
          final alpha = (1 - d / maxDist) * 0.08 * opacity;
          final paint = Paint()
            ..color = NexusTheme.teal.withOpacity(alpha)
            ..strokeWidth = 0.5
            ..style = PaintingStyle.stroke;
          canvas.drawLine(Offset(x1, y1), Offset(x2, y2), paint);
        }
      }
    }

    // Draw nodes
    for (final n in nodes) {
      final paint = Paint()
        ..color = NexusTheme.teal.withOpacity(n.op * opacity)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
        Offset(n.x * w, n.y * h),
        n.r,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CanvasBgPainter oldDelegate) => true;
}
