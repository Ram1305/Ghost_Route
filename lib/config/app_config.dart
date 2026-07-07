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

  /// Premium-only servers from backend.
  static String get premiumServersApiUrl =>
      '$apiBaseUrl/api/servers?premiumOnly=true';

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
      'Could not load subscription options. '
      'Please check your internet connection and try again. '
      'If the issue persists, restart the app.';

  /// Error when StoreKit returns no response (iOS).
  static const String storeKitNoResponseIos =
      'The App Store did not respond. Please check your internet connection and try again.';

  /// Error when store products are not configured (Android).
  static const String storeProductsNotFoundAndroid =
      'Could not load subscription options. Please check your internet connection and try again.';

  /// User-Agent for public HTTP requests (VPN Gate requires a desktop-style UA).
  static const String userAgent =
      'GhostRoute/1.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36';

  /// Visible paid-content labels for VPN-related screens (App Store Guideline 2.3.2).
  static const String disclaimerConnectRequired =
      '5 min free daily · Subscribe for unlimited VPN';
  static const String disclaimerActiveSubRequired =
      'Free session active · Subscribe for unlimited VPN';
  static const String disclaimerSecuredOverlayFree =
      'Free 5-minute session · Subscribe for unlimited VPN';
  static const String disclaimerSubscribeToServers =
      '5 min free daily · Subscribe for unlimited VPN';
  static const String disclaimerBrowseServers =
      'Browse free · 5 min VPN daily · Subscribe for unlimited';
  static const String disclaimerPlatinumBenefits =
      'Unlimited VPN access with a paid Platinum subscription';

  /// Home connect hint when user has no active subscription (Guideline 2.3.2).
  static const String connectHelperText =
      'One free 5-min session per day · Subscribe for unlimited';

  /// Shown when free daily session has already been used.
  static const String freeSessionExhaustedMessage =
      'Your free session for today is used. Subscribe for unlimited VPN.';

  /// Shown when the 5-minute free session timer reaches zero.
  static const String freeSessionEndedMessage =
      'Your free 5-minute session has ended. Subscribe for unlimited VPN.';

  /// Shown after manual disconnect during a free session.
  static const String freeSessionUsedMessage =
      'Today\'s free session is used. Subscribe for unlimited VPN.';

  /// Home connect hint when user has an active subscription.
  static const String connectHelperTextSubscribed =
      'Tap the shield to connect';

  /// Shown on Premium screen below hero (Guideline 2.3.2).
  static const String disclaimerPremiumHero =
      'Paid in-app purchase required to connect. Prices shown before purchase.';

  /// Profile screen — expired subscription (Guideline 2.3.2).
  static const String profileExpiredTitle =
      'Paid subscription expired. Purchase to renew.';
  static const String profileExpiredSubtitle =
      'Purchase a plan to connect to VPN and use premium features.';
  static const String profileUpgradeSubtitle =
      'Purchase a paid plan for faster speeds and more locations';
  static const String profileRenewButton = 'Purchase to renew';

  /// Google Play listing (package id).
  static const String playStorePackageId = 'com.yencode.ghostroute';

  /// Numeric App Store id — set in Firebase Remote Config `ios_app_store_id` when known.
  static const String iosAppStoreId = '';

  static String get playStoreUrl =>
      'https://play.google.com/store/apps/details?id=$playStorePackageId';

  static String appStoreUrlFor(String storeId) =>
      'https://apps.apple.com/app/id$storeId';
}
