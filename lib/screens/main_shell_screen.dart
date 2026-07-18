import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/main_nav_controller.dart';
import '../theme/nexus_theme.dart';
import '../widgets/main_bottom_nav.dart';
import '../widgets/main_nav_rail.dart';
import 'home_screen.dart';
import 'location_screen.dart';
import 'incognito_browser_screen.dart';
import 'profile_screen.dart';

class MainShellScreen extends StatefulWidget {
  final int initialIndex;

  const MainShellScreen({super.key, this.initialIndex = MainTab.home});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  late final MainNavController _nav;

  @override
  void initState() {
    super.initState();
    _nav = Get.put(MainNavController());
    if (widget.initialIndex != MainTab.home) {
      _nav.goToTab(widget.initialIndex);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Windows is a resizable desktop window, not a phone: a bottom tab bar
    // wastes horizontal space and reads as a mobile pattern. Use a side rail
    // instead. Android/iOS keep MainBottomNav untouched.
    final useSideRail = Platform.isWindows;

    return Obx(() {
      final content = IndexedStack(
        index: _nav.currentIndex.value,
        children: [
          HomeScreen(),
          const LocationScreen(embedded: true),
          const IncognitoBrowserScreen(embedded: true),
          const ProfileScreen(embedded: true),
        ],
      );

      if (useSideRail) {
        return Scaffold(
          backgroundColor: NexusTheme.bg,
          body: Row(
            children: [
              MainNavRail(
                currentIndex: _nav.currentIndex.value,
                onTabSelected: _nav.goToTab,
              ),
              Expanded(child: content),
            ],
          ),
        );
      }

      return Scaffold(
        backgroundColor: NexusTheme.bg,
        body: content,
        bottomNavigationBar: MainBottomNav(
          currentIndex: _nav.currentIndex.value,
          onTabSelected: _nav.goToTab,
        ),
      );
    });
  }
}
