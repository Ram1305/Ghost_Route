class AdminStats {
  final int totalUsers;
  final int activeSubscribers;
  final int unreadNotifications;

  AdminStats({
    required this.totalUsers,
    required this.activeSubscribers,
    required this.unreadNotifications,
  });

  factory AdminStats.fromJson(Map<String, dynamic> json) => AdminStats(
        totalUsers: (json['totalUsers'] as num?)?.toInt() ?? 0,
        activeSubscribers: (json['activeSubscribers'] as num?)?.toInt() ?? 0,
        unreadNotifications: (json['unreadNotifications'] as num?)?.toInt() ?? 0,
      );
}

class AdminSubscriptionEvent {
  final String userId;
  final String email;
  final String username;
  final String? planName;
  final DateTime date;
  final String? amount;
  final String? currency;
  final String? platform;

  AdminSubscriptionEvent({
    required this.userId,
    required this.email,
    required this.username,
    required this.planName,
    required this.date,
    required this.amount,
    required this.currency,
    required this.platform,
  });

  factory AdminSubscriptionEvent.fromJson(Map<String, dynamic> json) {
    return AdminSubscriptionEvent(
      userId: json['userId']?.toString() ?? '',
      email: json['email'] as String? ?? '',
      username: json['username'] as String? ?? '',
      planName: json['planName'] as String?,
      date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
      amount: json['amount']?.toString(),
      currency: json['currency'] as String?,
      platform: json['platform'] as String?,
    );
  }
}

/// Row shape from GET /api/users/ (admin-only, trimmed fields).
class AdminUserSummary {
  final String userId;
  final String username;
  final String email;
  final String role;
  final int? activePlan;
  final DateTime? subscriptionExpiresAt;
  final DateTime? createdAt;

  AdminUserSummary({
    required this.userId,
    required this.username,
    required this.email,
    required this.role,
    required this.activePlan,
    required this.subscriptionExpiresAt,
    required this.createdAt,
  });

  bool get isActiveSubscriber => activePlan != null;

  factory AdminUserSummary.fromJson(Map<String, dynamic> json) {
    return AdminUserSummary(
      userId: json['_id']?.toString() ?? '',
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? 'user',
      activePlan: (json['activePlan'] as num?)?.toInt(),
      subscriptionExpiresAt:
          DateTime.tryParse(json['subscriptionExpiresAt']?.toString() ?? ''),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
    );
  }
}

class AdminNotification {
  final String id;
  final String type;
  final String title;
  final String body;
  final bool read;
  final DateTime createdAt;

  AdminNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.read,
    required this.createdAt,
  });

  factory AdminNotification.fromJson(Map<String, dynamic> json) {
    return AdminNotification(
      id: json['_id']?.toString() ?? '',
      type: json['type'] as String? ?? '',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      read: json['read'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  AdminNotification copyWith({bool? read}) => AdminNotification(
        id: id,
        type: type,
        title: title,
        body: body,
        read: read ?? this.read,
        createdAt: createdAt,
      );
}
