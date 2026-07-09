import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import 'free_vpn_session.dart';
import 'subscription_expiry.dart';
import '../models/subscription.dart';
import '../models/user.dart';
import '../models/vpn.dart';
import '../models/wireguard_server.dart';

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

  // for storing single selected wireguard server details
  static WireguardServer get wireguardServer =>
      WireguardServer.fromJson(jsonDecode(_box.get('wireguardServer') ?? '{}'));
  static set wireguardServer(WireguardServer v) =>
      _box.put('wireguardServer', jsonEncode(v));

  /// Selected protocol: 'openvpn' (default) or 'wireguard'.
  static String get selectedProtocol => _box.get('selectedProtocol') ?? 'openvpn';
  static set selectedProtocol(String v) => _box.put('selectedProtocol', v);

  //for storing vpn servers details
  static List<Vpn> _readVpnList(String key) {
    final data = jsonDecode(_box.get(key) ?? '[]');
    return [for (final i in data) Vpn.fromJson(i)];
  }

  static void _writeVpnList(String key, List<Vpn> v) =>
      _box.put(key, jsonEncode(v.map((e) => e.toJson()).toList()));

  static List<Vpn> get vpnListFree => _readVpnList('vpnListFree');
  static set vpnListFree(List<Vpn> v) => _writeVpnList('vpnListFree', v);

  static List<Vpn> get vpnListPremium => _readVpnList('vpnListPremium');
  static set vpnListPremium(List<Vpn> v) => _writeVpnList('vpnListPremium', v);

  static List<WireguardServer> _readWireguardList(String key) {
    final data = jsonDecode(_box.get(key) ?? '[]');
    return [for (final i in data) WireguardServer.fromJson(i)];
  }

  static void _writeWireguardList(String key, List<WireguardServer> v) =>
      _box.put(key, jsonEncode(v.map((e) => e.toJson()).toList()));

  static List<WireguardServer> get vpnListPremiumWireguard =>
      _readWireguardList('vpnListPremiumWireguard');
  static set vpnListPremiumWireguard(List<WireguardServer> v) =>
      _writeWireguardList('vpnListPremiumWireguard', v);

  /// Alias for free server list (backward compatibility).
  static List<Vpn> get vpnList {
    final free = vpnListFree;
    if (free.isNotEmpty) return free;
    return _readVpnList('vpnList');
  }

  static set vpnList(List<Vpn> v) {
    vpnListFree = v;
    _writeVpnList('vpnList', v);
  }

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

  // --- Guest subscription (purchased without a backend account) ---

  static int? get guestActivePlanIndex => _box.get('guestActivePlanIndex') as int?;
  static set guestActivePlanIndex(int? v) =>
      v == null ? _box.delete('guestActivePlanIndex') : _box.put('guestActivePlanIndex', v);

  static DateTime? get guestSubscriptionExpiresAt {
    final ms = _box.get('guestSubExpiresAt') as int?;
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  static set guestSubscriptionExpiresAt(DateTime? v) =>
      v == null ? _box.delete('guestSubExpiresAt') : _box.put('guestSubExpiresAt', v?.millisecondsSinceEpoch);

  /// Active plan for a guest (no backend account). Returns null if expired or not set.
  static PremiumPlan? get guestActivePlan {
    final idx = guestActivePlanIndex;
    if (idx == null) return null;
    final expiry = guestSubscriptionExpiresAt;
    if (expiry != null && isSubscriptionDateExpired(expiry)) return null;
    return PremiumPlanX.fromStoredIndex(idx);
  }

  /// Whether the user (logged-in or guest) has a non-expired subscription.
  static bool get hasActiveSubscription => activeSubscriptionPlan != null;

  /// Active plan for connect gate — guest first, then logged-in user.
  static PremiumPlan? get activeSubscriptionPlan {
    final guest = guestActivePlan;
    if (guest != null) return guest;

    final u = currentUser;
    if (u == null) return null;

    final plan = currentUserActivePlan;
    if (plan == null) return null;
    if (isSubscriptionExpired(u, plan)) return null;
    return plan;
  }

  // --- Free VPN daily session (non-subscribers) ---

  static const Duration freeSessionLimit = FreeVpnSession.limit;

  static String? get freeVpnSessionDate => _box.get('freeVpnSessionDate') as String?;

  static set freeVpnSessionDate(String? v) =>
      v == null ? _box.delete('freeVpnSessionDate') : _box.put('freeVpnSessionDate', v);

  static DateTime? get freeVpnSessionStartedAt {
    final ms = _box.get('freeVpnSessionStartedAt') as int?;
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  static set freeVpnSessionStartedAt(DateTime? v) => v == null
      ? _box.delete('freeVpnSessionStartedAt')
      : _box.put('freeVpnSessionStartedAt', v.millisecondsSinceEpoch);

  static bool get hasUsedFreeVpnSessionToday =>
      FreeVpnSession.hasUsedSessionToday(freeVpnSessionDate);

  static bool get canStartFreeVpnSession =>
      FreeVpnSession.canStartSession(freeVpnSessionDate);

  static Duration get freeSessionRemaining =>
      FreeVpnSession.remainingFromStart(freeVpnSessionStartedAt);

  static int get freeSessionRemainingSeconds =>
      FreeVpnSession.remainingSecondsFromStart(freeVpnSessionStartedAt);

  static void markFreeVpnSessionUsed() {
    final now = DateTime.now();
    freeVpnSessionDate = FreeVpnSession.localDateKey(now);
    freeVpnSessionStartedAt = now;
  }

  /// Apply server state after reinstall or cross-device sync.
  static void applyRemoteFreeSession({
    required String sessionDate,
    DateTime? startedAt,
  }) {
    freeVpnSessionDate = sessionDate;
    if (startedAt != null) {
      freeVpnSessionStartedAt = startedAt;
    }
  }

  static void clearFreeVpnSessionStart() {
    freeVpnSessionStartedAt = null;
  }

  /// Optional update prompt dismissed for this target version.
  static String? get dismissedOptionalUpdateVersion =>
      _box.get('dismissedOptionalUpdateVersion') as String?;

  static set dismissedOptionalUpdateVersion(String? v) => v == null
      ? _box.delete('dismissedOptionalUpdateVersion')
      : _box.put('dismissedOptionalUpdateVersion', v);

  /// True when the resolved expiry calendar day is before today.
  static bool isSubscriptionExpired(User user, PremiumPlan plan) {
    return isUserSubscriptionExpired(user, plan);
  }
}
