import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/nexus_theme.dart';

/// Full-screen "You're Secured" overlay shown on connect
class SecuredOverlay extends StatefulWidget {
  const SecuredOverlay({
    super.key,
    required this.visible,
    required this.serverCode,
    required this.ping,
    required this.onDismiss,
  });

  final bool visible;
  final String serverCode;
  final String ping;
  final VoidCallback onDismiss;

  @override
  State<SecuredOverlay> createState() => _SecuredOverlayState();
}

class _SecuredOverlayState extends State<SecuredOverlay>
    with TickerProviderStateMixin {
  late AnimationController _ripple1Controller;
  late AnimationController _ripple2Controller;
  late AnimationController _ripple3Controller;
  late AnimationController _ripple4Controller;
  late AnimationController _shieldPulseController;

  @override
  void initState() {
    super.initState();
    _ripple1Controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
    _ripple2Controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
    _ripple3Controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
    _ripple4Controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
    _shieldPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ripple1Controller.dispose();
    _ripple2Controller.dispose();
    _ripple3Controller.dispose();
    _ripple4Controller.dispose();
    _shieldPulseController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant SecuredOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visible && !oldWidget.visible) {
      _ripple1Controller.repeat();
      _ripple2Controller.repeat();
      _ripple3Controller.repeat();
      _ripple4Controller.repeat();
    } else if (!widget.visible) {
      _ripple1Controller.stop();
      _ripple2Controller.stop();
      _ripple3Controller.stop();
      _ripple4Controller.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !widget.visible,
      child: AnimatedOpacity(
        opacity: widget.visible ? 1 : 0,
        duration: const Duration(milliseconds: 300),
        child: Stack(
          children: [
            GestureDetector(
              onTap: () {},
              child: Container(
                color: Colors.transparent,
              ),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1,
                    colors: [
                      NexusTheme.teal.withOpacity(0.12),
                      NexusTheme.bg.withOpacity(0.97),
                    ],
                    stops: const [0, 0.7],
                  ),
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    color: Colors.transparent,
                  ),
                ),
              ),
            ),
            if (widget.visible)
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ShieldWithRipples(
                      ripple1: _ripple1Controller,
                      ripple2: _ripple2Controller,
                      ripple3: _ripple3Controller,
                      ripple4: _ripple4Controller,
                      shieldPulse: _shieldPulseController,
                    ),
                    const SizedBox(height: 32),
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white,
                          NexusTheme.teal,
                        ],
                        stops: [0.3, 1],
                      ).createShader(bounds),
                      blendMode: BlendMode.srcIn,
                      child: Text(
                        "You're Secured",
                        style: GoogleFonts.outfit(
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'TRON VPN · MILITARY GRADE',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 12,
                        color: NexusTheme.text2,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _SecStat(label: 'Server', value: widget.serverCode),
                        const SizedBox(width: 32),
                        _SecStat(label: 'Latency', value: widget.ping),
                        const SizedBox(width: 32),
                        const _SecStat(label: 'AES Bit', value: '256'),
                        const SizedBox(width: 32),
                        const _SecStat(label: 'DNS Leaks', value: '0'),
                      ],
                    ),
                    const SizedBox(height: 40),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: widget.onDismiss,
                        borderRadius: BorderRadius.circular(50),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [NexusTheme.teal, NexusTheme.blue],
                            ),
                            borderRadius: BorderRadius.circular(50),
                            boxShadow: [
                              BoxShadow(
                                color: NexusTheme.teal.withOpacity(0.3),
                                blurRadius: 32,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Text(
                            'Start Browsing →',
                            style: GoogleFonts.outfit(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ShieldWithRipples extends StatelessWidget {
  final AnimationController ripple1;
  final AnimationController ripple2;
  final AnimationController ripple3;
  final AnimationController ripple4;
  final AnimationController shieldPulse;

  const _ShieldWithRipples({
    required this.ripple1,
    required this.ripple2,
    required this.ripple3,
    required this.ripple4,
    required this.shieldPulse,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      height: 240,
      child: Stack(
        alignment: Alignment.center,
        children: [
          _RippleRing(
            size: 120,
            controller: ripple1,
            delay: 0,
          ),
          _RippleRing(
            size: 160,
            controller: ripple2,
            delay: 400,
          ),
          _RippleRing(
            size: 200,
            controller: ripple3,
            delay: 800,
          ),
          _RippleRing(
            size: 240,
            controller: ripple4,
            delay: 1200,
          ),
          AnimatedBuilder(
            animation: shieldPulse,
            builder: (context, _) {
              final glow = 0.3 + 0.2 * shieldPulse.value;
              return Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    center: Alignment.center,
                    colors: [
                      NexusTheme.teal.withOpacity(0.15),
                      NexusTheme.teal.withOpacity(0.03),
                    ],
                  ),
                  border: Border.all(
                    color: NexusTheme.teal.withOpacity(0.5),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: NexusTheme.teal.withOpacity(glow),
                      blurRadius: 40,
                    ),
                    BoxShadow(
                      color: NexusTheme.teal.withOpacity(0.05),
                      blurRadius: 20,
                      spreadRadius: -10,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.shield_rounded,
                  size: 40,
                  color: NexusTheme.teal,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _RippleRing extends StatefulWidget {
  final double size;
  final AnimationController controller;
  final int delay;

  const _RippleRing({
    required this.size,
    required this.controller,
    required this.delay,
  });

  @override
  State<_RippleRing> createState() => _RippleRingState();
}

class _RippleRingState extends State<_RippleRing> {
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) widget.controller.repeat();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final t = Curves.easeOut.transform(widget.controller.value);
        final scale = 0.5 + 0.5 * t;
        final opacity = 0.8 * (1 - t);
        return Transform.scale(
          scale: scale,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: NexusTheme.teal.withOpacity(opacity),
                width: 2,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SecStat extends StatelessWidget {
  final String label;
  final String value;

  const _SecStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: NexusTheme.teal,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 11,
            color: NexusTheme.text2,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}
