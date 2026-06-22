import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../screens/incognito_browser_screen.dart';
import '../theme/nexus_theme.dart';

/// Quick tools menu opened from the Home screen.
class ToolsBottomSheet extends StatelessWidget {
  const ToolsBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => const ToolsBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(
        color: NexusTheme.bg2,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: NexusTheme.border2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: NexusTheme.text3,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'TOOLS',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10,
                    letterSpacing: 2,
                    color: NexusTheme.text3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Quick actions',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: NexusTheme.text,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + bottom),
            child: _ToolRow(
              icon: Icons.visibility_off_rounded,
              iconColor: NexusTheme.teal,
              title: 'Incognito Browser',
              subtitle: 'Private session — nothing saved after you close',
              onTap: () {
                Navigator.of(context).pop();
                Get.to(() => const IncognitoBrowserScreen());
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ToolRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: iconColor.withOpacity(0.12),
                  border: Border.all(color: iconColor.withOpacity(0.25)),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: NexusTheme.text,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: NexusTheme.text2,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: NexusTheme.text3,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
