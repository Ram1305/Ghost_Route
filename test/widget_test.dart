import 'package:flutter_test/flutter_test.dart';
import 'package:yencode_vpn/config/app_config.dart';

void main() {
  test('Production API default uses HTTPS', () {
    expect(AppConfig.apiBaseUrl.startsWith('https://'), isTrue);
  });
}
