import 'package:flutter_test/flutter_test.dart';
import 'package:ghost_route/config/app_config.dart';

void main() {
  test('Production API default uses HTTPS', () {
    expect(AppConfig.apiBaseUrl.startsWith('https://'), isTrue);
  });
}
