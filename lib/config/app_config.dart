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

  /// VPN Gate public API (CSV list of servers — large list).
  static const String vpnGateApiUrl = 'http://www.vpngate.net/api/iphone/';

  /// Managed VPN server list (Ghost Route backend; merged with VPN Gate).
  static String get serversApiUrl => '$apiBaseUrl/api/servers';

  /// IP geolocation API (free tier; use with User-Agent).
  static const String ipApiUrl = 'http://ip-api.com/json/';

  /// Public privacy policy (deploy web/privacy-policy.html to Netlify).
  static const String privacyPolicyUrl = 'https://ghostroutes.netlify.app/';

  /// Terms of Use / EULA.
  static const String termsOfUseUrl = 'https://ghostroutetermsofuse.netlify.app/';

  /// Auto-renewal disclosure shown on subscription screens (iOS).
  static const String subscriptionDisclosureIos =
      'Subscriptions renew automatically unless cancelled at least 24 hours before the end of the current period. '
      'Payment is charged to your App Store account. '
      'Manage or cancel in Settings → Apple ID → Subscriptions.';

  /// Auto-renewal disclosure shown on subscription screens (Android).
  static const String subscriptionDisclosureAndroid =
      'Subscriptions renew automatically unless cancelled at least 24 hours before the end of the current period. '
      'Payment is charged to your Google Play account. '
      'Manage or cancel in Google Play subscription settings.';

  /// Error when store products are not configured (iOS).
  static const String storeProductsNotFoundIos =
      'Could not load App Store subscriptions. '
      'On Simulator: open ios/Runner.xcworkspace in Xcode and use Product → Run (⌘R) — '
      'flutter run does not load Products.storekit. '
      'On a device: add all 6 subscription IDs in App Store Connect and sign in with a Sandbox Apple ID.';

  /// Error when StoreKit returns no response (iOS).
  static const String storeKitNoResponseIos =
      'App Store did not respond. On Simulator, run from Xcode (Product → Run), not flutter run. '
      'On device, check App Store Connect products and Sandbox account.';

  /// Error when store products are not configured (Android).
  static const String storeProductsNotFoundAndroid =
      'Subscription not found in the store. Ensure products are configured in Google Play Console.';

  /// User-Agent for public HTTP requests (VPN Gate requires a desktop-style UA).
  static const String userAgent =
      'GhostRoute/1.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36';
}
