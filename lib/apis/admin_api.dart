import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../helpers/pref.dart';
import '../models/admin_stats.dart';

/// Admin-only endpoints. Every call sends the bearer token from [Pref.authToken];
/// the backend independently re-verifies the caller's role from the database
/// on each request — this class does not itself enforce anything.
class AdminApi {
  static String get _base => AppConfig.apiBaseUrl;

  static Map<String, String> get _authHeaders => {
        'Content-Type': 'application/json',
        if (Pref.authToken != null) 'Authorization': 'Bearer ${Pref.authToken}',
      };

  static Future<AdminStats> getStats() async {
    final res = await http.get(
      Uri.parse('$_base/api/admin/stats'),
      headers: _authHeaders,
    );
    if (res.statusCode != 200) {
      final err = jsonDecode(res.body) as Map<String, dynamic>?;
      throw Exception(err?['error'] ?? 'Failed to load admin stats');
    }
    return AdminStats.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  static Future<List<AdminSubscriptionEvent>> getRecentSubscriptions({int limit = 20}) async {
    final res = await http.get(
      Uri.parse('$_base/api/admin/subscriptions/recent?limit=$limit'),
      headers: _authHeaders,
    );
    if (res.statusCode != 200) {
      final err = jsonDecode(res.body) as Map<String, dynamic>?;
      throw Exception(err?['error'] ?? 'Failed to load recent subscriptions');
    }
    final list = jsonDecode(res.body) as List<dynamic>;
    return list
        .map((e) => AdminSubscriptionEvent.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// [activeOnly] filters to users with a currently active subscription.
  static Future<List<AdminUserSummary>> getUsers({bool activeOnly = false}) async {
    final res = await http.get(
      Uri.parse('$_base/api/users/?activeOnly=$activeOnly'),
      headers: _authHeaders,
    );
    if (res.statusCode != 200) {
      final err = jsonDecode(res.body) as Map<String, dynamic>?;
      throw Exception(err?['error'] ?? 'Failed to load users');
    }
    final list = jsonDecode(res.body) as List<dynamic>;
    return list.map((e) => AdminUserSummary.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<List<AdminNotification>> getNotifications({int limit = 50}) async {
    final res = await http.get(
      Uri.parse('$_base/api/admin/notifications?limit=$limit'),
      headers: _authHeaders,
    );
    if (res.statusCode != 200) {
      final err = jsonDecode(res.body) as Map<String, dynamic>?;
      throw Exception(err?['error'] ?? 'Failed to load notifications');
    }
    final list = jsonDecode(res.body) as List<dynamic>;
    return list.map((e) => AdminNotification.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<void> markNotificationRead(String id) async {
    final res = await http.post(
      Uri.parse('$_base/api/admin/notifications/$id/read'),
      headers: _authHeaders,
    );
    if (res.statusCode != 200) {
      final err = jsonDecode(res.body) as Map<String, dynamic>?;
      throw Exception(err?['error'] ?? 'Failed to update notification');
    }
  }

  static Future<void> markAllNotificationsRead() async {
    final res = await http.post(
      Uri.parse('$_base/api/admin/notifications/read-all'),
      headers: _authHeaders,
    );
    if (res.statusCode != 200) {
      final err = jsonDecode(res.body) as Map<String, dynamic>?;
      throw Exception(err?['error'] ?? 'Failed to update notifications');
    }
  }
}
