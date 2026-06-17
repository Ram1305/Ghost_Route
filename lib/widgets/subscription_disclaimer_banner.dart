import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/nexus_theme.dart';

/// Informational banner for subscription-required disclosure (Guideline 2.3.2).
class SubscriptionDisclaimerBanner extends StatelessWidget {
  const SubscriptionDisclaimerBanner({
    super.key,
    required this.text,
    this.compact = false,
  });

  final String text;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 14,
        vertical: compact ? 6 : 8,
      ),
      decoration: BoxDecoration(
        color: NexusTheme.gold.withOpacity(0.08),
        border: Border.all(color: NexusTheme.gold.withOpacity(0.35)),
        borderRadius: BorderRadius.circular(compact ? 10 : 12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.lock_outline_rounded,
            size: compact ? 13 : 15,
            color: NexusTheme.gold,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.outfit(
                fontSize: compact ? 11 : 12,
                fontWeight: FontWeight.w600,
                color: NexusTheme.gold,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
