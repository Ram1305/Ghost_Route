/// Backend API base URL (from env or build). Used by payment and other APIs.
///
/// Default: http://72.61.236.154:2626
/// Override via: flutter run --dart-define=API_BASE_URL=http://YOUR_IP:PORT
class AppConfig {
  AppConfig._();

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://ghostroute.octosofttechnologies.in',
  );

  /// VPN Gate public API (CSV list of servers).
  static const String vpnGateApiUrl = 'http://www.vpngate.net/api/iphone/';

  /// IP geolocation API (free tier; use with User-Agent).
  static const String ipApiUrl = 'http://ip-api.com/json/';

  /// User-Agent for public HTTP requests (some APIs require it).
  static const String userAgent =
      'TronVPN/1.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36';
}
