import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/app_config.dart';
import '../controllers/auth_controller.dart';
import '../controllers/main_nav_controller.dart';
import '../controllers/payment_controller.dart';
import '../helpers/pref.dart';
import '../models/subscription.dart';
import '../models/user.dart';
import '../theme/nexus_theme.dart';
import '../widgets/canvas_background.dart';
import '../widgets/purchase_invoice_sheet.dart';
import 'login_screen.dart';
import 'signup_screen.dart';

class ProfileScreen extends StatefulWidget {
  final bool embedded;

  const ProfileScreen({super.key, this.embedded = false});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Pref.isLoggedIn) {
        Get.find<AuthController>().refreshCurrentUserFromBackend();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    return Obx(() {
      final currentUser = auth.currentUser.value ?? Pref.currentUser;
      if (currentUser == null) {
        return _buildNotLoggedInScaffold(context);
      }
      final subscriptionHistory = currentUser.subscriptionHistory;
      final currentActivePlan = currentUser.activePlan ??
          (subscriptionHistory.isNotEmpty ? subscriptionHistory.last.plan : null);
      final currentPlanLabel = currentActivePlan != null
          ? Subscription(plan: currentActivePlan, date: DateTime.now()).planLabel
          : null;

      // Effective expiry: from API only (do not infer from old purchase history).
      DateTime? effectiveExpiresAt = currentUser.subscriptionExpiresAt;
      final now = DateTime.now();
      final isExpired = currentActivePlan != null &&
          Pref.isSubscriptionExpired(currentUser, currentActivePlan);
      final int? daysLeft = effectiveExpiresAt != null && !isExpired
          ? effectiveExpiresAt.difference(now).inDays
          : null;

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
                  _buildAppBar(context, isLoggedIn: true),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 20),
                          _buildSectionTitle('Profile details'),
                          const SizedBox(height: 12),
                          _buildDetailCard(
                            Icons.person_rounded,
                            'Username',
                            currentUser.username,
                          ),
                          const SizedBox(height: 10),
                          _buildDetailCard(
                            Icons.email_rounded,
                            'Email',
                            currentUser.email,
                          ),
                          const SizedBox(height: 10),
                          if (currentUser.phone.trim().isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _buildDetailCard(
                                Icons.phone_rounded,
                                'Mobile',
                                currentUser.phone,
                              ),
                            ),
                          const SizedBox(height: 28),
                          _buildSectionTitle('Plan'),
                          const SizedBox(height: 12),
                          if (isExpired) ...[
                            _buildExpiredCard(context),
                            const SizedBox(height: 10),
                          ],
                          if (currentPlanLabel != null && !isExpired)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _buildDetailCard(
                                Icons.workspace_premium_rounded,
                                'Current plan',
                                daysLeft != null
                                    ? '$currentPlanLabel · $daysLeft days left'
                                    : currentPlanLabel,
                              ),
                            ),
                          if (currentPlanLabel == null && !isExpired)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _buildDetailCard(
                                Icons.info_outline_rounded,
                                'Current plan',
                                'No active plan',
                              ),
                            ),
                          if (!isExpired) _buildUpgradePlanCard(context),
                          if (isExpired) _buildRenewButton(context),
                          const SizedBox(height: 28),
                          _buildSectionTitle('Purchase history'),
                          const SizedBox(height: 12),
                          if (subscriptionHistory.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: NexusTheme.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: NexusTheme.border),
                              ),
                              child: Center(
                                child: Text(
                                  'No purchases yet.',
                                  style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    color: NexusTheme.text2,
                                  ),
                                ),
                              ),
                            )
                          else
                            ...subscriptionHistory.reversed.map((s) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _buildPurchaseHistoryTile(
                                  context,
                                  purchase: s,
                                  user: currentUser,
                                ),
                              );
                            }),
                          const SizedBox(height: 24),
                          _buildRestorePurchasesButton(),
                          const SizedBox(height: 10),
                          _buildPrivacyPolicyButton(),
                          const SizedBox(height: 10),
                          _buildLogoutButton(),
                          const SizedBox(height: 10),
                          _buildDeleteAccountButton(context, currentUser.email),
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
    });
  }

  Widget _buildNotLoggedInScaffold(BuildContext context) {
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
                _buildAppBar(context, isLoggedIn: false),
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.person_rounded,
                            size: 64,
                            color: NexusTheme.text3,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Not logged in',
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: NexusTheme.text2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Log in to see your profile and subscription history.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              color: NexusTheme.text3,
                            ),
                          ),
                          const SizedBox(height: 28),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: () => Get.to(() => const LoginScreen()),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: NexusTheme.teal,
                                foregroundColor: Colors.black87,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Text(
                                'Sign in',
                                style: GoogleFonts.outfit(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          GestureDetector(
                            onTap: () => Get.to(() => const SignupScreen()),
                            child: RichText(
                              text: TextSpan(
                                style: GoogleFonts.outfit(fontSize: 14, color: NexusTheme.text2),
                                children: [
                                  const TextSpan(text: "Don't have an account? "),
                                  TextSpan(
                                    text: 'Create account',
                                    style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.w700,
                                      color: NexusTheme.teal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildAppBar(BuildContext context, {required bool isLoggedIn}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
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
          Text(
            'Account',
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

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: GoogleFonts.jetBrainsMono(
        fontSize: 11,
        letterSpacing: 2,
        color: NexusTheme.text3,
      ),
    );
  }

  Widget _buildDetailCard(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: NexusTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: NexusTheme.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: NexusTheme.teal.withOpacity(0.15),
            ),
            child: Icon(icon, size: 20, color: NexusTheme.teal),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10,
                    letterSpacing: 1.5,
                    color: NexusTheme.text3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: NexusTheme.text,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpgradePlanCard(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => MainNavController.switchTo(MainTab.premium),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: NexusTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: NexusTheme.border),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              NexusTheme.teal.withOpacity(0.08),
              NexusTheme.gold.withOpacity(0.05),
            ],
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: NexusTheme.gold.withOpacity(0.2),
              ),
              child: const Icon(Icons.workspace_premium_rounded, size: 20, color: NexusTheme.gold),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Upgrade plan',
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: NexusTheme.text,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    AppConfig.profileUpgradeSubtitle,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: NexusTheme.text2,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 14, color: NexusTheme.text3),
          ],
        ),
      ),
    );
  }

  Widget _buildExpiredCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: NexusTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: NexusTheme.red.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: NexusTheme.red.withOpacity(0.15),
            ),
            child: const Icon(Icons.event_busy_rounded, size: 20, color: NexusTheme.red),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppConfig.profileExpiredTitle,
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: NexusTheme.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  AppConfig.profileExpiredSubtitle,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
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

  Widget _buildRenewButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: () => MainNavController.switchTo(MainTab.premium),
          style: ElevatedButton.styleFrom(
            backgroundColor: NexusTheme.teal,
            foregroundColor: Colors.black87,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Text(
            AppConfig.profileRenewButton,
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRestorePurchasesButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: () async {
          if (!Get.isRegistered<PaymentController>()) {
            Get.put(PaymentController());
          }
          await Get.find<PaymentController>().restorePurchases();
        },
        style: OutlinedButton.styleFrom(
          foregroundColor: NexusTheme.teal,
          side: BorderSide(color: NexusTheme.teal.withOpacity(0.5)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          'Restore purchases',
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildPrivacyPolicyButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: () async {
          final uri = Uri.parse(AppConfig.privacyPolicyUrl);
          if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
            Get.snackbar('Error', 'Could not open privacy policy');
          }
        },
        style: OutlinedButton.styleFrom(
          foregroundColor: NexusTheme.text2,
          side: BorderSide(color: NexusTheme.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          'Privacy policy',
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteAccountButton(BuildContext context, String email) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: () => _confirmDeleteAccount(context, email),
        style: OutlinedButton.styleFrom(
          foregroundColor: NexusTheme.red,
          side: BorderSide(color: NexusTheme.red.withOpacity(0.6)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          'Delete account',
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDeleteAccount(BuildContext context, String email) async {
    final passwordController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: NexusTheme.surface,
        title: Text(
          'Delete account?',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w700,
            color: NexusTheme.text,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This permanently deletes your account and subscription data for $email. This cannot be undone.',
              style: GoogleFonts.outfit(fontSize: 14, color: NexusTheme.text2),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              style: GoogleFonts.outfit(color: NexusTheme.text),
              decoration: InputDecoration(
                labelText: 'Password',
                labelStyle: GoogleFonts.outfit(color: NexusTheme.text3),
                filled: true,
                fillColor: NexusTheme.bg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: GoogleFonts.outfit(color: NexusTheme.text2)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Delete', style: GoogleFonts.outfit(color: NexusTheme.red, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) {
      passwordController.dispose();
      return;
    }
    final password = passwordController.text;
    passwordController.dispose();
    final ok = await Get.find<AuthController>().deleteAccount(password: password);
    if (ok && context.mounted) {
      Get.offAll(() => const LoginScreen());
    }
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: () {
          Get.find<AuthController>().logout();
          Get.offAll(() => const LoginScreen());
        },
        style: OutlinedButton.styleFrom(
          foregroundColor: NexusTheme.red,
          side: BorderSide(color: NexusTheme.red.withOpacity(0.6)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          'Logout',
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildPurchaseHistoryTile(
    BuildContext context, {
    required Subscription purchase,
    required User user,
  }) {
    final planLabel = purchase.planLabel;
    final amount = purchase.displayAmount;
    final d = purchase.date;
    final dateStr = '${d.day}/${d.month}/${d.year}';
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => PurchaseInvoiceSheet.show(
          context,
          purchase: purchase,
          user: user,
        ),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: NexusTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: NexusTheme.border),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: NexusTheme.gold.withOpacity(0.2),
                ),
                child: const Icon(Icons.receipt_long_rounded, size: 20, color: NexusTheme.gold),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      planLabel,
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: NexusTheme.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$amount · $dateStr',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 11,
                        color: NexusTheme.text2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Tap to view invoice',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: NexusTheme.teal,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, size: 20, color: NexusTheme.text3),
            ],
          ),
        ),
      ),
    );
  }
}
