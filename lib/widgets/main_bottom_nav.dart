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
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 10,
        bottom: MediaQuery.of(context).padding.bottom + 28,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, NexusTheme.bg],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Expanded(
            child: MainNavBtn(
              icon: Icons.shield_rounded,
              label: 'Shield',
              active: currentIndex == 0,
              onTap: () => onTabSelected(0),
            ),
          ),
          Expanded(
            child: MainNavBtn(
              icon: Icons.public_rounded,
              label: 'Servers',
              active: currentIndex == 1,
              onTap: () => onTabSelected(1),
            ),
          ),
          Expanded(
            child: MainNavBtn(
              icon: Icons.visibility_off_rounded,
              label: 'Browser',
              active: currentIndex == 2,
              onTap: () => onTabSelected(2),
            ),
          ),
          Expanded(
            child: MainNavBtn(
              icon: Icons.person_rounded,
              label: 'Account',
              active: currentIndex == 3,
              onTap: () => onTabSelected(3),
            ),
          ),
        ],
      ),
    );
  }
}

class MainNavBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const MainNavBtn({
    super.key,
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 22,
              color: active ? NexusTheme.teal : NexusTheme.text2.withOpacity(0.35),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 9,
                letterSpacing: 1.5,
                color: active ? NexusTheme.teal : NexusTheme.text2.withOpacity(0.35),
              ),
            ),
            if (active)
              Container(
                width: 4,
                height: 4,
                margin: const EdgeInsets.only(top: 4),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: NexusTheme.teal,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
