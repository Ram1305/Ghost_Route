import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../apis/apis.dart';
import '../models/ip_details.dart';
import '../models/network_data.dart';
import '../theme/nexus_theme.dart';
import '../widgets/canvas_background.dart';
import '../widgets/desktop_content_bound.dart';
import '../widgets/network_card.dart';

class NetworkTestScreen extends StatefulWidget {
  const NetworkTestScreen({super.key});

  @override
  State<NetworkTestScreen> createState() => _NetworkTestScreenState();
}

class _NetworkTestScreenState extends State<NetworkTestScreen> {
  final ipData = IPDetails.fromJson({}).obs;
  final isLoading = true.obs;

  @override
  void initState() {
    super.initState();
    _loadIpDetails();
  }

  Future<void> _loadIpDetails() async {
    isLoading.value = true;
    ipData.value = IPDetails.fromJson({});
    await APIs.getIPDetails(ipData: ipData);
    isLoading.value = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NexusTheme.bg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.5,
              child: CanvasBackground(opacity: 0.5),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(),
                Expanded(
                  child: Obx(
                    () => DesktopContentBound(
                      child: ListView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 22),
                      children: [
                        const SizedBox(height: 20),
                        Text(
                          'Compare your public IP before and after connecting '
                          'to verify your VPN is actually active.',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            color: NexusTheme.text3,
                          ),
                        ),
                        const SizedBox(height: 16),
                        NetworkCard(
                          data: NetworkData(
                            title: 'IP Address',
                            subtitle: isLoading.value
                                ? 'Checking...'
                                : (ipData.value.query.isEmpty
                                    ? 'Not available'
                                    : ipData.value.query),
                            icon: Icon(
                              Icons.location_on_rounded,
                              color: NexusTheme.blue,
                            ),
                          ),
                        ),
                        NetworkCard(
                          data: NetworkData(
                            title: 'Internet Provider',
                            subtitle: isLoading.value
                                ? 'Checking...'
                                : (ipData.value.isp.isEmpty
                                    ? 'Unknown'
                                    : ipData.value.isp),
                            icon: Icon(
                              Icons.business_rounded,
                              color: NexusTheme.gold,
                            ),
                          ),
                        ),
                        NetworkCard(
                          data: NetworkData(
                            title: 'Location',
                            subtitle: isLoading.value
                                ? 'Checking...'
                                : (ipData.value.country.isEmpty
                                    ? 'Unknown'
                                    : '${ipData.value.city}, ${ipData.value.regionName}, ${ipData.value.country}'),
                            icon: Icon(
                              Icons.public_rounded,
                              color: NexusTheme.purple,
                            ),
                          ),
                        ),
                        NetworkCard(
                          data: NetworkData(
                            title: 'Timezone',
                            subtitle: isLoading.value
                                ? 'Checking...'
                                : (ipData.value.timezone.isEmpty
                                    ? 'Unknown'
                                    : ipData.value.timezone),
                            icon: Icon(
                              Icons.access_time_rounded,
                              color: NexusTheme.teal,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: OutlinedButton.icon(
                            onPressed: isLoading.value ? null : _loadIpDetails,
                            icon: const Icon(Icons.refresh_rounded),
                            label: Text(
                              'Run test again',
                              style: GoogleFonts.outfit(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: NexusTheme.teal,
                              side: BorderSide(color: NexusTheme.teal.withOpacity(0.6)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Get.back(),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            color: NexusTheme.text2,
          ),
          const Spacer(),
          Text(
            'Network Test',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: NexusTheme.text,
            ),
          ),
          const Spacer(),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}
