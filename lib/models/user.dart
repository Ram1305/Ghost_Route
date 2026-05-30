import 'subscription.dart';

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

  User({
    required this.username,
    required this.email,
    required this.phone,
    required this.password,
    this.subscriptionHistory = const [],
    this.activePlan,
    this.subscriptionExpiresAt,
    this.backendUserId,
  });

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
    PremiumPlan? active =
        activePlanRaw != null && activePlanRaw is int && activePlanRaw >= 0 && activePlanRaw < PremiumPlan.values.length
            ? PremiumPlan.values[activePlanRaw]
            : null;
    final expiresAtRaw = json['subscriptionExpiresAt'];
    final DateTime? expiresAt = expiresAtRaw is String
        ? DateTime.tryParse(expiresAtRaw)
        : null;
    final backendId = json['backendUserId'] as String?;
    return User(
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      password: json['password'] ?? '',
      subscriptionHistory: history,
      activePlan: active,
      subscriptionExpiresAt: expiresAt,
      backendUserId: backendId,
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
  }) {
    return User(
      username: username ?? this.username,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      password: password ?? this.password,
      subscriptionHistory: subscriptionHistory ?? this.subscriptionHistory,
      activePlan: activePlan ?? this.activePlan,
      subscriptionExpiresAt: subscriptionExpiresAt ?? this.subscriptionExpiresAt,
      backendUserId: backendUserId ?? this.backendUserId,
    );
  }
}
