import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../controllers/settings_controller.dart';
import '../helpers/my_dialogs.dart';
import '../theme/nexus_theme.dart';
import '../widgets/canvas_background.dart';
import 'network_test_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _settings = Get.put(SettingsController());

  static final _ipv4 = RegExp(r'^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$');

  static bool _isValidIPv4(String v) {
    final m = _ipv4.firstMatch(v);
    if (m == null) return false;
    for (var i = 1; i <= 4; i++) {
      if (int.parse(m.group(i)!) > 255) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return Scaffold(
        backgroundColor: NexusTheme.bg,
        body: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: Opacity(
                opacity: 0.5,
                child: CanvasBackground(opacity: 0.5),
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
                          const SizedBox(height: 20),
                          _buildSectionTitle('Connection'),
                          const SizedBox(height: 12),
                          _buildProtocolCard(),
                          const SizedBox(height: 10),
                          _buildDnsCard(context),
                          const SizedBox(height: 10),
                          _buildComingSoonRow(
                            icon: Icons.shield_outlined,
                            title: 'Kill switch',
                            subtitle:
                                'Block all traffic if the VPN connection drops.',
                          ),
                          const SizedBox(height: 10),
                          _buildComingSoonRow(
                            icon: Icons.wifi_tethering_error_rounded,
                            title: 'Auto-connect on untrusted Wi-Fi',
                            subtitle:
                                'Connect automatically on unrecognized networks.',
                          ),
                          const SizedBox(height: 10),
                          _buildComingSoonRow(
                            icon: Icons.call_split_rounded,
                            title: 'Split tunneling',
                            subtitle:
                                'Choose which apps bypass the VPN (Android).',
                          ),
                          const SizedBox(height: 28),
                          _buildSectionTitle('Privacy & diagnostics'),
                          const SizedBox(height: 12),
                          _buildActionRow(
                            icon: Icons.network_check_rounded,
                            iconColor: NexusTheme.blue,
                            title: 'Network test',
                            subtitle:
                                'Check your current public IP and location.',
                            onTap: () => Get.to(() => const NetworkTestScreen()),
                          ),
                          const SizedBox(height: 10),
                          _buildActionRow(
                            icon: Icons.delete_sweep_rounded,
                            iconColor: NexusTheme.red,
                            title: 'Clear connection history',
                            subtitle: 'Remove all saved connection sessions.',
                            onTap: () => _confirmClearHistory(context),
                          ),
                          const SizedBox(height: 28),
                          _buildSectionTitle('Notifications'),
                          const SizedBox(height: 12),
                          _buildComingSoonRow(
                            icon: Icons.notifications_none_rounded,
                            title: 'Push notifications',
                            subtitle: 'Get alerted about your connection status.',
                          ),
                          const SizedBox(height: 28),
                          _buildSectionTitle('Appearance'),
                          const SizedBox(height: 12),
                          _buildAppearanceCard(),
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
            'Settings',
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

  Widget _iconBadge(IconData icon, Color color) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: color.withOpacity(0.15),
      ),
      child: Icon(icon, size: 20, color: color),
    );
  }

  Widget _buildProtocolCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: NexusTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: NexusTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Protocol',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 10,
              letterSpacing: 1.5,
              color: NexusTheme.text3,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _protocolOption('wireguard', 'WireGuard')),
              const SizedBox(width: 10),
              Expanded(child: _protocolOption('openvpn', 'OpenVPN')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _protocolOption(String value, String label) {
    final selected = _settings.protocol.value == value;
    return GestureDetector(
      onTap: () => _settings.setProtocol(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? NexusTheme.teal.withOpacity(0.15) : NexusTheme.bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? NexusTheme.teal : NexusTheme.border,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: selected ? NexusTheme.teal : NexusTheme.text2,
          ),
        ),
      ),
    );
  }

  Widget _buildDnsCard(BuildContext context) {
    final current = _settings.dnsServer.value;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _editDnsServer(context),
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
              _iconBadge(Icons.dns_rounded, NexusTheme.blue),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Custom DNS',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 10,
                        letterSpacing: 1.5,
                        color: NexusTheme.text3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      current.isEmpty ? 'Automatic' : current,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: NexusTheme.text,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: NexusTheme.text3),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _editDnsServer(BuildContext context) async {
    final controller = TextEditingController(text: _settings.dnsServer.value);
    String? error;
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: NexusTheme.surface2,
          title: Text(
            'Custom DNS server',
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
                "Leave blank to use the server's default DNS.",
                style: GoogleFonts.outfit(fontSize: 13, color: NexusTheme.text2),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                style: GoogleFonts.jetBrainsMono(color: NexusTheme.text),
                decoration: InputDecoration(
                  hintText: '1.1.1.1',
                  hintStyle: GoogleFonts.jetBrainsMono(color: NexusTheme.text3),
                  errorText: error,
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
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: GoogleFonts.outfit(color: NexusTheme.text2)),
            ),
            TextButton(
              onPressed: () {
                final value = controller.text.trim();
                if (value.isNotEmpty && !_isValidIPv4(value)) {
                  setDialogState(() => error = 'Enter a valid IPv4 address');
                  return;
                }
                Navigator.pop(ctx, value);
              },
              child: Text(
                'Save',
                style: GoogleFonts.outfit(
                  color: NexusTheme.teal,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
    if (result == null) return;
    _settings.setCustomDnsServer(result);
  }

  Widget _buildComingSoonRow({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: NexusTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: NexusTheme.border),
      ),
      child: Row(
        children: [
          _iconBadge(icon, NexusTheme.text3),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: NexusTheme.text,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: NexusTheme.gold.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'SOON',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 9,
                          letterSpacing: 1,
                          color: NexusTheme.gold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.outfit(fontSize: 12, color: NexusTheme.text3),
                ),
              ],
            ),
          ),
          Switch(value: false, onChanged: null),
        ],
      ),
    );
  }

  Widget _buildActionRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
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
              _iconBadge(icon, iconColor ?? NexusTheme.teal),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: NexusTheme.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.outfit(fontSize: 12, color: NexusTheme.text3),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: NexusTheme.text3),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmClearHistory(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: NexusTheme.surface2,
        title: Text(
          'Clear connection history?',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w700,
            color: NexusTheme.text,
          ),
        ),
        content: Text(
          'This removes all saved connection sessions from this device. This cannot be undone.',
          style: GoogleFonts.outfit(fontSize: 14, color: NexusTheme.text2),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: GoogleFonts.outfit(color: NexusTheme.text2)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Clear',
              style: GoogleFonts.outfit(color: NexusTheme.red, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      _settings.clearConnectionHistory();
      MyDialogs.success(msg: 'Connection history cleared');
    }
  }

  Widget _buildAppearanceCard() {
    final isDark = _settings.isDarkMode.value;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: NexusTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: NexusTheme.border),
      ),
      child: Row(
        children: [
          _iconBadge(
            isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
            NexusTheme.purple,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dark mode',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: NexusTheme.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isDark ? 'On' : 'Off',
                  style: GoogleFonts.outfit(fontSize: 12, color: NexusTheme.text3),
                ),
              ],
            ),
          ),
          Switch(
            value: isDark,
            activeThumbColor: NexusTheme.teal,
            onChanged: _settings.setDarkMode,
          ),
        ],
      ),
    );
  }
}
