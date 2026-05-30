import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import '../models/subscription.dart';
import '../models/user.dart';
import '../models/vpn.dart';

class Pref {
  static late Box _box;

  /// Mock OTP for signup and forgot-password; replace with API later.
  static const String mockOtp = '123456';

  static Future<void> initializeHive() async {
    await Hive.initFlutter();
    _box = await Hive.openBox('data');
    _migrateSubscriptionHistoryToPerUser();
  }

  /// One-time: move global subscriptionHistory into first user if they have none.
  static void _migrateSubscriptionHistoryToPerUser() {
    final raw = _box.get('subscriptionHistory');
    if (raw == null) return;
    try {
      final data = jsonDecode(raw as String) as List;
      final legacy = data
          .map((e) => Subscription.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      if (legacy.isEmpty) return;
      final users = Pref.users;
      if (users.isEmpty) return;
      final first = users.first;
      if (first.subscriptionHistory.isNotEmpty) return;
      final updated = first.copyWith(subscriptionHistory: legacy);
      final updatedList = List<User>.from(users)..[0] = updated;
      Pref.users = updatedList;
      if (currentUser?.email == first.email) {
        Pref.currentUser = updated;
      }
    } catch (_) {}
    _box.delete('subscriptionHistory');
  }

  //for storing theme data
  static bool get isDarkMode => _box.get('isDarkMode') ?? false;
  static set isDarkMode(bool v) => _box.put('isDarkMode', v);

  //for storing single selected vpn details
  static Vpn get vpn => Vpn.fromJson(jsonDecode(_box.get('vpn') ?? '{}'));
  static set vpn(Vpn v) => _box.put('vpn', jsonEncode(v));

  //for storing vpn servers details
  static List<Vpn> get vpnList {
    List<Vpn> temp = [];
    final data = jsonDecode(_box.get('vpnList') ?? '[]');

    for (var i in data) temp.add(Vpn.fromJson(i));

    return temp;
  }

  static set vpnList(List<Vpn> v) => _box.put('vpnList', jsonEncode(v));

  // --- Auth & users ---
  static List<User> get users {
    final data = jsonDecode(_box.get('users') ?? '[]') as List;
    return data.map((e) => User.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  static set users(List<User> v) =>
      _box.put('users', jsonEncode(v.map((e) => e.toJson()).toList()));

  static User? get currentUser {
    final raw = _box.get('currentUser');
    if (raw == null) return null;
    return User.fromJson(Map<String, dynamic>.from(jsonDecode(raw as String) as Map));
  }

  static set currentUser(User? v) =>
      _box.put('currentUser', v == null ? null : jsonEncode(v.toJson()));

  static bool get isLoggedIn => currentUser != null;

  /// Current user's subscription history (per-user packs).
  static List<Subscription> get currentUserSubscriptionHistory =>
      currentUser?.subscriptionHistory ?? [];

  /// Current user's active plan; falls back to latest in history if not set.
  static PremiumPlan? get currentUserActivePlan {
    final u = currentUser;
    if (u == null) return null;
    if (u.activePlan != null) return u.activePlan;
    final history = u.subscriptionHistory;
    if (history.isEmpty) return null;
    return history.last.plan;
  }

  /// Last time OTP was "sent" (for mock cooldown); null if never sent.
  static DateTime? get lastOtpSentAt {
    final ms = _box.get('lastOtpSentAt') as int?;
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  static set lastOtpSentAt(DateTime? v) =>
      _box.put('lastOtpSentAt', v?.millisecondsSinceEpoch);
}
