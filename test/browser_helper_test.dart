import 'package:flutter_test/flutter_test.dart';
import 'package:ghost_route/helpers/browser_helper.dart';

void main() {
  group('BrowserHelper', () {
    test('resolveInput adds https scheme for domain-like input', () {
      expect(
        BrowserHelper.resolveInput('example.com'),
        'https://example.com',
      );
    });

    test('resolveInput keeps existing scheme', () {
      expect(
        BrowserHelper.resolveInput('https://example.com/path'),
        'https://example.com/path',
      );
    });

    test('resolveInput uses search for plain text', () {
      expect(
        BrowserHelper.resolveInput('ghost route vpn'),
        'https://duckduckgo.com/?q=ghost%20route%20vpn',
      );
    });

    test('resolveInput returns default for empty input', () {
      expect(
        BrowserHelper.resolveInput(''),
        BrowserHelper.defaultStartUrl,
      );
    });

    test('displayUrl strips scheme and trailing slash', () {
      expect(
        BrowserHelper.displayUrl('https://duckduckgo.com/'),
        'duckduckgo.com',
      );
    });
  });
}
