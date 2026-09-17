import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../apis/admin_api.dart';
import '../models/admin_stats.dart';
import '../models/subscription.dart';
import '../theme/nexus_theme.dart';
import '../widgets/canvas_background.dart';

/// Shows either every user or just active subscribers, depending on
/// [activeOnly] — used by the two tappable stat cards on AdminScreen.
class AdminUserListScreen extends StatefulWidget {
  final bool activeOnly;
  final String title;

  const AdminUserListScreen({
    super.key,
    required this.activeOnly,
    required this.title,
  });

  @override
  State<AdminUserListScreen> createState() => _AdminUserListScreenState();
}

class _AdminUserListScreenState extends State<AdminUserListScreen> {
  List<AdminUserSummary>? _users;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final users = await AdminApi.getUsers(activeOnly: widget.activeOnly);
      if (!mounted) return;
      setState(() {
        _users = users;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
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
                Expanded(child: _buildBody()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading && _users == null) {
      return Center(child: CircularProgressIndicator(color: NexusTheme.teal));
    }
    if (_error != null && _users == null) {
      return _buildErrorState();
    }
    final users = _users ?? [];
    if (users.isEmpty) {
      return Center(
        child: Text(
          'No users found.',
          style: GoogleFonts.outfit(fontSize: 14, color: NexusTheme.text2),
        ),
      );
    }
    return RefreshIndicator(
      color: NexusTheme.teal,
      onRefresh: _load,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 40),
        itemCount: users.length,
        itemBuilder: (context, i) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _buildUserRow(users[i]),
        ),
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
              _error ?? '',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(fontSize: 14, color: NexusTheme.text2),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: _load,
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
            widget.title,
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

  Widget _buildUserRow(AdminUserSummary user) {
    final planLabel = user.activePlan != null
        ? PremiumPlanX.fromStoredIndex(user.activePlan!).planLabel
        : 'No active plan';
    return Container(
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
              color: (user.isActiveSubscriber ? NexusTheme.teal : NexusTheme.text3)
                  .withOpacity(0.15),
            ),
            child: Icon(
              user.role == 'admin'
                  ? Icons.admin_panel_settings_rounded
                  : Icons.person_rounded,
              size: 20,
              color: user.isActiveSubscriber ? NexusTheme.teal : NexusTheme.text3,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.username.isNotEmpty ? user.username : user.email,
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
                  user.email,
                  style: GoogleFonts.outfit(fontSize: 12, color: NexusTheme.text3),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Text(
            planLabel,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 11,
              color: user.isActiveSubscriber ? NexusTheme.teal : NexusTheme.text3,
            ),
          ),
        ],
      ),
    );
  }
}
