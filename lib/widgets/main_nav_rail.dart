import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/nexus_theme.dart';

/// Desktop (Windows) equivalent of [MainBottomNav] — a side rail instead of
/// a bottom bar, since a bottom tab bar reads as a mobile pattern on a wide
/// resizable window.
class MainNavRail extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;

  const MainNavRail({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
  });

  static const _destinations = [
    (
      icon: Icons.shield_outlined,
      selectedIcon: Icons.shield_rounded,
      label: 'Shield',
    ),
    (
      icon: Icons.public_outlined,
      selectedIcon: Icons.public_rounded,
      label: 'Servers',
    ),
    (
      icon: Icons.visibility_off_outlined,
      selectedIcon: Icons.visibility_off_rounded,
      label: 'Browser',
    ),
    (
      icon: Icons.person_outline_rounded,
      selectedIcon: Icons.person_rounded,
      label: 'Account',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: NexusTheme.bg2,
        border: Border(
          right: BorderSide(color: NexusTheme.border.withValues(alpha: 0.8)),
        ),
      ),
      child: SafeArea(
        right: false,
        child: SizedBox(
          width: 88,
          child: Column(
            children: [
              const SizedBox(height: 24),
              for (var i = 0; i < _destinations.length; i++)
                _RailItem(
                  icon: _destinations[i].icon,
                  selectedIcon: _destinations[i].selectedIcon,
                  label: _destinations[i].label,
                  selected: currentIndex == i,
                  onTap: () => onTabSelected(i),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RailItem extends StatelessWidget {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _RailItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: selected
                  ? NexusTheme.teal.withValues(alpha: 0.14)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  selected ? selectedIcon : icon,
                  size: 24,
                  color: selected
                      ? NexusTheme.teal
                      : NexusTheme.text2.withValues(alpha: 0.65),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    color: selected ? NexusTheme.teal : NexusTheme.text2,
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
