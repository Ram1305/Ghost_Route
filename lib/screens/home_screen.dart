import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../controllers/home_controller.dart';
import '../controllers/main_nav_controller.dart';
import '../config/app_config.dart';
import '../helpers/pref.dart';
import '../main.dart';
import '../models/vpn_status.dart';
import '../services/vpn_engine.dart';
import '../theme/nexus_theme.dart';
import '../widgets/canvas_background.dart';
import '../widgets/count_down_timer.dart';
import '../widgets/power_orb.dart';
import '../widgets/secured_overlay.dart';
import '../widgets/subscription_disclaimer_banner.dart';
import 'premium_screen.dart';

class HomeScreen extends StatelessWidget {
  HomeScreen({super.key});

  final _controller = Get.put(HomeController());

  @override
  Widget build(BuildContext context) {
    mq = MediaQuery.sizeOf(context);

    return Scaffold(
      backgroundColor: NexusTheme.bg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Canvas background
          Positioned.fill(
            child: Opacity(
              opacity: 0.6,
              child: const CanvasBackground(opacity: 0.6),
            ),
          ),
          // Content
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildFreeSessionBanner(context),
                  _buildHeader(context),
                  const SizedBox(height: 10),
                  _buildPowerSection(context),
                  const SizedBox(height: 24),
                  _buildIpStrip(context),
                  // const SizedBox(height: 22),
                  // _buildProtocolPills(),
                  const SizedBox(height: 22),
                  _buildServerSection(context),
                  const SizedBox(height: 22),
                  _buildStatsSection(context),
                  SizedBox(height: mq.height * 0.12),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
          // Secured overlay
          Obx(() {
            if (!_controller.showSecuredOverlay.value) return const SizedBox();
            return Positioned.fill(
              child: SecuredOverlay(
                visible: true,
                serverCode: _controller.vpn.value.countryShort.isNotEmpty
                    ? _controller.vpn.value.countryShort
                    : '—',
                ping: _controller.vpn.value.ping.isNotEmpty
                    ? '${_controller.vpn.value.ping}ms'
                    : '—',
                onDismiss: () => _controller.dismissSecuredOverlay(),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildFreeSessionBanner(BuildContext context) {
    if (Pref.hasActiveSubscription) {
      return const SizedBox.shrink();
    }

    return Obx(() {
      final connected =
          _controller.vpnState.value == VpnEngine.vpnConnected;
      final canStart = Pref.canStartFreeVpnSession;
      final remaining = connected
          ? _controller.freeSecondsRemaining.value
          : canStart
              ? Pref.freeSessionLimit.inSeconds
              : 0;

      if (!connected && !canStart) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 0),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: NexusTheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: NexusTheme.border),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.timer_off_outlined,
                  size: 18,
                  color: NexusTheme.text2,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Free session used today',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 11,
                      letterSpacing: 0.5,
                      color: NexusTheme.text2,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }

      return Padding(
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 0),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: NexusTheme.teal.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: NexusTheme.teal.withOpacity(0.35)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.timer_outlined,
                size: 18,
                color: NexusTheme.teal,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Free minutes left',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 11,
                    letterSpacing: 1,
                    color: NexusTheme.teal,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                formatSessionMmSs(remaining),
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: NexusTheme.text,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [NexusTheme.teal, NexusTheme.blue],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: NexusTheme.teal.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                    BoxShadow(
                      color: NexusTheme.blue.withOpacity(0.2),
                      blurRadius: 20,
                      spreadRadius: -2,
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(1),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.asset(
                    'assets/images/logo.png',
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.shield_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 9),
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.white, NexusTheme.teal],
                  stops: [0, 0.5],
                ).createShader(bounds),
                blendMode: BlendMode.srcIn,
                child: Text(
                  'Ghost Route',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          Row(
            children: [
              Obx(() {
                final on = _controller.vpnState.value == VpnEngine.vpnConnected;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: on
                          ? NexusTheme.teal.withOpacity(0.3)
                          : NexusTheme.border,
                    ),
                    color: on
                        ? NexusTheme.teal.withOpacity(0.08)
                        : NexusTheme.surface,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: on ? NexusTheme.teal : NexusTheme.text3,
                          boxShadow: on
                              ? [
                                  BoxShadow(
                                    color: NexusTheme.teal,
                                    blurRadius: 8,
                                  ),
                                ]
                              : null,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        on ? 'LIVE' : 'OFF',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 11,
                          letterSpacing: 0.5,
                          color: on ? NexusTheme.teal : NexusTheme.text2,
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () => Get.to(() => const PremiumScreen()),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        NexusTheme.gold.withOpacity(0.25),
                        NexusTheme.gold.withOpacity(0.1),
                      ],
                    ),
                    border: Border.all(
                      color: NexusTheme.gold.withOpacity(0.4),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: NexusTheme.gold.withOpacity(0.2),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text('★', style: TextStyle(fontSize: 15, color: NexusTheme.gold)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPowerSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Column(
        children: [
          Obx(() {
            final connected =
                _controller.vpnState.value == VpnEngine.vpnConnected;
            if (Pref.hasActiveSubscription) {
              return const SizedBox.shrink();
            }
            return SubscriptionDisclaimerBanner(
              text: connected
                  ? AppConfig.disclaimerActiveSubRequired
                  : AppConfig.disclaimerConnectRequired,
            );
          }),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: () {
              debugPrint('[TronVPN] Connect button (power orb) tapped');
              _controller.connectToVpn();
            },
            child: Obx(() {
              final connecting =
                  _controller.vpnState.value == VpnEngine.vpnConnecting;
              final connected =
                  _controller.vpnState.value == VpnEngine.vpnConnected;
              return PowerOrb(
                isConnected: connected,
                isConnecting: connecting,
                onTap: () {
                  debugPrint('[TronVPN] Connect button (power orb) tapped');
                  _controller.connectToVpn();
                },
              );
            }),
          ),
          const SizedBox(height: 20),
          Obx(() {
            final connected =
                _controller.vpnState.value == VpnEngine.vpnConnected;
            final hint = connected
                ? 'Connected via ${_controller.vpn.value.countryLong}'
                : Pref.hasActiveSubscription
                    ? AppConfig.connectHelperTextSubscribed
                    : AppConfig.connectHelperText;
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 13,
                  color: connected ? NexusTheme.teal : NexusTheme.text2,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    hint,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: connected ? NexusTheme.teal : NexusTheme.text2,
                    ),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildIpStrip(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Container(
        decoration: BoxDecoration(
          color: NexusTheme.surface,
          border: Border.all(color: NexusTheme.border),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Expanded(
              child: _IpCell(
                label: 'Your IP',
                value: '203.45.71.88', // Placeholder
              ),
            ),
            Container(
              width: 1,
              height: 40,
              color: NexusTheme.border,
            ),
            Expanded(
              child: Obx(() {
                final connected =
                    _controller.vpnState.value == VpnEngine.vpnConnected;
                return _IpCell(
                  label: 'VPN IP',
                  value: connected
                      ? '${_controller.vpn.value.ip}.xx'
                      : '—',
                  showDot: connected,
                );
              }),
            ),
            Container(
              width: 1,
              height: 40,
              color: NexusTheme.border,
            ),
            Expanded(
              child: Obx(() {
                final connected =
                    _controller.vpnState.value == VpnEngine.vpnConnected;
                return _IpCell(
                  label: 'Location',
                  value: connected
                      ? _controller.vpn.value.countryShort
                      : '—',
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProtocolPills() {
    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 22),
        children: ['WireGuard', 'OpenVPN', 'IKEv2']
            .asMap()
            .entries
            .map((e) => Padding(
                  padding: EdgeInsets.only(right: e.key < 2 ? 8 : 0),
                  child: _ProtocolPill(
                    label: e.value,
                    active: e.key == 0,
                    fastest: e.key == 0,
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildServerSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'SERVERS',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 10,
                  letterSpacing: 2,
                  color: NexusTheme.text3,
                ),
              ),
              GestureDetector(
                onTap: () => MainNavController.switchTo(MainTab.servers),
                child: Text(
                  'View All →',
                  style: TextStyle(
                    fontSize: 12,
                    color: NexusTheme.teal.withOpacity(0.7),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (!Pref.hasActiveSubscription)
            const SubscriptionDisclaimerBanner(
              text: AppConfig.disclaimerSubscribeToServers,
              compact: true,
            ),
          if (!Pref.hasActiveSubscription) const SizedBox(height: 13),
          if (Pref.hasActiveSubscription) const SizedBox(height: 13),
          GestureDetector(
            onTap: () => MainNavController.switchTo(MainTab.servers),
            child: _ServerCard(
              country: _controller.vpn.value.countryLong.isEmpty
                  ? 'Select Server'
                  : _controller.vpn.value.countryLong,
              flag: _controller.vpn.value.countryShort.isEmpty
                  ? '🌐'
                  : _controller.vpn.value.countryShort,
              meta: _controller.vpn.value.ip.isEmpty
                  ? 'Tap to choose'
                  : '${_controller.vpn.value.ip}.xx · ${_controller.vpn.value.numVpnSessions} users',
              ping: _controller.vpn.value.ping.isEmpty
                  ? '—'
                  : '${_controller.vpn.value.ping}ms',
              selected: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'LIVE STATS',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 10,
                  letterSpacing: 2,
                  color: NexusTheme.text3,
                ),
              ),
              Obx(() {
                if (_controller.vpnState.value != VpnEngine.vpnConnected ||
                    !Pref.hasActiveSubscription) {
                  return Text(
                    'Session: 00:00',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 10,
                      color: NexusTheme.text2,
                    ),
                  );
                }
                return DefaultTextStyle(
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10,
                    color: NexusTheme.text2,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Session: '),
                      CountDownTimer.elapsed(
                        running: _controller
                            .vpnState.value == VpnEngine.vpnConnected,
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 11),
          StreamBuilder<VpnStatus?>(
            initialData: VpnStatus(),
            stream: VpnEngine.vpnStatusSnapshot(),
            builder: (context, snapshot) {
              final byteIn = snapshot.data?.byteIn ?? '0 kbps';
              final byteOut = snapshot.data?.byteOut ?? '0 kbps';
              return Row(
                children: [
                  Expanded(
                    child: _StatTile(
                      icon: Icons.arrow_downward_rounded,
                      value: byteIn,
                      label: 'DOWNLOAD',
                      color: NexusTheme.blue,
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: _StatTile(
                      icon: Icons.arrow_upward_rounded,
                      value: byteOut,
                      label: 'UPLOAD',
                      color: NexusTheme.teal,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _IpCell extends StatelessWidget {
  final String label;
  final String value;
  final bool showDot;

  const _IpCell({
    required this.label,
    required this.value,
    this.showDot = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 9,
                letterSpacing: 1.5,
                color: NexusTheme.text3,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                if (showDot)
                  Container(
                    width: 5,
                    height: 5,
                    margin: const EdgeInsets.only(right: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: NexusTheme.teal,
                      boxShadow: [
                        BoxShadow(
                          color: NexusTheme.teal,
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: Text(
                    value,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 13,
                      color: NexusTheme.text,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
  }
}

class _ProtocolPill extends StatelessWidget {
  final String label;
  final bool active;
  final bool fastest;

  const _ProtocolPill({
    required this.label,
    this.active = false,
    this.fastest = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: active
              ? NexusTheme.teal.withOpacity(0.4)
              : NexusTheme.border,
        ),
        color: active
            ? NexusTheme.teal.withOpacity(0.1)
            : NexusTheme.surface,
        boxShadow: active
            ? [
                BoxShadow(
                  color: NexusTheme.teal.withOpacity(0.1),
                  blurRadius: 12,
                ),
              ]
            : null,
      ),
      child: Text(
        fastest ? '$label ⚡' : label,
        style: GoogleFonts.jetBrainsMono(
          fontSize: 11,
          letterSpacing: 0.5,
          color: active ? NexusTheme.teal : NexusTheme.text2,
        ),
      ),
    );
  }
}

class _ServerCard extends StatelessWidget {
  final String country;
  final String flag;
  final String meta;
  final String ping;
  final bool selected;

  const _ServerCard({
    required this.country,
    required this.flag,
    required this.meta,
    required this.ping,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: selected
            ? NexusTheme.teal.withOpacity(0.04)
            : NexusTheme.surface,
        border: Border.all(
          color: selected
              ? NexusTheme.teal.withOpacity(0.35)
              : NexusTheme.border,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: NexusTheme.surface2,
              border: Border.all(color: NexusTheme.border),
            ),
            child: Center(
              child: Text(flag, style: const TextStyle(fontSize: 23)),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  country,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: NexusTheme.text,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  meta,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10,
                    color: NexusTheme.text2,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                ping,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 12,
                  color: NexusTheme.teal,
                ),
              ),
              Row(
                children: List.generate(
                  4,
                  (i) => Container(
                    width: 3,
                    height: 4 + i * 3.0,
                    margin: const EdgeInsets.only(left: 2),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(1.5),
                      color: i < 3 ? NexusTheme.teal : NexusTheme.text3,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatTile({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: NexusTheme.surface,
        border: Border.all(color: NexusTheme.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: color.withOpacity(0.1),
            ),
            child: Icon(icon, size: 15, color: color),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: NexusTheme.text,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 10,
              letterSpacing: 1.5,
              color: NexusTheme.text3,
            ),
          ),
        ],
      ),
    );
  }
}
