import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/nexus_theme.dart';

class AppUpdateDialog extends StatelessWidget {
  final String title;
  final String message;
  final String currentVersion;
  final String latestVersion;
  final bool forceUpdate;
  final VoidCallback onUpdate;
  final VoidCallback? onLater;

  const AppUpdateDialog({
    super.key,
    required this.title,
    required this.message,
    required this.currentVersion,
    required this.latestVersion,
    required this.forceUpdate,
    required this.onUpdate,
    this.onLater,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String message,
    required String currentVersion,
    required String latestVersion,
    required bool forceUpdate,
    required VoidCallback onUpdate,
    VoidCallback? onLater,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: !forceUpdate,
      builder: (ctx) => AppUpdateDialog(
        title: title,
        message: message,
        currentVersion: currentVersion,
        latestVersion: latestVersion,
        forceUpdate: forceUpdate,
        onUpdate: onUpdate,
        onLater: onLater,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !forceUpdate,
      child: AlertDialog(
        backgroundColor: NexusTheme.bg2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: NexusTheme.border),
        ),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: NexusTheme.teal.withOpacity(0.15),
              ),
              child: const Icon(
                Icons.system_update_rounded,
                color: NexusTheme.teal,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: NexusTheme.text,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: GoogleFonts.outfit(
                fontSize: 14,
                height: 1.45,
                color: NexusTheme.text2,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: NexusTheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: NexusTheme.border),
              ),
              child: Text(
                'Installed $currentVersion  →  Latest $latestVersion',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 11,
                  color: NexusTheme.teal,
                ),
              ),
            ),
          ],
        ),
        actions: [
          if (!forceUpdate && onLater != null)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
                onLater!();
              },
              child: Text(
                'Later',
                style: GoogleFonts.outfit(color: NexusTheme.text2),
              ),
            ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop(true);
              onUpdate();
            },
            style: FilledButton.styleFrom(
              backgroundColor: NexusTheme.teal,
              foregroundColor: Colors.black87,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              forceUpdate ? 'Update now' : 'Update',
              style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
