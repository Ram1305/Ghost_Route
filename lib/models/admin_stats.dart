class AdminStats {
  final int totalUsers;
  final int activeSubscribers;

  AdminStats({required this.totalUsers, required this.activeSubscribers});

  factory AdminStats.fromJson(Map<String, dynamic> json) => AdminStats(
        totalUsers: (json['totalUsers'] as num?)?.toInt() ?? 0,
        activeSubscribers: (json['activeSubscribers'] as num?)?.toInt() ?? 0,
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
