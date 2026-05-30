import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../apis/payment_api.dart';
import '../controllers/auth_controller.dart';
import '../controllers/payment_controller.dart';
import '../helpers/my_dialogs.dart';
import '../helpers/pref.dart';
import '../models/plan.dart';
import '../theme/nexus_theme.dart';
import '../widgets/canvas_background.dart';
import 'login_screen.dart';
import 'signup_screen.dart';

class PremiumScreen extends StatelessWidget {
  const PremiumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NexusTheme.bg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.5,
              child: const CanvasBackground(opacity: 0.5),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(context),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        _buildHero(context),
                        const SizedBox(height: 32),
                        _buildBenefits(context),
                        const SizedBox(height: 36),
                        _buildCta(context),
                        const SizedBox(height: 16),
                        _buildAlreadyHaveAccount(context),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Get.back(),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            color: NexusTheme.text2,
          ),
          const Spacer(),
          Text(
            'Tron VPN',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: NexusTheme.text,
            ),
          ),
          const Spacer(),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildHero(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            NexusTheme.teal.withOpacity(0.12),
            NexusTheme.gold.withOpacity(0.08),
            NexusTheme.purple.withOpacity(0.06),
          ],
        ),
        border: Border.all(
          color: NexusTheme.teal.withOpacity(0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: NexusTheme.teal.withOpacity(0.15),
            blurRadius: 40,
            spreadRadius: -4,
          ),
          BoxShadow(
            color: NexusTheme.gold.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  NexusTheme.gold,
                  NexusTheme.gold.withOpacity(0.7),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: NexusTheme.gold.withOpacity(0.4),
                  blurRadius: 28,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: const Icon(
              Icons.star_rounded,
              size: 44,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                NexusTheme.gold,
                NexusTheme.teal,
              ],
            ).createShader(bounds),
            blendMode: BlendMode.srcIn,
            child: Text(
              'Platinum & Platinum+',
              style: GoogleFonts.outfit(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose your plan · Weekly, monthly or yearly · Multiple devices',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: NexusTheme.text2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefits(BuildContext context) {
    final benefits = [
      _Benefit(
        icon: Icons.bolt_rounded,
        title: 'Unlimited speed',
        subtitle: 'No throttling, full bandwidth on all servers',
        color: NexusTheme.gold,
      ),
      _Benefit(
        icon: Icons.public_rounded,
        title: 'All locations',
        subtitle: 'Access 50+ countries and 200+ servers',
        color: NexusTheme.teal,
      ),
      _Benefit(
        icon: Icons.support_agent_rounded,
        title: 'Priority support',
        subtitle: '24/7 dedicated help when you need it',
        color: NexusTheme.blue,
      ),
      _Benefit(
        icon: Icons.block_rounded,
        title: 'Ad-free experience',
        subtitle: 'Clean, distraction-free VPN usage',
        color: NexusTheme.purple,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'WHAT YOU GET',
          style: GoogleFonts.jetBrainsMono(
            fontSize: 11,
            letterSpacing: 2,
            color: NexusTheme.text3,
          ),
        ),
        const SizedBox(height: 16),
        ...benefits.asMap().entries.map((e) {
          final b = e.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _BenefitCard(
              icon: b.icon,
              title: b.title,
              subtitle: b.subtitle,
              color: b.color,
            ),
          );
        }),
      ],
    );
  }

  Widget _buildCta(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showPlanSheet(context),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  NexusTheme.gold,
                  NexusTheme.gold.withOpacity(0.85),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: NexusTheme.gold.withOpacity(0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              'Choose plan',
              style: GoogleFonts.outfit(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAlreadyHaveAccount(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: () => Get.to(() => const LoginScreen()),
        child: RichText(
          text: TextSpan(
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: NexusTheme.text2,
            ),
            children: [
              const TextSpan(text: 'Already have an account? '),
              TextSpan(
                text: 'Login',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w700,
                  color: NexusTheme.teal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPlanSheet(BuildContext context) async {
    try {
      final plans = await PaymentApi.getPlans();
      if (!context.mounted) return;
      final isLoggedIn = Pref.isLoggedIn;
      showModalBottomSheet<void>(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (ctx) => PlanSheet(
          plans: plans,
          onSelect: (plan) {
            Get.back(); // close sheet
            if (isLoggedIn) {
              if (!Get.isRegistered<PaymentController>()) {
                Get.put(PaymentController());
              }
              Get.find<PaymentController>().openCheckout(plan);
            } else {
              Get.to(() => SignupScreen(selectedPlan: plan, plans: plans));
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

/// Reusable plan picker (Platinum & Platinum+ with weekly/monthly/yearly). Used by PremiumScreen and SignupScreen.
/// [plans] come from backend (GET /api/payments/plans).
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

  List<Plan> get _platinumPlans =>
      widget.plans.where((p) => p.isPlatinum).toList()..sort((a, b) => a.index.compareTo(b.index));
  List<Plan> get _platinumPlusPlans =>
      widget.plans.where((p) => p.isPlatinumPlus).toList()..sort((a, b) => a.index.compareTo(b.index));

  @override
  void initState() {
    super.initState();
    _selected = widget.initialSelected ??
        widget.plans.where((p) => p.interval == 'yearly').firstOrNull ??
        widget.plans.first;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: NexusTheme.bg2,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: NexusTheme.border2),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: NexusTheme.text3,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Choose your plan',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: NexusTheme.text,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Platinum or Platinum+ · Weekly, monthly or yearly',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: NexusTheme.text2,
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20, 8, 20, 20 + MediaQuery.of(context).padding.bottom),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_platinumPlans.isNotEmpty)
                    _buildTierSection(
                      context,
                      tierName: 'Platinum',
                      subtitle: 'Full speed · 50+ locations · Ad-free',
                      accentColor: NexusTheme.gold,
                      plans: _platinumPlans,
                    ),
                  if (_platinumPlans.isNotEmpty && _platinumPlusPlans.isNotEmpty)
                    const SizedBox(height: 24),
                  if (_platinumPlusPlans.isNotEmpty)
                    _buildTierSection(
                      context,
                      tierName: 'Platinum +',
                      subtitle: 'More devices · Priority support · 80+ locations',
                      accentColor: NexusTheme.purple,
                      plans: _platinumPlusPlans,
                    ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => widget.onSelect(_selected),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                NexusTheme.teal,
                                NexusTheme.teal2,
                              ],
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Continue',
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
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

  Widget _buildTierSection(
    BuildContext context, {
    required String tierName,
    required String subtitle,
    required Color accentColor,
    required List<Plan> plans,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                tierName,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: accentColor,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: GoogleFonts.outfit(
            fontSize: 12,
            color: NexusTheme.text2,
          ),
        ),
        const SizedBox(height: 12),
        ...plans.map((plan) => _buildPlanTile(context, plan, accentColor)),
      ],
    );
  }

  Widget _buildPlanTile(BuildContext context, Plan plan, Color tierColor) {
    final isSelected = _selected.index == plan.index;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _selected = plan),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? tierColor : NexusTheme.border2,
                width: isSelected ? 2 : 1,
              ),
              color: isSelected ? tierColor.withOpacity(0.1) : NexusTheme.surface,
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: tierColor.withOpacity(0.15),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? tierColor : NexusTheme.text3,
                      width: 2,
                    ),
                    color: isSelected ? tierColor : Colors.transparent,
                  ),
                  child: isSelected
                      ? const Icon(Icons.check_rounded, size: 14, color: Colors.black87)
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
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: NexusTheme.text,
                            ),
                          ),
                          if (plan.badge != null && plan.badge!.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: NexusTheme.gold.withOpacity(0.25),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                plan.badge!,
                                style: GoogleFonts.outfit(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: NexusTheme.gold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        plan.description,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: NexusTheme.text2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.devices_rounded, size: 14, color: NexusTheme.text3),
                          const SizedBox(width: 4),
                          Text(
                            '${plan.devices} devices',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: NexusTheme.text2,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      plan.price,
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: tierColor,
                      ),
                    ),
                    Text(
                      plan.period,
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: NexusTheme.text3,
                      ),
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

class _Benefit {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  _Benefit({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });
}

class _BenefitCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _BenefitCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: NexusTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: NexusTheme.border),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: color.withOpacity(0.15),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: NexusTheme.text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: NexusTheme.text2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
