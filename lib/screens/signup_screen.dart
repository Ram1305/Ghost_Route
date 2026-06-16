import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../apis/payment_api.dart';
import '../controllers/auth_controller.dart';
import '../controllers/payment_controller.dart';
import '../helpers/my_dialogs.dart';
import '../models/plan.dart';
import '../theme/nexus_theme.dart';
import '../widgets/canvas_background.dart';
import '../widgets/subscription_legal_footer.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'premium_screen.dart';

class SignupScreen extends StatefulWidget {
  final Plan? selectedPlan;
  final List<Plan>? plans;

  const SignupScreen({super.key, this.selectedPlan, this.plans});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  Plan? _plan;
  List<Plan>? _plans;
  final _auth = Get.find<AuthController>();

  final _username = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();

  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _plan = widget.selectedPlan;
    _plans = widget.plans;
    if (_plan == null && _plans != null && _plans!.isNotEmpty) {
      _plan = _plans!.where((p) => p.interval == 'yearly').firstOrNull ?? _plans!.first;
    }
  }

  @override
  void dispose() {
    _username.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  void _changePlan() async {
    List<Plan> plans = _plans ?? [];
    if (plans.isEmpty) {
      try {
        plans = await PaymentApi.getPlans();
        if (mounted) setState(() => _plans = plans);
      } catch (e) {
        if (mounted) MyDialogs.error(msg: e.toString().replaceFirst('Exception: ', ''));
        return;
      }
    }
    if (!mounted || plans.isEmpty) return;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => PlanSheet(
        plans: plans,
        initialSelected: _plan,
        onSelect: (plan) {
          setState(() => _plan = plan);
          Get.back();
        },
      ),
    );
  }

  Future<void> _signUp() async {
    if (_loading) return;
    setState(() => _loading = true);
    final ok = await _auth.signUp(
      username: _username.text,
      email: _email.text,
      phone: _phone.text,
      password: _password.text,
      confirmPassword: _confirmPassword.text,
    );
    setState(() => _loading = false);
    if (!ok) return;
    if (!mounted) return;
    // No plan selected → go straight to home; user can subscribe anytime from Premium.
    if (_plan == null) {
      Get.offAll(() => HomeScreen());
      return;
    }
    final subscribe = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: NexusTheme.surface,
        title: Text(
          'Subscribe now?',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w700,
            color: NexusTheme.text,
          ),
        ),
        content: Text(
          'Your account was created. You can subscribe now or continue and subscribe later from Premium.',
          style: GoogleFonts.outfit(fontSize: 14, color: NexusTheme.text2),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Later', style: GoogleFonts.outfit(color: NexusTheme.text2)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Subscribe', style: GoogleFonts.outfit(color: NexusTheme.teal, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (subscribe == true && _plan != null) {
      if (!Get.isRegistered<PaymentController>()) {
        Get.put(PaymentController());
      }
      await Get.find<PaymentController>().openCheckout(_plan!, fromSignup: true);
    } else {
      Get.offAll(() => HomeScreen());
    }
  }

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
                _buildAppBar(),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 16),
                        _buildPlanCard(_plan, _plans),
                        const SizedBox(height: 12),
                        const SubscriptionLegalFooter(),
                        const SizedBox(height: 24),
                        _buildTextField(
                          controller: _username,
                          label: 'Username',
                          hint: 'Enter username',
                          icon: Icons.person_rounded,
                        ),
                        const SizedBox(height: 14),
                        _buildTextField(
                          controller: _email,
                          label: 'Email',
                          hint: 'Enter email',
                          icon: Icons.email_rounded,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 14),
                        _buildTextField(
                          controller: _phone,
                          label: 'Mobile number (optional)',
                          hint: 'Enter mobile number',
                          icon: Icons.phone_rounded,
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 14),
                        _buildTextField(
                          controller: _password,
                          label: 'Password',
                          hint: 'Enter password',
                          icon: Icons.lock_rounded,
                          obscureText: true,
                        ),
                        const SizedBox(height: 14),
                        _buildTextField(
                          controller: _confirmPassword,
                          label: 'Confirm password',
                          hint: 'Confirm password',
                          icon: Icons.lock_rounded,
                          obscureText: true,
                        ),
                        const SizedBox(height: 28),
                        _buildSignUpButton(),
                        const SizedBox(height: 20),
                        _buildAlreadyHaveAccount(),
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

  Widget _buildAppBar() {
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
            'Sign up',
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

  Widget _buildPlanCard(Plan? plan, List<Plan>? plans) {
    final hasPlan = plan != null;
    final accent = plan?.isPlatinumPlus == true ? NexusTheme.purple : NexusTheme.gold;
    return InkWell(
      onTap: _changePlan,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasPlan ? accent.withOpacity(0.4) : NexusTheme.border,
          ),
          color: hasPlan ? accent.withOpacity(0.1) : NexusTheme.surface,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasPlan ? plan!.displayName : 'Subscribe (optional)',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: NexusTheme.text,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hasPlan
                        ? '${plan!.displayPrice} ${plan.period} · ${plan.description}'
                        : 'You can subscribe now or any time after signup',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: NexusTheme.text2,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              hasPlan ? 'Change' : 'Select',
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: hasPlan ? accent : NexusTheme.teal,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 12,
              color: hasPlan ? accent : NexusTheme.teal,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    String? label,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 11,
              letterSpacing: 1.5,
              color: NexusTheme.text3,
            ),
          ),
          const SizedBox(height: 6),
        ],
        TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          style: GoogleFonts.outfit(
            fontSize: 14,
            color: NexusTheme.text,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.outfit(color: NexusTheme.text3, fontSize: 14),
            prefixIcon: Icon(icon, size: 20, color: NexusTheme.text3),
            filled: true,
            fillColor: NexusTheme.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: NexusTheme.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: NexusTheme.border),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildSignUpButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _loading ? null : _signUp,
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
            child: _loading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.black87,
                    ),
                  )
                : Text(
                    'Sign up',
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

  Widget _buildAlreadyHaveAccount() {
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
}
