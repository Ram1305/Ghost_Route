/// Backend API base URL (from env or build). Used by payment and other APIs.
///
/// Production default: https://api.yencodetech.com
/// Override via: flutter run --dart-define=API_BASE_URL=https://YOUR_HOST
class AppConfig {
  AppConfig._();

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.yencodetech.com',
  );
}
