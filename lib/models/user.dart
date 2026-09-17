import 'subscription.dart';
import '../helpers/subscription_expiry.dart';

class User {
  final String username;
  final String email;
  final String phone;
  final String password;
  final List<Subscription> subscriptionHistory;
  final PremiumPlan? activePlan;
  final DateTime? subscriptionExpiresAt;
  /// Backend MongoDB user id; when set, payment flow will call activate-subscription API.
  final String? backendUserId;
  /// 'user' (default) or 'admin'. Server-assigned only (ADMIN_EMAILS) — never
  /// trust this for access control, it's for UI gating only; the backend
  /// re-verifies the real role from the database on every admin API call.
  final String role;

  User({
    required this.username,
    required this.email,
    required this.phone,
    required this.password,
    this.subscriptionHistory = const [],
    this.activePlan,
    this.subscriptionExpiresAt,
    this.backendUserId,
    this.role = 'user',
  });

  bool get isAdmin => role == 'admin';

  /// Stable id for keying; email is unique per user.
  String get id => email;

  Map<String, dynamic> toJson() => {
        'username': username,
        'email': email,
        'phone': phone,
        'password': password,
        'subscriptionHistory':
            subscriptionHistory.map((e) => e.toJson()).toList(),
        if (activePlan != null) 'activePlan': activePlan!.index,
        if (subscriptionExpiresAt != null)
          'subscriptionExpiresAt': subscriptionExpiresAt!.toIso8601String(),
        if (backendUserId != null) 'backendUserId': backendUserId,
        'role': role,
      };

  factory User.fromJson(Map<String, dynamic> json) {
    final historyRaw = json['subscriptionHistory'];
    List<Subscription> history = [];
    if (historyRaw is List) {
      history = historyRaw
          .map((e) => Subscription.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    }
    final activePlanRaw = json['activePlan'];
    PremiumPlan? active = activePlanRaw != null && activePlanRaw is int
            ? PremiumPlanX.fromStoredIndex(activePlanRaw)
            : null;
    final expiresAtRaw = json['subscriptionExpiresAt'];
    final DateTime? expiresAt = parseSubscriptionDate(expiresAtRaw);
    final backendId = json['backendUserId'] as String?;
    final roleRaw = json['role'];
    final role = roleRaw == 'admin' ? 'admin' : 'user';
    return User(
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      password: json['password'] ?? '',
      subscriptionHistory: history,
      activePlan: active,
      subscriptionExpiresAt: expiresAt,
      backendUserId: backendId,
      role: role,
    );
  }

  /// Copy with new subscription history and/or active plan (for updatePack).
  User copyWith({
    String? username,
    String? email,
    String? phone,
    String? password,
    List<Subscription>? subscriptionHistory,
    PremiumPlan? activePlan,
    DateTime? subscriptionExpiresAt,
    String? backendUserId,
    String? role,
  }) {
    return User(
      username: username ?? this.username,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      password: password ?? this.password,
      subscriptionHistory: subscriptionHistory ?? this.subscriptionHistory,
      activePlan: activePlan ?? this.activePlan,
      role: role ?? this.role,
      subscriptionExpiresAt: subscriptionExpiresAt ?? this.subscriptionExpiresAt,
      backendUserId: backendUserId ?? this.backendUserId,
    );
  }
}
