class VpnConnectionSession {
  final String country;
  final DateTime startedAt;
  final DateTime endedAt;
  final String protocol;

  const VpnConnectionSession({
    required this.country,
    required this.startedAt,
    required this.endedAt,
    required this.protocol,
  });

  Duration get duration => endedAt.difference(startedAt);

  factory VpnConnectionSession.fromJson(Map<String, dynamic> json) {
    return VpnConnectionSession(
      country: (json['country'] ?? '').toString(),
      startedAt: DateTime.fromMillisecondsSinceEpoch(
        _parseInt(json['startedAt'], 0),
      ),
      endedAt: DateTime.fromMillisecondsSinceEpoch(
        _parseInt(json['endedAt'], 0),
      ),
      protocol: (json['protocol'] ?? 'openvpn').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'country': country,
        'startedAt': startedAt.millisecondsSinceEpoch,
        'endedAt': endedAt.millisecondsSinceEpoch,
        'protocol': protocol,
      };

  static int _parseInt(dynamic value, int defaultValue) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? defaultValue;
  }
}
