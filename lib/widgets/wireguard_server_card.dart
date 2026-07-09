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

  String _maskLast2Digits(String input) {
    int digits = 0;
    final chars = input.split('');
    for (int i = chars.length - 1; i >= 0; i--) {
      final c = chars[i];
      final isDigit = c.codeUnitAt(0) >= 48 && c.codeUnitAt(0) <= 57;
      if (!isDigit) continue;
      digits++;
      if (digits <= 2) {
        chars[i] = 'X';
      } else {
        break;
      }
    }
    return chars.join();
  }

  String _flagForCountry(String country) {
    final c = country.trim().toLowerCase();
    if (c.isEmpty) return '🌐';
    if (c.contains('united states') || c == 'usa' || c.contains('america')) {
      return '🇺🇸';
    }
    if (c.contains('singapore')) return '🇸🇬';
    if (c.contains('india')) return '🇮🇳';
    if (c.contains('japan')) return '🇯🇵';
    return '🌐';
  }

  String? _flagAssetForCountry(String country) {
    final c = country.trim().toLowerCase();
    if (c.contains('united states') || c == 'usa' || c.contains('america')) {
      return 'us';
    }
    if (c.contains('singapore')) return 'sg';
    if (c.contains('india')) return 'in';
    if (c.contains('japan')) return 'jp';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final country = server.country.trim().isEmpty ? '—' : server.country.trim();
    final city = server.city.trim().isEmpty ? '—' : server.city.trim();
    final rawHost = server.host.trim().isEmpty ? '—' : server.host.trim();
    final hostOnly = _maskLast2Digits(rawHost);
    final host = server.port > 0 ? '$hostOnly:XXXXX' : hostOnly;
    final flag = _flagForCountry(country);
    final flagAsset = _flagAssetForCountry(country);
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
                    color: NexusTheme.surface2,
                    border: Border.all(color: NexusTheme.border),
                    boxShadow: [
                      BoxShadow(
                        color: NexusTheme.teal.withOpacity(0.25),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: flagAsset == null
                        ? Center(
                            child: Text(
                              flag,
                              style: const TextStyle(fontSize: 22, height: 1),
                            ),
                          )
                        : Image.asset(
                            'assets/flags/$flagAsset.png',
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
                        country,
                        style: GoogleFonts.outfit(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: NexusTheme.text,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        city,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: NexusTheme.text2,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        host,
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '10ms',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 12,
                        color: NexusTheme.teal,
                        fontWeight: FontWeight.w700,
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
                            color: NexusTheme.teal,
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
}

