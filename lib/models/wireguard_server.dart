class WireguardServer {
  final int id;
  final String serverName;
  final String country;
  final String city;
  final String host;
  final int port;
  final String publicKey;
  final String clientPrivateKey;
  final String address;
  final String dns;
  final String allowedIPs;
  final int persistentKeepalive;

  const WireguardServer({
    required this.id,
    required this.serverName,
    required this.country,
    required this.city,
    required this.host,
    required this.port,
    required this.publicKey,
    required this.clientPrivateKey,
    required this.address,
    required this.dns,
    required this.allowedIPs,
    required this.persistentKeepalive,
  });

  factory WireguardServer.fromJson(Map<String, dynamic> json) {
    return WireguardServer(
      id: _parseInt(json['id'], 0),
      serverName: (json['serverName'] ?? '').toString(),
      country: (json['country'] ?? '').toString(),
      city: (json['city'] ?? '').toString(),
      host: (json['host'] ?? '').toString(),
      port: _parseInt(json['port'], 0),
      publicKey: (json['publicKey'] ?? '').toString(),
      clientPrivateKey: (json['clientPrivateKey'] ?? '').toString(),
      address: (json['address'] ?? '').toString(),
      dns: (json['dns'] ?? '').toString(),
      allowedIPs: (json['allowedIPs'] ?? '').toString(),
      persistentKeepalive: _parseInt(json['persistentKeepalive'], 0),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'serverName': serverName,
        'country': country,
        'city': city,
        'host': host,
        'port': port,
        'publicKey': publicKey,
        'clientPrivateKey': clientPrivateKey,
        'address': address,
        'dns': dns,
        'allowedIPs': allowedIPs,
        'persistentKeepalive': persistentKeepalive,
      };

  static int _parseInt(dynamic value, int defaultValue) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? defaultValue;
  }
}

