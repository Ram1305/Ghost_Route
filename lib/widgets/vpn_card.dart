import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../controllers/home_controller.dart';
import '../helpers/pref.dart';
import '../main.dart';
import '../models/vpn.dart';
import '../services/vpn_engine.dart';
import '../theme/nexus_theme.dart';

/// Tron VPN-style server card
class VpnCard extends StatelessWidget {
  final Vpn vpn;
  final bool selected;

  const VpnCard({
    super.key,
    required this.vpn,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();

    return Padding(
      padding: EdgeInsets.symmetric(vertical: mq.height * .01),
      child: Material(
        color: selected
            ? NexusTheme.teal.withValues(alpha: 0.04)
            : NexusTheme.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () {
            final isSameServer = selected;
            if (isSameServer) {
              debugPrint(
                  '[TronVPN] VpnCard: Same server already selected, going back');
              Get.back();
              return;
            }
            debugPrint(
                '[TronVPN] VpnCard: Selected ${vpn.countryLong} (${vpn.hostname}), saving and connecting');
            controller.vpn.value = vpn;
            Pref.vpn = vpn;
            Get.back();

            if (controller.vpnState.value == VpnEngine.vpnConnected) {
              debugPrint(
                  '[TronVPN] VpnCard: Was connected, stopping then will reconnect in 2s');
              VpnEngine.stopVpn();
              Future.delayed(
                  const Duration(seconds: 2), () => controller.connectToVpn());
            } else {
              controller.connectToVpn();
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(
                color: selected
                    ? NexusTheme.teal.withValues(alpha: 0.35)
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
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'assets/flags/${vpn.countryShort.toLowerCase()}.png',
                      height: 46,
                      width: 46,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vpn.countryLong,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: NexusTheme.text,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${vpn.ip}.xx · ${vpn.numVpnSessions} users',
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
                      '${vpn.ping}ms',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 12,
                        color: _pingColor(vpn.ping),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(
                        4,
                        (i) => Container(
                          width: 3,
                          height: 4 + i * 3.0,
                          margin: const EdgeInsets.only(left: 2),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(1.5),
                            color: i < _signalBars(vpn.ping)
                                ? NexusTheme.teal
                                : NexusTheme.text3,
                          ),
                        ),
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

  Color _pingColor(String ping) {
    final p = int.tryParse(ping) ?? 100;
    if (p < 50) return NexusTheme.teal;
    if (p < 100) return NexusTheme.gold;
    return NexusTheme.red;
  }

  int _signalBars(String ping) {
    final p = int.tryParse(ping) ?? 100;
    if (p < 30) return 4;
    if (p < 60) return 3;
    if (p < 100) return 2;
    return 1;
  }
}
