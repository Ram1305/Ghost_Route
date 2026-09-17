import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../apis/admin_api.dart';
import '../models/admin_stats.dart';
import '../theme/nexus_theme.dart';
import '../widgets/canvas_background.dart';

class AdminNotificationsScreen extends StatefulWidget {
  const AdminNotificationsScreen({super.key});

  @override
  State<AdminNotificationsScreen> createState() => _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState extends State<AdminNotificationsScreen> {
  List<AdminNotification>? _notifications;
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
      final notifications = await AdminApi.getNotifications();
      if (!mounted) return;
      setState(() {
        _notifications = notifications;
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

  Future<void> _onTapNotification(AdminNotification n) async {
    if (n.read) return;
    final list = _notifications;
    if (list == null) return;
    final idx = list.indexWhere((e) => e.id == n.id);
    if (idx == -1) return;
    setState(() => list[idx] = n.copyWith(read: true));
    try {
      await AdminApi.markNotificationRead(n.id);
    } catch (_) {
      // Leave it marked read locally — a background retry isn't worth the
      // complexity here; next full reload will resync from the backend.
    }
  }

  Future<void> _markAllRead() async {
    final list = _notifications;
    if (list == null || list.every((n) => n.read)) return;
    setState(() {
      _notifications = list.map((n) => n.copyWith(read: true)).toList();
    });
    try {
      await AdminApi.markAllNotificationsRead();
    } catch (_) {}
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
    if (_loading && _notifications == null) {
      return Center(child: CircularProgressIndicator(color: NexusTheme.teal));
    }
    if (_error != null && _notifications == null) {
      return _buildErrorState();
    }
    final notifications = _notifications ?? [];
    if (notifications.isEmpty) {
      return Center(
        child: Text(
          'No notifications yet.',
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
        itemCount: notifications.length,
        itemBuilder: (context, i) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _buildNotificationRow(notifications[i]),
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
    final hasUnread = (_notifications ?? []).any((n) => !n.read);
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
            'Notifications',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: NexusTheme.text,
            ),
          ),
          const Spacer(),
          if (hasUnread)
            TextButton(
              onPressed: _markAllRead,
              child: Text(
                'Mark all read',
                style: GoogleFonts.outfit(fontSize: 12, color: NexusTheme.teal),
              ),
            )
          else
            const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildNotificationRow(AdminNotification n) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _onTapNotification(n),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: n.read ? NexusTheme.surface : NexusTheme.teal.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: n.read ? NexusTheme.border : NexusTheme.teal.withOpacity(0.4),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                      n.title,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: NexusTheme.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      n.body,
                      style: GoogleFonts.outfit(fontSize: 13, color: NexusTheme.text2),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _relativeTime(n.createdAt),
                      style: GoogleFonts.jetBrainsMono(fontSize: 10, color: NexusTheme.text3),
                    ),
                  ],
                ),
              ),
              if (!n.read)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: NexusTheme.teal,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _relativeTime(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.day}/${date.month}/${date.year}';
  }
}
