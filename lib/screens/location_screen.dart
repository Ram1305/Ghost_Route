import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

import '../controllers/home_controller.dart';
import '../controllers/location_controller.dart';
import '../controllers/main_nav_controller.dart';
import '../config/app_config.dart';
import '../helpers/pref.dart';
import '../main.dart';
import '../models/vpn.dart';
import '../models/wireguard_server.dart';
import '../screens/premium_screen.dart';
import '../theme/nexus_theme.dart';
import '../widgets/desktop_content_bound.dart';
import '../widgets/subscription_disclaimer_banner.dart';
import '../widgets/vpn_card.dart';
import '../widgets/wireguard_server_card.dart';

class LocationScreen extends StatefulWidget {
  final bool embedded;

  const LocationScreen({super.key, this.embedded = false});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  @override
  void initState() {
    super.initState();
    final controller = Get.put(LocationController());
    controller.getVpnData();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<LocationController>();

    return DefaultTabController(
      length: 2,
      child: Obx(
        () => Scaffold(
          backgroundColor: NexusTheme.bg,
          appBar: AppBar(
            backgroundColor: NexusTheme.bg,
            foregroundColor: NexusTheme.text,
            elevation: 0,
            title: Text(
              'VPN Locations',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: NexusTheme.text,
              ),
            ),
            bottom: TabBar(
              indicatorColor: NexusTheme.teal,
              labelColor: NexusTheme.teal,
              unselectedLabelColor: NexusTheme.text2,
              labelStyle: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              tabs: [
                Tab(text: 'Free (${controller.freeVpnList.length})'),
                Tab(text: 'Premium (${controller.premiumWireguardList.length})'),
              ],
            ),
          ),
          floatingActionButton: Padding(
            padding: const EdgeInsets.only(bottom: 10, right: 10),
            child: FloatingActionButton(
              onPressed: () => controller.getVpnData(),
              backgroundColor: NexusTheme.teal.withValues(alpha: 0.15),
              foregroundColor: NexusTheme.teal,
              elevation: 0,
              child: const Icon(Icons.refresh_rounded),
            ),
          ),
          body: DesktopContentBound(
            maxWidth: 640,
            child: TabBarView(
              children: [
                _ServerTab(
                  isLoading: controller.isLoading.value,
                  servers: controller.freeVpnList,
                  disclaimer: !Pref.hasActiveSubscription
                      ? AppConfig.disclaimerBrowseServers
                      : null,
                ),
                _WireguardServerTab(
                  isLoading: controller.isLoading.value,
                  servers: controller.premiumWireguardList,
                  disclaimer: !Pref.hasActiveSubscription
                      ? AppConfig.disclaimerPlatinumBenefits
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ServerTab extends StatelessWidget {
  final bool isLoading;
  final List<Vpn> servers;
  final String? disclaimer;

  const _ServerTab({
    required this.isLoading,
    required this.servers,
    this.disclaimer,
  });

  @override
  Widget build(BuildContext context) {
    final home = Get.find<HomeController>();
    // OpenVPN (the "Free" tier's backend) has no Windows implementation;
    // WireGuard (Premium tab) is the only working VPN backend on Windows.
    final unavailableOnWindows = Platform.isWindows;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (unavailableOnWindows)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: SubscriptionDisclaimerBanner(
              text:
                  'Free OpenVPN servers aren\'t available on Windows yet — use a Premium (WireGuard) server instead.',
              accentColor: NexusTheme.text2,
            ),
          )
        else if (disclaimer != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: SubscriptionDisclaimerBanner(text: disclaimer!),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Opacity(
            opacity: unavailableOnWindows ? 0.5 : 1,
            child: Material(
            color: NexusTheme.surface,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: unavailableOnWindows
                  ? null
                  : () => home.connectToFastestFreeServer(),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: NexusTheme.border),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      NexusTheme.teal.withOpacity(0.10),
                      NexusTheme.surface.withOpacity(0.0),
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: NexusTheme.teal.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: NexusTheme.teal.withOpacity(0.25),
                        ),
                      ),
                      child: const Icon(
                        Icons.flash_on_rounded,
                        color: NexusTheme.teal,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Fastest Free Server',
                            style: GoogleFonts.outfit(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              color: NexusTheme.text,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Auto-selects the lowest latency location and connects',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 10.5,
                              color: NexusTheme.text2,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      color: NexusTheme.text2,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
          ),
          ),
        ),
        Expanded(
          child: isLoading && servers.isEmpty
              ? _loadingWidget()
              : servers.isEmpty
                  ? _noVPNFound()
                  : _vpnList(servers),
        ),
      ],
    );
  }

  Widget _vpnList(List<Vpn> list) {
    return ListView.builder(
      itemCount: list.length,
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.only(
        top: mq.height * .015,
        bottom: mq.height * .1,
        left: mq.width * .04,
        right: mq.width * .04,
      ),
      itemBuilder: (ctx, i) {
        final controller = Get.find<HomeController>();
        final vpn = list[i];
        return Opacity(
          opacity: Platform.isWindows ? 0.5 : 1,
          child: VpnCard(
            vpn: vpn,
            selected: controller.vpn.value.countryShort == vpn.countryShort &&
                controller.vpn.value.hostname == vpn.hostname,
          ),
        );
      },
    );
  }

  Widget _loadingWidget() => SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            LottieBuilder.asset(
              'assets/lottie/loading.json',
              width: mq.width * .7,
            ),
            const SizedBox(height: 16),
            Text(
              'Loading VPNs...',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: NexusTheme.text2,
              ),
            ),
          ],
        ),
      );

  Widget _noVPNFound() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 64,
              color: NexusTheme.text3,
            ),
            const SizedBox(height: 16),
            Text(
              'VPNs Not Found',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: NexusTheme.text2,
              ),
            ),
          ],
        ),
      );
}

class _WireguardServerTab extends StatelessWidget {
  final bool isLoading;
  final List<WireguardServer> servers;
  final String? disclaimer;

  const _WireguardServerTab({
    required this.isLoading,
    required this.servers,
    this.disclaimer,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (disclaimer != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: SubscriptionDisclaimerBanner(text: disclaimer!),
          ),
        Expanded(
          child: isLoading && servers.isEmpty
              ? const _LoadingServersWidget(label: 'Loading premium servers...')
              : servers.isEmpty
                  ? const _NoServersFoundWidget()
                  : _serverList(servers),
        ),
      ],
    );
  }

  Widget _serverList(List<WireguardServer> list) {
    return ListView.builder(
      itemCount: list.length,
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.only(
        top: mq.height * .015,
        bottom: mq.height * .1,
        left: mq.width * .04,
        right: mq.width * .04,
      ),
      itemBuilder: (ctx, i) {
        final server = list[i];
        return WireguardServerCard(
          server: server,
          onConnect: () {
            if (!Pref.hasActiveSubscription) {
              Get.to(() => const PremiumScreen());
              return;
            }
            final home = Get.find<HomeController>();
            MainNavController.switchTo(MainTab.home);
            if (Get.key.currentState?.canPop() ?? false) {
              Get.back();
            }
            // Disconnects whatever's active (any protocol) before connecting
            // to this server.
            home.switchToWireguardServer(server);
          },
        );
      },
    );
  }
}

class _LoadingServersWidget extends StatelessWidget {
  final String label;
  const _LoadingServersWidget({required this.label});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            LottieBuilder.asset(
              'assets/lottie/loading.json',
              width: mq.width * .7,
            ),
            const SizedBox(height: 16),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: NexusTheme.text2,
              ),
            ),
          ],
        ),
      );
}

class _NoServersFoundWidget extends StatelessWidget {
  const _NoServersFoundWidget();

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 64,
              color: NexusTheme.text3,
            ),
            const SizedBox(height: 16),
            Text(
              'Servers Not Found',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: NexusTheme.text2,
              ),
            ),
          ],
        ),
      );
}
