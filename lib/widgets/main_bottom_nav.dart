import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/nexus_theme.dart';

class MainBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;

  const MainBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: NexusTheme.bg2,
        border: Border(
          top: BorderSide(color: NexusTheme.border.withValues(alpha: 0.8)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Theme(
          data: Theme.of(context).copyWith(
            useMaterial3: true,
            splashColor: NexusTheme.teal.withValues(alpha: 0.08),
            highlightColor: NexusTheme.teal.withValues(alpha: 0.04),
            navigationBarTheme: NavigationBarThemeData(
              height: 72,
              backgroundColor: NexusTheme.bg2,
              surfaceTintColor: Colors.transparent,
              shadowColor: Colors.transparent,
              elevation: 0,
              indicatorColor: NexusTheme.teal.withValues(alpha: 0.14),
              indicatorShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              labelTextStyle: WidgetStateProperty.resolveWith((states) {
                final selected = states.contains(WidgetState.selected);
                return GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: selected ? NexusTheme.teal : NexusTheme.text2,
                );
              }),
              iconTheme: WidgetStateProperty.resolveWith((states) {
                final selected = states.contains(WidgetState.selected);
                return IconThemeData(
                  size: 24,
                  color: selected
                      ? NexusTheme.teal
                      : NexusTheme.text2.withValues(alpha: 0.65),
                );
              }),
              overlayColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.pressed)) {
                  return NexusTheme.teal.withValues(alpha: 0.08);
                }
                return Colors.transparent;
              }),
            ),
          ),
          child: NavigationBar(
            selectedIndex: currentIndex,
            onDestinationSelected: onTabSelected,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            animationDuration: const Duration(milliseconds: 350),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.shield_outlined),
                selectedIcon: Icon(Icons.shield_rounded),
                label: 'Shield',
              ),
              NavigationDestination(
                icon: Icon(Icons.public_outlined),
                selectedIcon: Icon(Icons.public_rounded),
                label: 'Servers',
              ),
              NavigationDestination(
                icon: Icon(Icons.visibility_off_outlined),
                selectedIcon: Icon(Icons.visibility_off_rounded),
                label: 'Browser',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline_rounded),
                selectedIcon: Icon(Icons.person_rounded),
                label: 'Account',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
