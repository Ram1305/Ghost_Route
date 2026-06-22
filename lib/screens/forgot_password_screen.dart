import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../controllers/auth_controller.dart';
import '../helpers/auth_navigation.dart';
import '../theme/nexus_theme.dart';
import '../widgets/canvas_background.dart';
import 'login_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _email = TextEditingController();
  final _otp = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();
  final _auth = Get.find<AuthController>();

  bool _otpSent = false;
  bool _otpVerified = false;
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _otp.dispose();
    _newPassword.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final ok = await _auth.sendOtp(_email.text, 'forgot_password');
    if (ok) setState(() => _otpSent = true);
  }

  Future<void> _verifyOtp() async {
    final ok = await _auth.verifyOtp(_email.text, _otp.text, 'forgot_password');
    if (ok) setState(() => _otpVerified = true);
  }

  Future<void> _changePassword() async {
    if (_loading) return;
    setState(() => _loading = true);
    final ok = await _auth.resetPassword(
      email: _email.text,
      otp: _otp.text,
      newPassword: _newPassword.text,
      confirmPassword: _confirmPassword.text,
    );
    setState(() => _loading = false);
    if (ok) {
      Get.off(() => const LoginScreen());
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
                        const SizedBox(height: 24),
                        Text(
                          'Forgot password',
                          style: GoogleFonts.outfit(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: NexusTheme.text,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Enter your email, verify OTP, then set a new password.',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            color: NexusTheme.text2,
                          ),
                        ),
                        const SizedBox(height: 28),
                        _buildTextField(
                          controller: _email,
                          label: 'Email',
                          hint: 'Enter email',
                          icon: Icons.email_rounded,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: TextButton(
                            onPressed: _otpSent ? null : _sendOtp,
                            style: TextButton.styleFrom(
                              backgroundColor: NexusTheme.teal.withOpacity(0.2),
                              foregroundColor: NexusTheme.teal,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              _otpSent ? 'OTP sent' : 'Send OTP',
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        if (_otpSent) ...[
                          const SizedBox(height: 18),
                          _buildTextField(
                            controller: _otp,
                            label: 'OTP',
                            hint: 'Enter 6-digit OTP',
                            icon: Icons.pin_rounded,
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: TextButton(
                              onPressed: _otpVerified ? null : _verifyOtp,
                              style: TextButton.styleFrom(
                                backgroundColor: _otpVerified
                                    ? NexusTheme.teal.withOpacity(0.3)
                                    : NexusTheme.teal.withOpacity(0.2),
                                foregroundColor: NexusTheme.teal,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                _otpVerified ? 'Verified' : 'Verify OTP',
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                        if (_otpVerified) ...[
                          const SizedBox(height: 20),
                          _buildTextField(
                            controller: _newPassword,
                            label: 'New password',
                            hint: 'Enter new password',
                            icon: Icons.lock_rounded,
                            obscureText: true,
                          ),
                          const SizedBox(height: 14),
                          _buildTextField(
                            controller: _confirmPassword,
                            label: 'Confirm password',
                            hint: 'Confirm new password',
                            icon: Icons.lock_rounded,
                            obscureText: true,
                          ),
                          const SizedBox(height: 24),
                          _buildChangePasswordButton(),
                        ],
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
            onPressed: popAuthScreenOrGoHome,
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            color: NexusTheme.text2,
          ),
          const Spacer(),
          Text(
            'Forgot password',
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 11,
            letterSpacing: 1.5,
            color: NexusTheme.text3,
          ),
        ),
        const SizedBox(height: 6),
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

  Widget _buildChangePasswordButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _loading ? null : _changePassword,
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
                    'Change password',
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
}
