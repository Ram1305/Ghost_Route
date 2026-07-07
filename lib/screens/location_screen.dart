import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

import '../controllers/home_controller.dart';
import '../controllers/location_controller.dart';
import '../config/app_config.dart';
import '../helpers/pref.dart';
import '../main.dart';
import '../models/vpn.dart';
import '../theme/nexus_theme.dart';
import '../widgets/subscription_disclaimer_banner.dart';
import '../widgets/vpn_card.dart';

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
                Tab(text: 'Premium (${controller.premiumVpnList.length})'),
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
          body: TabBarView(
            children: [
              _ServerTab(
                isLoading: controller.isLoading.value,
                servers: controller.freeVpnList,
                disclaimer: !Pref.hasActiveSubscription
                    ? AppConfig.disclaimerBrowseServers
                    : null,
              ),
              _ServerTab(
                isLoading: controller.isLoading.value,
                servers: controller.premiumVpnList,
                disclaimer: !Pref.hasActiveSubscription
                    ? AppConfig.disclaimerPlatinumBenefits
                    : null,
              ),
            ],
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
        return VpnCard(
          vpn: vpn,
          selected: controller.vpn.value.countryShort == vpn.countryShort &&
              controller.vpn.value.hostname == vpn.hostname,
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
