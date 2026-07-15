import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../controllers/home_controller.dart';
import '../helpers/connection_history.dart';
import '../helpers/country_flag.dart';
import '../models/vpn_connection_session.dart';
import '../services/vpn_engine.dart';
import '../theme/nexus_theme.dart';

class ConnectionHistorySection extends StatelessWidget {
  const ConnectionHistorySection({super.key, required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Touch reactive fields so this rebuilds on connect/disconnect/ticks.
      controller.connectionHistoryRevision.value;
      controller.vpnState.value;
      controller.activeSessionElapsedSeconds.value;
      final sessions = controller.connectionHistory.toList();
      final isConnected =
          controller.vpnState.value == VpnEngine.vpnConnected;
      final activeCountry = controller.activeSessionCountry.value.trim();
      final activeStart = controller.activeSessionStartedAt.value;
      final showActive = isConnected &&
          activeStart != null &&
          activeCountry.isNotEmpty;

      final grouped = groupSessionsByDay(sessions);
      final hasAny = showActive || grouped.isNotEmpty;

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'CONNECTION HISTORY',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 10,
                letterSpacing: 2,
                color: NexusTheme.text3,
              ),
            ),
            const SizedBox(height: 11),
            if (!hasAny)
              const _EmptyHistoryCard()
            else ...[
              if (showActive || grouped.containsKey('Today'))
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _DayGroup(
                    label: 'Today',
                    sessions: grouped['Today'] ?? const [],
                    leadingRows: showActive
                        ? [
                            _HistoryRow(
                              country: activeCountry,
                              durationLabel: formatDurationCompact(
                                Duration(
                                  seconds: controller
                                      .activeSessionElapsedSeconds.value,
                                ),
                              ),
                              trailingLabel: 'Active',
                              accent: true,
                            ),
                          ]
                        : const [],
                  ),
                ),
              ...grouped.entries
                  .where((entry) => entry.key != 'Today')
                  .map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child:
                          _DayGroup(label: entry.key, sessions: entry.value),
                    ),
                  ),
            ],
          ],
        ),
      );
    });
  }
}

class _EmptyHistoryCard extends StatelessWidget {
  const _EmptyHistoryCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: NexusTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: NexusTheme.border),
      ),
      child: Text(
        'No sessions yet — connect to start building history.',
        style: GoogleFonts.jetBrainsMono(
          fontSize: 11,
          color: NexusTheme.text2,
          height: 1.4,
        ),
      ),
    );
  }
}

class _DayGroup extends StatelessWidget {
  const _DayGroup({
    required this.label,
    required this.sessions,
    this.leadingRows = const [],
  });

  final String label;
  final List<VpnConnectionSession> sessions;
  final List<Widget> leadingRows;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[
      ...leadingRows,
      for (final session in sessions)
        _HistoryRow(
          country: session.country,
          durationLabel: formatDurationCompact(session.duration),
        ),
    ];

    if (rows.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: NexusTheme.text2,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: NexusTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: NexusTheme.border),
          ),
          child: Column(
            children: [
              for (var i = 0; i < rows.length; i++) ...[
                if (i > 0)
                  const Divider(
                    height: 1,
                    thickness: 1,
                    color: NexusTheme.border,
                  ),
                rows[i],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({
    required this.country,
    required this.durationLabel,
    this.trailingLabel,
    this.accent = false,
  });

  final String country;
  final String durationLabel;
  final String? trailingLabel;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          Text(
            flagEmojiForCountryName(country),
            style: const TextStyle(fontSize: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  country,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 13,
                    color: accent ? NexusTheme.teal : NexusTheme.text,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (trailingLabel != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    trailingLabel!,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 9,
                      letterSpacing: 1,
                      color: NexusTheme.teal,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Text(
            durationLabel,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 11,
              color: accent ? NexusTheme.teal : NexusTheme.text2,
            ),
          ),
        ],
      ),
    );
  }
}
