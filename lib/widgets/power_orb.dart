import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/nexus_theme.dart';

/// Power orb with orbital rings, ring fill, scan sweep, floating bits - from vpn-premium.html
class PowerOrb extends StatefulWidget {
  const PowerOrb({
    super.key,
    required this.isConnected,
    required this.isConnecting,
    required this.onTap,
  });

  final bool isConnected;
  final bool isConnecting;
  final VoidCallback onTap;

  @override
  State<PowerOrb> createState() => _PowerOrbState();
}

class _PowerOrbState extends State<PowerOrb>
    with TickerProviderStateMixin {
  late AnimationController _orbit1Controller;
  late AnimationController _orbit2Controller;
  late AnimationController _sweepController;
  late AnimationController _glowController;
  late AnimationController _ringController;

  @override
  void initState() {
    super.initState();
    _orbit1Controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
    _orbit2Controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
    _sweepController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
  }

  @override
  void didUpdateWidget(covariant PowerOrb oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isConnected && !oldWidget.isConnected) {
      _ringController.forward();
    } else if (!widget.isConnected && oldWidget.isConnected) {
      _ringController.reverse();
    }
  }

  @override
  void dispose() {
    _orbit1Controller.dispose();
    _orbit2Controller.dispose();
    _sweepController.dispose();
    _glowController.dispose();
    _ringController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const size = 220.0;
    const coreSize = 140.0;
    const orbit1Size = 190.0;
    const orbit2Size = 165.0;

    return GestureDetector(
      onTap: widget.isConnecting ? null : widget.onTap,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Orbit 1
            AnimatedBuilder(
              animation: _orbit1Controller,
              builder: (_, child) => Transform.rotate(
                angle: _orbit1Controller.value * 2 * math.pi,
                child: child,
              ),
              child: CustomPaint(
                size: const Size(orbit1Size, orbit1Size),
                painter: _OrbitRingPainter(
                  color: NexusTheme.teal.withOpacity(0.1),
                  showDot: widget.isConnected,
                  dotColor: NexusTheme.teal,
                ),
              ),
            ),
            // Orbit 2
            AnimatedBuilder(
              animation: _orbit2Controller,
              builder: (_, child) => Transform.rotate(
                angle: -_orbit2Controller.value * 2 * math.pi,
                child: child,
              ),
              child: CustomPaint(
                size: const Size(orbit2Size, orbit2Size),
                painter: _OrbitRingPainter(
                  color: NexusTheme.teal.withOpacity(0.1),
                  showDot: widget.isConnected,
                  dotColor: NexusTheme.blue,
                ),
              ),
            ),
            // Ring fill (progress)
            AnimatedBuilder(
              animation: _ringController,
              builder: (_, __) => CustomPaint(
                size: const Size(size, size),
                painter: _RingFillPainter(
                  progress: Curves.easeInOutCubic.transform(_ringController.value),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [NexusTheme.teal, NexusTheme.blue],
                  ),
                ),
              ),
            ),
            // Power core
            _PowerCore(
              size: coreSize,
              isConnected: widget.isConnected,
              isConnecting: widget.isConnecting,
              glowProgress: _glowController,
              sweepProgress: _sweepController,
            ),
          ],
        ),
      ),
    );
  }
}

class _OrbitRingPainter extends CustomPainter {
  final Color color;
  final bool showDot;
  final Color dotColor;

  _OrbitRingPainter({
    required this.color,
    required this.showDot,
    required this.dotColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final rect = Rect.fromCircle(center: center, radius: size.width / 2 - 1);
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    _drawDashedCircle(canvas, rect, paint);

    if (showDot) {
      final dotPaint = Paint()
        ..color = dotColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(size.width / 2, 0), 2.5, dotPaint);
    }
  }

  void _drawDashedCircle(Canvas canvas, Rect rect, Paint paint) {
    const dashLength = 4.0;
    const gapLength = 6.0;
    final path = Path()..addOval(rect);
    final pathMetrics = path.computeMetrics();
    for (final metric in pathMetrics) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = (distance + dashLength).clamp(0.0, metric.length);
        final extractPath = metric.extractPath(distance, end);
        canvas.drawPath(extractPath, paint);
        distance += dashLength + gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _OrbitRingPainter oldDelegate) =>
      oldDelegate.showDot != showDot;
}

class _RingFillPainter extends CustomPainter {
  final double progress;
  final Gradient gradient;

  _RingFillPainter({required this.progress, required this.gradient});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final center = Offset(size.width / 2, size.height / 2);
    const radius = 100.0;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final sweepAngle = 2 * math.pi * progress;
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-math.pi / 2);
    canvas.translate(-center.dx, -center.dy);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      0,
      sweepAngle,
      false,
      paint,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _RingFillPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _PowerCore extends StatelessWidget {
  final double size;
  final bool isConnected;
  final bool isConnecting;
  final AnimationController glowProgress;
  final AnimationController sweepProgress;

  const _PowerCore({
    required this.size,
    required this.isConnected,
    required this.isConnecting,
    required this.glowProgress,
    required this.sweepProgress,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([glowProgress, sweepProgress]),
      builder: (context, _) {
        final glow = isConnected
            ? 0.15 + 0.15 * (glowProgress.value * 2 - 1).abs()
            : 0.0;
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              center: const Alignment(0.4, 0.35),
              colors: [
                const Color(0xFF0F2520),
                const Color(0xFF050F0C),
              ],
            ),
            border: Border.all(
              color: isConnected
                  ? NexusTheme.teal.withOpacity(0.45)
                  : NexusTheme.teal.withOpacity(0.12),
              width: 2,
            ),
            boxShadow: isConnected
                ? [
                    BoxShadow(
                      color: NexusTheme.teal.withOpacity(glow),
                      blurRadius: 30,
                      spreadRadius: 2,
                    ),
                    BoxShadow(
                      color: NexusTheme.teal.withOpacity(0.06),
                      blurRadius: 30,
                      spreadRadius: 0,
                    ),
                  ]
                : null,
          ),
          child: ClipOval(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Scan sweep when connected
                if (isConnected)
                  Transform.rotate(
                    angle: sweepProgress.value * 2 * math.pi,
                    child: CustomPaint(
                      size: Size(size, size),
                      painter: _ScanSweepPainter(),
                    ),
                  ),
                // Float bits when connected
                if (isConnected) const _FloatBits(),
                // Gradient overlay
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      center: const Alignment(0.5, 0),
                      colors: [
                        NexusTheme.teal.withOpacity(0.05),
                        Colors.transparent,
                      ],
                      stops: const [0, 0.6],
                    ),
                  ),
                ),
                // Icon and text
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isConnected
                            ? NexusTheme.teal.withOpacity(0.12)
                            : NexusTheme.teal.withOpacity(0.06),
                        border: Border.all(
                          color: isConnected
                              ? NexusTheme.teal.withOpacity(0.3)
                              : NexusTheme.teal.withOpacity(0.12),
                          width: 1,
                        ),
                        boxShadow: isConnected
                            ? [
                                BoxShadow(
                                  color: NexusTheme.teal.withOpacity(0.2),
                                  blurRadius: 16,
                                ),
                              ]
                            : null,
                      ),
                      child: isConnecting
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: NexusTheme.teal,
                              ),
                            )
                          : Icon(
                              Icons.power_settings_new,
                              size: 26,
                              color: isConnected
                                  ? NexusTheme.teal
                                  : NexusTheme.text3,
                            ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isConnecting
                          ? 'CONNECTING'
                          : isConnected
                              ? 'SECURED'
                              : 'CONNECT',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 11,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w500,
                        color: isConnected || isConnecting
                            ? NexusTheme.teal
                            : NexusTheme.text3,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ScanSweepPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final rect = Rect.fromCircle(center: center, radius: size.width / 2);
    final paint = Paint()
      ..shader = SweepGradient(
        center: Alignment.center,
        startAngle: 0,
        endAngle: math.pi * 0.33,
        colors: [
          NexusTheme.teal.withOpacity(0.15),
          Colors.transparent,
        ],
      ).createShader(rect);
    canvas.drawCircle(center, size.width / 2, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _FloatBits extends StatefulWidget {
  const _FloatBits();

  @override
  State<_FloatBits> createState() => _FloatBitsState();
}

class _FloatBitsState extends State<_FloatBits>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          size: const Size(140, 140),
          painter: _FloatBitsPainter(progress: _controller.value),
        );
      },
    );
  }
}

class _FloatBitsPainter extends CustomPainter {
  final double progress;

  _FloatBitsPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final positions = [
      Offset(size.width * 0.45, size.height * 0.9),
      Offset(size.width * 0.55, size.height * 0.85),
      Offset(size.width * 0.5, size.height * 0.95),
      Offset(size.width * 0.4, size.height * 0.8),
      Offset(size.width * 0.6, size.height * 0.92),
    ];
    for (var i = 0; i < positions.length; i++) {
      final p = positions[i];
      final phase = (progress + i * 0.2) % 1.0;
      final y = p.dy - phase * 60;
      final opacity = (1 - phase) * 0.8;
      if (opacity > 0) {
        final paint = Paint()
          ..color = NexusTheme.teal.withOpacity(opacity)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(p.dx, y), 1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _FloatBitsPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
