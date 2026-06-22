import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../apis/payment_api.dart';
import '../config/app_config.dart';
import '../controllers/payment_controller.dart';
import '../helpers/my_dialogs.dart';
import '../helpers/pref.dart';
import '../models/plan.dart';
import '../theme/nexus_theme.dart';
import '../widgets/canvas_background.dart';
import '../widgets/subscription_disclaimer_banner.dart';
import '../widgets/subscription_legal_footer.dart';
import 'login_screen.dart';
import 'signup_screen.dart';

class PremiumScreen extends StatefulWidget {
  final bool embedded;

  const PremiumScreen({super.key, this.embedded = false});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  List<Plan> _plans = [];
  bool _loadingPlans = false;

  @override
  void initState() {
    super.initState();
    _ensurePaymentController();
    _loadPlans();
  }

  void _ensurePaymentController() {
    if (!Get.isRegistered<PaymentController>()) {
      Get.put(PaymentController());
    }
    Get.find<PaymentController>().ensureStoreProductsLoaded();
  }

  Future<void> _loadPlans() async {
    setState(() => _loadingPlans = true);
    try {
      final plans = await PaymentApi.getPlans();
      if (mounted) setState(() => _plans = plans);
    } catch (_) {
      // Hero still works; sheet will retry on open.
    } finally {
      if (mounted) setState(() => _loadingPlans = false);
    }
  }

  Plan? get _yearlyPlan =>
      _plans.where((p) => p.interval == 'yearly').firstOrNull ?? _plans.lastOrNull;

  Plan? get _monthlyPlan =>
      _plans.where((p) => p.interval == 'monthly').firstOrNull ?? _plans.firstOrNull;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: NexusTheme.bg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned.fill(
            child: Opacity(opacity: 0.55, child: CanvasBackground(opacity: 0.55)),
          ),
          Positioned(
            top: -80,
            right: -60,
            child: _GlowOrb(color: NexusTheme.purple, size: 220, opacity: 0.14),
          ),
          Positioned(
            bottom: 120,
            left: -90,
            child: _GlowOrb(color: NexusTheme.teal, size: 260, opacity: 0.1),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(context),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(20, 8, 20, 120 + bottomInset),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildHero(context),
                        const SizedBox(height: 20),
                        _buildPricingRow(context),
                        const SizedBox(height: 24),
                        _buildBenefits(context),
                        const SizedBox(height: 20),
                        _buildSubscriptionDisclosure(context),
                        const SizedBox(height: 10),
                        const SubscriptionLegalFooter(),
                        const SizedBox(height: 8),
                        _buildRestorePurchases(context),
                        if (!Pref.isLoggedIn) ...[
                          const SizedBox(height: 12),
                          _buildAuthLinks(context),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildStickyCta(context, bottomInset),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 6, 16, 4),
      child: Row(
        children: [
          if (!widget.embedded)
            IconButton(
              onPressed: () => Get.back(),
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              color: NexusTheme.text2,
            )
          else
            const SizedBox(width: 48),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: NexusTheme.teal.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: NexusTheme.teal.withOpacity(0.35)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.workspace_premium_rounded, size: 16, color: NexusTheme.teal),
                const SizedBox(width: 6),
                Text(
                  'PLATINUM',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                    color: NexusTheme.teal,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildHero(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                NexusTheme.purple.withOpacity(0.14),
                NexusTheme.blue.withOpacity(0.08),
                NexusTheme.bg2.withOpacity(0.6),
              ],
            ),
            border: Border.all(color: NexusTheme.teal.withOpacity(0.22)),
            boxShadow: [
              BoxShadow(
                color: NexusTheme.purple.withOpacity(0.12),
                blurRadius: 32,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: NexusTheme.purple.withOpacity(0.35),
                          blurRadius: 40,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [NexusTheme.teal, NexusTheme.blue],
                      ),
                      border: Border.all(color: Colors.white24, width: 1.5),
                    ),
                    child: const Icon(
                      Icons.shield_rounded,
                      size: 40,
                      color: Color(0xFF001A14),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [NexusTheme.teal, NexusTheme.blue, NexusTheme.purple],
                ).createShader(bounds),
                blendMode: BlendMode.srcIn,
                child: Text(
                  'Unlock Platinum',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.8,
                    height: 1.1,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Full-speed VPN · Every location · Zero ads',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: NexusTheme.text2,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: NexusTheme.surface2,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: NexusTheme.border2),
                ),
                child: Text(
                  AppConfig.disclaimerPremiumHero,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: NexusTheme.teal.withOpacity(0.9),
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPricingRow(BuildContext context) {
    if (_loadingPlans) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 2.5, color: NexusTheme.teal),
          ),
        ),
      );
    }

    final monthly = _monthlyPlan;
    final yearly = _yearlyPlan;
    if (monthly == null && yearly == null) {
      return _buildFallbackPricingHint();
    }

    return Row(
      children: [
        if (monthly != null)
          Expanded(
            child: _PricingPreviewCard(
              plan: monthly,
              accent: NexusTheme.teal,
              onTap: () => _openCheckoutForPlan(monthly),
            ),
          ),
        if (monthly != null && yearly != null) const SizedBox(width: 12),
        if (yearly != null)
          Expanded(
            child: _PricingPreviewCard(
              plan: yearly,
              accent: NexusTheme.purple,
              highlighted: true,
              onTap: () => _openCheckoutForPlan(yearly),
            ),
          ),
      ],
    );
  }

  Widget _buildFallbackPricingHint() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: NexusTheme.surface,
        border: Border.all(color: NexusTheme.border2),
      ),
      child: Row(
        children: [
          Icon(Icons.payments_outlined, color: NexusTheme.gold, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'From \$5.00/month · \$35.00/year',
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: NexusTheme.text,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefits(BuildContext context) {
    const benefits = [
      _Benefit(Icons.bolt_rounded, 'Unlimited speed', NexusTheme.gold),
      _Benefit(Icons.public_rounded, '50+ countries', NexusTheme.teal),
      _Benefit(Icons.lock_rounded, 'Military encryption', NexusTheme.blue),
      _Benefit(Icons.block_rounded, 'Ad-free', NexusTheme.purple),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SubscriptionDisclaimerBanner(text: AppConfig.disclaimerPlatinumBenefits),
        const SizedBox(height: 18),
        Text(
          'INCLUDED WITH PLATINUM',
          style: GoogleFonts.jetBrainsMono(
            fontSize: 10,
            letterSpacing: 2.2,
            color: NexusTheme.text3,
          ),
        ),
        const SizedBox(height: 14),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.35,
          children: benefits
              .map((b) => _BenefitTile(icon: b.icon, label: b.label, color: b.color))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildStickyCta(BuildContext context, double bottomInset) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: EdgeInsets.fromLTRB(20, 14, 20, 14 + bottomInset),
          decoration: BoxDecoration(
            color: NexusTheme.bg2.withOpacity(0.92),
            border: Border(top: BorderSide(color: NexusTheme.border2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.35),
                blurRadius: 24,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                height: 56,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [NexusTheme.teal, NexusTheme.blue],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: NexusTheme.teal.withOpacity(0.35),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _showPlanSheet(context),
                      borderRadius: BorderRadius.circular(18),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.rocket_launch_rounded, size: 20, color: Color(0xFF001A14)),
                          const SizedBox(width: 10),
                          Text(
                            'Get Platinum',
                            style: GoogleFonts.outfit(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF001A14),
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubscriptionDisclosure(BuildContext context) {
    final disclosure = Platform.isIOS
        ? AppConfig.subscriptionDisclosureIos
        : AppConfig.subscriptionDisclosureAndroid;
    return Text(
      disclosure,
      textAlign: TextAlign.center,
      style: GoogleFonts.outfit(fontSize: 11, height: 1.45, color: NexusTheme.text3),
    );
  }

  Widget _buildRestorePurchases(BuildContext context) {
    return Center(
      child: TextButton.icon(
        onPressed: () async {
          if (!Get.isRegistered<PaymentController>()) Get.put(PaymentController());
          await Get.find<PaymentController>().restorePurchases();
        },
        icon: Icon(Icons.restore_rounded, size: 18, color: NexusTheme.teal.withOpacity(0.9)),
        label: Text(
          'Restore purchases',
          style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: NexusTheme.teal),
        ),
      ),
    );
  }

  Widget _buildAuthLinks(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: NexusTheme.surface,
        border: Border.all(color: NexusTheme.border),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => Get.to(() => const LoginScreen()),
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.outfit(fontSize: 14, color: NexusTheme.text2),
                children: [
                  const TextSpan(text: 'Already have an account? '),
                  TextSpan(
                    text: 'Sign in',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: NexusTheme.teal),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => Get.to(() => const SignupScreen()),
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.outfit(fontSize: 14, color: NexusTheme.text2),
                children: [
                  const TextSpan(text: 'New here? '),
                  TextSpan(
                    text: 'Create account',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: NexusTheme.teal),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openCheckoutForPlan(Plan plan) async {
    _ensurePaymentController();
    final plans = _plans.isNotEmpty ? _plans : await PaymentApi.getPlans();
    if (!mounted) return;
    if (Pref.isLoggedIn) {
      Get.find<PaymentController>().openCheckout(plan);
    } else {
      _showAccountOrGuestDialog(plan, plans);
    }
  }

  void _showAccountOrGuestDialog(Plan plan, List<Plan> plans) {
    Get.dialog(
      AlertDialog(
        backgroundColor: NexusTheme.bg2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: NexusTheme.border2),
        ),
        title: Text(
          'Continue to purchase',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 18, color: NexusTheme.text),
        ),
        content: Text(
          'Purchase without an account, or sign in to sync your subscription.',
          style: GoogleFonts.outfit(fontSize: 14, color: NexusTheme.text2, height: 1.45),
        ),
        actionsAlignment: MainAxisAlignment.start,
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          _dialogButton(
            label: 'Purchase now',
            filled: true,
            onTap: () {
              Get.back();
              if (!Get.isRegistered<PaymentController>()) Get.put(PaymentController());
              Get.find<PaymentController>().openCheckout(plan, guestMode: true);
            },
          ),
          const SizedBox(height: 8),
          _dialogButton(
            label: 'Sign in',
            filled: false,
            onTap: () {
              Get.back();
              Get.to(() => const LoginScreen());
            },
          ),
          TextButton(
            onPressed: () {
              Get.back();
              Get.to(() => SignupScreen(selectedPlan: plan, plans: plans));
            },
            child: Text('Create account', style: GoogleFonts.outfit(color: NexusTheme.text2)),
          ),
        ],
      ),
    );
  }

  Widget _dialogButton({required String label, required bool filled, required VoidCallback onTap}) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: filled
          ? ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: NexusTheme.teal,
                foregroundColor: const Color(0xFF001A14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(label, style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
            )
          : OutlinedButton(
              onPressed: onTap,
              style: OutlinedButton.styleFrom(
                foregroundColor: NexusTheme.teal,
                side: BorderSide(color: NexusTheme.teal.withOpacity(0.45)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(label, style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
            ),
    );
  }

  Future<void> _showPlanSheet(BuildContext context) async {
    try {
      _ensurePaymentController();
      final plans = _plans.isNotEmpty ? _plans : await PaymentApi.getPlans();
      if (!context.mounted) return;
      if (mounted && _plans.isEmpty) setState(() => _plans = plans);
      final isLoggedIn = Pref.isLoggedIn;
      showModalBottomSheet<void>(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (ctx) => PlanSheet(
          plans: plans,
          onSelect: (plan) {
            Get.back();
            if (isLoggedIn) {
              if (!Get.isRegistered<PaymentController>()) Get.put(PaymentController());
              Get.find<PaymentController>().openCheckout(plan);
            } else {
              _showAccountOrGuestDialog(plan, plans);
            }
          },
        ),
      );
    } catch (e) {
      if (context.mounted) {
        MyDialogs.error(msg: e.toString().replaceFirst('Exception: ', ''));
      }
    }
  }
}

class _GlowOrb extends StatelessWidget {
  final Color color;
  final double size;
  final double opacity;

  const _GlowOrb({required this.color, required this.size, this.opacity = 0.12});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withOpacity(opacity), color.withOpacity(0)],
        ),
      ),
    );
  }
}

class _PricingPreviewCard extends StatelessWidget {
  final Plan plan;
  final Color accent;
  final bool highlighted;
  final VoidCallback onTap;

  const _PricingPreviewCard({
    required this.plan,
    required this.accent,
    this.highlighted = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: highlighted
                  ? [accent.withOpacity(0.22), accent.withOpacity(0.06)]
                  : [NexusTheme.surface, NexusTheme.surface.withOpacity(0.5)],
            ),
            border: Border.all(
              color: highlighted ? accent.withOpacity(0.55) : NexusTheme.border2,
              width: highlighted ? 1.5 : 1,
            ),
            boxShadow: highlighted
                ? [BoxShadow(color: accent.withOpacity(0.15), blurRadius: 16, offset: const Offset(0, 6))]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (plan.badge != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    plan.badge!.toUpperCase(),
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                      color: accent,
                    ),
                  ),
                ),
              Text(
                plan.intervalLabel,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: NexusTheme.text2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                plan.displayPrice,
                style: GoogleFonts.outfit(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: highlighted ? accent : NexusTheme.text,
                  height: 1,
                ),
              ),
              Text(
                plan.period,
                style: GoogleFonts.outfit(fontSize: 11, color: NexusTheme.text3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Benefit {
  final IconData icon;
  final String label;
  final Color color;

  const _Benefit(this.icon, this.label, this.color);
}

class _BenefitTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _BenefitTile({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: NexusTheme.surface,
        border: Border.all(color: NexusTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [color.withOpacity(0.25), color.withOpacity(0.08)],
              ),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const Spacer(),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: NexusTheme.text,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

/// Reusable plan picker (Platinum monthly/yearly). Used by PremiumScreen and SignupScreen.
class PlanSheet extends StatefulWidget {
  final List<Plan> plans;
  final void Function(Plan plan) onSelect;
  final Plan? initialSelected;

  const PlanSheet({
    super.key,
    required this.plans,
    required this.onSelect,
    this.initialSelected,
  });

  @override
  State<PlanSheet> createState() => _PlanSheetState();
}

class _PlanSheetState extends State<PlanSheet> {
  late Plan _selected;

  List<Plan> get _sortedPlans =>
      List<Plan>.from(widget.plans)..sort((a, b) => a.index.compareTo(b.index));

  @override
  void initState() {
    super.initState();
    _selected = widget.initialSelected ??
        widget.plans.where((p) => p.interval == 'yearly').firstOrNull ??
        widget.plans.first;
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: BoxDecoration(
        color: NexusTheme.bg2,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: NexusTheme.border2),
        boxShadow: [
          BoxShadow(color: NexusTheme.purple.withOpacity(0.08), blurRadius: 40, offset: const Offset(0, -8)),
        ],
      ),
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: NexusTheme.text3.withOpacity(0.6),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 8),
            child: Column(
              children: [
                Text(
                  'Pick your plan',
                  style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w800, color: NexusTheme.text),
                ),
                const SizedBox(height: 6),
                Text(
                  'Cancel anytime · Secure payment',
                  style: GoogleFonts.outfit(fontSize: 13, color: NexusTheme.text2),
                ),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20, 8, 20, 16 + bottom),
              child: Column(
                children: [
                  ..._sortedPlans.map((plan) => _buildPlanCard(plan)),
                  const SizedBox(height: 16),
                  const SubscriptionLegalFooter(),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        gradient: const LinearGradient(
                          colors: [NexusTheme.teal, NexusTheme.teal2],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: NexusTheme.teal.withOpacity(0.35),
                            blurRadius: 16,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => widget.onSelect(_selected),
                          borderRadius: BorderRadius.circular(18),
                          child: Center(
                            child: Text(
                              'Continue with ${_selected.intervalLabel}',
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF001A14),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(Plan plan) {
    final isSelected = _selected.index == plan.index;
    final isYearly = plan.interval == 'yearly';
    final accent = isYearly ? NexusTheme.purple : NexusTheme.teal;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _selected = plan),
          borderRadius: BorderRadius.circular(22),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: isSelected
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [accent.withOpacity(0.2), accent.withOpacity(0.05)],
                    )
                  : null,
              color: isSelected ? null : NexusTheme.surface,
              border: Border.all(
                color: isSelected ? accent : NexusTheme.border2,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [BoxShadow(color: accent.withOpacity(0.18), blurRadius: 20, offset: const Offset(0, 6))]
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: isSelected ? accent : NexusTheme.text3, width: 2),
                    color: isSelected ? accent : Colors.transparent,
                  ),
                  child: isSelected
                      ? const Icon(Icons.check_rounded, size: 16, color: Color(0xFF1A1200))
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            plan.intervalLabel,
                            style: GoogleFonts.outfit(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: NexusTheme.text,
                            ),
                          ),
                          if (plan.badge != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: NexusTheme.purple.withOpacity(0.18),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                plan.badge!,
                                style: GoogleFonts.outfit(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: NexusTheme.purple,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        plan.description,
                        style: GoogleFonts.outfit(fontSize: 12, color: NexusTheme.text2),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      plan.displayPrice,
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: isSelected ? accent : NexusTheme.text,
                      ),
                    ),
                    Text(
                      plan.period,
                      style: GoogleFonts.outfit(fontSize: 11, color: NexusTheme.text3),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
