import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../controllers/auth_controller.dart';
import '../controllers/payment_controller.dart';
import '../helpers/pref.dart';
import '../main.dart';
import '../services/free_vpn_session_service.dart';
import '../theme/nexus_theme.dart';
import '../widgets/canvas_background.dart';
import 'main_shell_screen.dart';

/// Tron VPN-style splash with shield ripple animation
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _rippleController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: const Interval(0, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: const Interval(0, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _fadeController.forward();
    });

    Future.delayed(const Duration(milliseconds: 1500), () async {
      if (!mounted) return;
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      // Keep AuthController for the whole app so Profile/Payment can Get.find it
      Get.put(AuthController(), permanent: true);
      if (Pref.isLoggedIn) {
        // Sync subscription from backend so "already purchased" is always correct
        try {
          await Get.find<AuthController>().refreshCurrentUserFromBackend();
        } catch (_) {}
      }
      // Re-sync App Store / Play entitlements if local state has no active sub
      if (!Pref.hasActiveSubscription) {
        try {
          await FreeVpnSessionService.syncFromServer();
        } catch (_) {}
        try {
          Get.put(PaymentController(), permanent: true);
          await Get.find<PaymentController>().syncSubscriptionFromStore();
        } catch (_) {}
      }
      // Always land on HomeScreen — Apple Guideline 5.1.1(v): apps must not
      // require sign-in or subscription before showing any functionality.
      // The subscription gate fires only when the user taps the VPN toggle.
      if (!mounted) return;
      Get.off(() => const MainShellScreen());
    });
  }

  @override
  void dispose() {
    _rippleController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    mq = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Dark gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  NexusTheme.bg,
                  NexusTheme.bg2,
                ],
              ),
            ),
          ),
          // Animated canvas background
          Positioned.fill(
            child: Opacity(
              opacity: 0.6,
              child: CanvasBackground(opacity: 0.6),
            ),
          ),
          // Content
          Center(
            child: AnimatedBuilder(
              animation: Listenable.merge([_fadeController, _rippleController]),
              builder: (context, _) {
                return SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _ShieldWithRipples(controller: _rippleController),
                        const SizedBox(height: 20),
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white,
                              Colors.white70,
                              NexusTheme.teal,
                            ],
                            stops: [0, 0.5, 1],
                          ).createShader(bounds),
                          blendMode: BlendMode.srcIn,
                          child: Text(
                            'Ghost Route',
                            style: GoogleFonts.outfit(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'MILITARY GRADE',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 12,
                            color: NexusTheme.text2,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ShieldWithRipples extends StatelessWidget {
  final AnimationController controller;

  const _ShieldWithRipples({required this.controller});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      height: 160,
      child: Stack(
        alignment: Alignment.center,
        children: [
          _RippleRing(size: 120, controller: controller, delay: 0),
          _RippleRing(size: 160, controller: controller, delay: 450),
          _RippleRing(size: 200, controller: controller, delay: 900),
          Container(
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
                  color: NexusTheme.teal.withOpacity(0.3),
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
          ),
        ],
      ),
    );
  }
}

class _RippleRing extends StatelessWidget {
  final double size;
  final AnimationController controller;
  final int delay;

  const _RippleRing({
    required this.size,
    required this.controller,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final t = (controller.value + delay / 1800.0) % 1.0;
        final scale = 0.5 + 0.5 * Curves.easeOut.transform(t);
        final opacity = 0.8 * (1 - t);
        return Transform.scale(
          scale: scale,
          child: Container(
            width: size,
            height: size,
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
