import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../controllers/admin_controller.dart';
import '../models/admin_stats.dart';
import '../theme/nexus_theme.dart';
import '../widgets/canvas_background.dart';
import 'admin_notifications_screen.dart';
import 'admin_user_list_screen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final _admin = Get.put(AdminController());

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
                  child: Obx(() {
                    if (_admin.isLoading.value && _admin.stats.value == null) {
                      return Center(
                        child: CircularProgressIndicator(color: NexusTheme.teal),
                      );
                    }
                    if (_admin.error.value.isNotEmpty && _admin.stats.value == null) {
                      return _buildErrorState();
                    }
                    return RefreshIndicator(
                      color: NexusTheme.teal,
                      onRefresh: _admin.reload,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 22),
                        children: [
                          const SizedBox(height: 20),
                          _buildStatsRow(_admin.stats.value),
                          const SizedBox(height: 28),
                          _buildSectionTitle('Recent subscriptions'),
                          const SizedBox(height: 12),
                          if (_admin.recentSubscriptions.isEmpty)
                            _buildEmptyRecent()
                          else
                            ..._admin.recentSubscriptions.map(_buildSubscriptionRow),
                          const SizedBox(height: 40),
                        ],
                      ),
                    );
                  }),
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
            'Admin',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: NexusTheme.text,
            ),
          ),
          const Spacer(),
          Obx(() {
            final unread = _admin.stats.value?.unreadNotifications ?? 0;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  onPressed: () async {
                    await Get.to(() => const AdminNotificationsScreen());
                    _admin.reload();
                  },
                  icon: const Icon(Icons.notifications_none_rounded, size: 22),
                  color: NexusTheme.text2,
                ),
                if (unread > 0)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: NexusTheme.red,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      constraints: const BoxConstraints(minWidth: 16),
                      child: Text(
                        unread > 99 ? '99+' : '$unread',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          }),
          Obx(
            () => IconButton(
              onPressed: _admin.isLoading.value ? null : _admin.reload,
              icon: const Icon(Icons.refresh_rounded, size: 20),
              color: NexusTheme.text2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 40, color: NexusTheme.red),
            const SizedBox(height: 12),
            Text(
              _admin.error.value,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(fontSize: 14, color: NexusTheme.text2),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: _admin.reload,
              style: OutlinedButton.styleFrom(
                foregroundColor: NexusTheme.teal,
                side: BorderSide(color: NexusTheme.teal.withOpacity(0.6)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: GoogleFonts.jetBrainsMono(
        fontSize: 11,
        letterSpacing: 2,
        color: NexusTheme.text3,
      ),
    );
  }

  Widget _buildStatsRow(AdminStats? stats) {
    return Row(
      children: [
        Expanded(
          child: _statCard(
            icon: Icons.people_alt_rounded,
            color: NexusTheme.blue,
            label: 'Total users',
            value: stats?.totalUsers.toString() ?? '—',
            onTap: () => Get.to(
              () => const AdminUserListScreen(activeOnly: false, title: 'All users'),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statCard(
            icon: Icons.workspace_premium_rounded,
            color: NexusTheme.gold,
            label: 'Active subscribers',
            value: stats?.activeSubscribers.toString() ?? '—',
            onTap: () => Get.to(
              () => const AdminUserListScreen(activeOnly: true, title: 'Active subscribers'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _statCard({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: NexusTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: NexusTheme.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: color.withOpacity(0.15),
                    ),
                    child: Icon(icon, size: 18, color: color),
                  ),
                  Icon(Icons.chevron_right_rounded, size: 18, color: NexusTheme.text3),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: NexusTheme.text,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: GoogleFonts.outfit(fontSize: 12, color: NexusTheme.text3),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyRecent() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: NexusTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: NexusTheme.border),
      ),
      child: Center(
        child: Text(
          'No subscriptions yet.',
          style: GoogleFonts.outfit(fontSize: 14, color: NexusTheme.text2),
        ),
      ),
    );
  }

  Widget _buildSubscriptionRow(AdminSubscriptionEvent event) {
    final d = event.date;
    final dateStr = '${d.day}/${d.month}/${d.year}';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: NexusTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: NexusTheme.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: NexusTheme.teal.withOpacity(0.15),
            ),
            child: Icon(Icons.workspace_premium_rounded, size: 20, color: NexusTheme.teal),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.username.isNotEmpty ? event.username : event.email,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: NexusTheme.text,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${event.planName ?? 'Unknown plan'} · $dateStr',
                  style: GoogleFonts.outfit(fontSize: 12, color: NexusTheme.text3),
                ),
              ],
            ),
          ),
          if (event.amount != null)
            Text(
              '${event.amount} ${event.currency ?? ''}'.trim(),
              style: GoogleFonts.jetBrainsMono(fontSize: 12, color: NexusTheme.text2),
            ),
        ],
      ),
    );
  }
}
