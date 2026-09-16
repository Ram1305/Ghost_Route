import 'package:flutter_test/flutter_test.dart';
import 'package:ghost_route/helpers/openvpn_config.dart';

void main() {
  group('applyCustomDnsToOpenVpnConfig', () {
    test('returns config unchanged when dnsServer is null', () {
      const config = 'client\ndev tun\n';
      expect(applyCustomDnsToOpenVpnConfig(config, null), config);
    });

    test('returns config unchanged when dnsServer is blank', () {
      const config = 'client\ndev tun\n';
      expect(applyCustomDnsToOpenVpnConfig(config, '   '), config);
    });

    test('appends dhcp-option DNS line when none exists', () {
      const config = 'client\ndev tun\n';
      final result = applyCustomDnsToOpenVpnConfig(config, '1.1.1.1');
      expect(result, 'client\ndev tun\ndhcp-option DNS 1.1.1.1\n');
    });

    test('replaces an existing dhcp-option DNS line', () {
      const config = 'client\ndhcp-option DNS 8.8.8.8\ndev tun\n';
      final result = applyCustomDnsToOpenVpnConfig(config, '1.1.1.1');
      expect(result.contains('8.8.8.8'), isFalse);
      expect(result.trim().split('\n').last, 'dhcp-option DNS 1.1.1.1');
    });

    test('replaces multiple existing dhcp-option DNS lines', () {
      const config =
          'client\ndhcp-option DNS 8.8.8.8\ndhcp-option DNS 8.8.4.4\ndev tun\n';
      final result = applyCustomDnsToOpenVpnConfig(config, '9.9.9.9');
      expect('DNS 8.8.8.8'.allMatches(result).length, 0);
      expect('DNS 8.8.4.4'.allMatches(result).length, 0);
      expect('dhcp-option DNS 9.9.9.9'.allMatches(result).length, 1);
    });

    test('does not touch dhcp-option DNS6 lines', () {
      const config = 'client\ndhcp-option DNS6 2001:4860:4860::8888\ndev tun\n';
      final result = applyCustomDnsToOpenVpnConfig(config, '1.1.1.1');
      expect(result.contains('DNS6 2001:4860:4860::8888'), isTrue);
      expect(result.contains('dhcp-option DNS 1.1.1.1'), isTrue);
    });

    test('trims whitespace on the provided dns server', () {
      const config = 'client\n';
      final result = applyCustomDnsToOpenVpnConfig(config, '  1.1.1.1  ');
      expect(result, 'client\ndhcp-option DNS 1.1.1.1\n');
    });
  });
}
