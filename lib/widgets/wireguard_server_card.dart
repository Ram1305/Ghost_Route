import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/wireguard_server.dart';
import '../theme/nexus_theme.dart';

class WireguardServerCard extends StatelessWidget {
  final WireguardServer server;

  const WireguardServerCard({super.key, required this.server});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Material(
        color: NexusTheme.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => _showDetails(context),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: NexusTheme.border),
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
                  child: Icon(Icons.vpn_key_rounded, color: NexusTheme.teal, size: 22),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        server.serverName,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: NexusTheme.text,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${server.country}${server.city.isNotEmpty ? ' · ${server.city}' : ''}',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: NexusTheme.text2,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${server.host}:${server.port}',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: NexusTheme.text3,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Icon(Icons.chevron_right_rounded, color: NexusTheme.text3),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDetails(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: NexusTheme.bg2,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: NexusTheme.border2),
        ),
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 22),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: NexusTheme.text3.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                server.serverName,
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: NexusTheme.text,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${server.country}${server.city.isNotEmpty ? ' · ${server.city}' : ''}',
                style: GoogleFonts.outfit(fontSize: 13, color: NexusTheme.text2),
              ),
              const SizedBox(height: 14),
              _kv('Endpoint', '${server.host}:${server.port}'),
              _kv('Address', server.address),
              _kv('DNS', server.dns),
              _kv('Allowed IPs', server.allowedIPs),
              _kv('Persistent Keepalive', '${server.persistentKeepalive}s'),
              const SizedBox(height: 8),
              Text(
                'This list is display-only (WireGuard connect is not enabled in this app yet).',
                style: GoogleFonts.outfit(fontSize: 11, color: NexusTheme.text3, height: 1.3),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              k,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 11,
                color: NexusTheme.text3,
              ),
            ),
          ),
          Expanded(
            child: Text(
              v,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 11,
                color: NexusTheme.text2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

