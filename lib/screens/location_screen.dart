import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

import '../controllers/home_controller.dart';
import '../controllers/location_controller.dart';
import '../main.dart';
import '../theme/nexus_theme.dart';
import '../widgets/vpn_card.dart';

class LocationScreen extends StatelessWidget {
  LocationScreen({super.key});

  final _controller = LocationController();

  @override
  Widget build(BuildContext context) {
    if (_controller.vpnList.isEmpty) _controller.getVpnData();

    return Obx(
      () => Scaffold(
        backgroundColor: NexusTheme.bg,
        appBar: AppBar(
          backgroundColor: NexusTheme.bg,
          foregroundColor: NexusTheme.text,
          elevation: 0,
          title: Text(
            'VPN Locations (${_controller.vpnList.length})',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: NexusTheme.text,
            ),
          ),
        ),
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 10, right: 10),
          child: FloatingActionButton(
            onPressed: () => _controller.getVpnData(),
            backgroundColor: NexusTheme.teal.withValues(alpha: 0.15),
            foregroundColor: NexusTheme.teal,
            elevation: 0,
            child: const Icon(Icons.refresh_rounded),
          ),
        ),
        body: _controller.isLoading.value
            ? _loadingWidget()
            : _controller.vpnList.isEmpty
                ? _noVPNFound()
                : _vpnData(),
      ),
    );
  }

  Widget _vpnData() => ListView.builder(
        itemCount: _controller.vpnList.length,
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.only(
          top: mq.height * .015,
          bottom: mq.height * .1,
          left: mq.width * .04,
          right: mq.width * .04,
        ),
        itemBuilder: (ctx, i) {
          final controller = Get.find<HomeController>();
          final vpn = _controller.vpnList[i];
          return VpnCard(
            vpn: vpn,
            selected:
                controller.vpn.value.countryShort == vpn.countryShort &&
                    controller.vpn.value.hostname == vpn.hostname,
          );
        },
      );

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
