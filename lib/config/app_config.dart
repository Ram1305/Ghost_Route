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

  /// Managed VPN server list (Ghost Route backend).
  static String get serversApiUrl => '$apiBaseUrl/api/servers';

  /// IP geolocation API (free tier; use with User-Agent).
  static const String ipApiUrl = 'http://ip-api.com/json/';

  /// Public privacy policy (host web/privacy-policy.html at this URL).
  static const String privacyPolicyUrl =
      'https://ghostroute.octosofttechnologies.in/privacy-policy.html';

  /// User-Agent for public HTTP requests (some APIs require it).
  static const String userAgent =
      'GhostRoute/1.0 (compatible; +https://ghostroute.octosofttechnologies.in)';
}
