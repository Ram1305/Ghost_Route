import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../main.dart';
import '../theme/nexus_theme.dart';

/// Tron VPN-style card for status display
class HomeCard extends StatelessWidget {
  final String title, subtitle;
  final Widget icon;

  const HomeCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: mq.width * .45,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: NexusTheme.surface,
          border: Border.all(color: NexusTheme.border),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            icon,
            const SizedBox(height: 6),
            Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: NexusTheme.text,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 10,
                letterSpacing: 1.5,
                color: NexusTheme.text2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
