import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/main_nav_controller.dart';
import '../theme/nexus_theme.dart';
import '../widgets/main_bottom_nav.dart';
import 'home_screen.dart';
import 'location_screen.dart';
import 'premium_screen.dart';
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
    return Obx(
      () => Scaffold(
        backgroundColor: NexusTheme.bg,
        body: IndexedStack(
          index: _nav.currentIndex.value,
          children: [
            HomeScreen(),
            const LocationScreen(embedded: true),
            const PremiumScreen(embedded: true),
            const ProfileScreen(embedded: true),
          ],
        ),
        bottomNavigationBar: MainBottomNav(
          currentIndex: _nav.currentIndex.value,
          onTabSelected: _nav.goToTab,
        ),
      ),
    );
  }
}
