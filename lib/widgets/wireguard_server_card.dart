import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/wireguard_server.dart';
import '../theme/nexus_theme.dart';

class WireguardServerCard extends StatelessWidget {
  final WireguardServer server;
  final VoidCallback onConnect;

  const WireguardServerCard({
    super.key,
    required this.server,
    required this.onConnect,
  });

  @override
  Widget build(BuildContext context) {
    final label = server.city.isNotEmpty ? '${server.country} · ${server.city}' : server.country;
    final endpoint = '${server.host}:${server.port}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onConnect,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  NexusTheme.surface2,
                  NexusTheme.surface.withOpacity(0.02),
                ],
              ),
              border: Border.all(color: NexusTheme.border2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: NexusTheme.glowTeal.withOpacity(0.18),
                    border: Border.all(color: NexusTheme.border2),
                  ),
                  child: Icon(Icons.workspace_premium_rounded,
                      color: NexusTheme.gold, size: 22),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        server.serverName,
                        style: GoogleFonts.outfit(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: NexusTheme.text,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        label,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: NexusTheme.text2,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        endpoint,
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: NexusTheme.surface2,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: NexusTheme.border),
                  ),
                  child: Text(
                    'SETUP',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: NexusTheme.teal,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

