import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../controllers/home_controller.dart';
import '../helpers/privacy_score.dart';
import '../services/vpn_engine.dart';
import '../theme/nexus_theme.dart';

class PrivacyScoreCard extends StatelessWidget {
  const PrivacyScoreCard({super.key, required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isConnected =
          controller.vpnState.value == VpnEngine.vpnConnected;
      final score = privacyScoreForConnected(isConnected);
      final rowProgress = protectionProgressForConnected(isConnected);

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'PRIVACY SCORE',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 10,
                letterSpacing: 2,
                color: NexusTheme.text3,
              ),
            ),
            const SizedBox(height: 11),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: NexusTheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: NexusTheme.border),
              ),
              child: Column(
                children: [
                  _ScoreRing(score: score, isConnected: isConnected),
                  const SizedBox(height: 20),
                  ...List.generate(kPrivacyProtectionLabels.length, (index) {
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: index == kPrivacyProtectionLabels.length - 1
                            ? 0
                            : 12,
                      ),
                      child: _ProtectionRow(
                        label: kPrivacyProtectionLabels[index],
                        progress: rowProgress,
                        staggerIndex: index,
                        isConnected: isConnected,
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _ScoreRing extends StatelessWidget {
  const _ScoreRing({required this.score, required this.isConnected});

  final int score;
  final bool isConnected;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey(isConnected),
      tween: Tween(begin: 0, end: score / 100),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, progress, _) {
        final displayScore = (progress * 100).round();
        return SizedBox(
          width: 120,
          height: 120,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size(120, 120),
                painter: _ScoreRingPainter(progress: progress),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$displayScore%',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: isConnected ? NexusTheme.teal : NexusTheme.text2,
                    ),
                  ),
                  Text(
                    'Privacy Score',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 9,
                      letterSpacing: 1,
                      color: NexusTheme.text3,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ScoreRingPainter extends CustomPainter {
  _ScoreRingPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    const strokeWidth = 8.0;

    final trackPaint = Paint()
      ..color = NexusTheme.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    if (progress <= 0) return;

    final sweep = 2 * math.pi * progress;
    final arcPaint = Paint()
      ..shader = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: 3 * math.pi / 2,
        colors: [NexusTheme.teal, NexusTheme.blue],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweep,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ScoreRingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _ProtectionRow extends StatefulWidget {
  const _ProtectionRow({
    required this.label,
    required this.progress,
    required this.staggerIndex,
    required this.isConnected,
  });

  final String label;
  final double progress;
  final int staggerIndex;
  final bool isConnected;

  @override
  State<_ProtectionRow> createState() => _ProtectionRowState();
}

class _ProtectionRowState extends State<_ProtectionRow> {
  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey('${widget.label}-${widget.isConnected}'),
      tween: Tween(begin: 0, end: widget.progress),
      duration: Duration(milliseconds: 600 + widget.staggerIndex * 150),
      curve: Curves.easeOutCubic,
      builder: (context, animatedProgress, _) {
        final showCheck = animatedProgress >= 0.99;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.label,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 11,
                      color: showCheck ? NexusTheme.text : NexusTheme.text2,
                    ),
                  ),
                ),
                AnimatedOpacity(
                  opacity: showCheck ? 1 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.check_circle_rounded,
                    size: 16,
                    color: NexusTheme.teal,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: animatedProgress,
                minHeight: 4,
                backgroundColor: NexusTheme.border,
                valueColor: AlwaysStoppedAnimation<Color>(
                  showCheck ? NexusTheme.teal : NexusTheme.text3,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
