/// Injects/overrides the DNS server pushed via OpenVPN's `dhcp-option DNS`
/// directive. Returns [config] unchanged when [dnsServer] is null/blank.
/// Existing `dhcp-option DNS <ip>` lines are removed (DNS6 lines are left
/// alone) and a single line for [dnsServer] is appended.
String applyCustomDnsToOpenVpnConfig(String config, String? dnsServer) {
  final dns = dnsServer?.trim() ?? '';
  if (dns.isEmpty) return config;

  final withoutExistingDns = config.replaceAll(
    RegExp(
      r'^[ \t]*dhcp-option[ \t]+DNS[ \t]+\S+[ \t]*\r?\n?',
      multiLine: true,
      caseSensitive: false,
    ),
    '',
  );
  return '${withoutExistingDns.trimRight()}\ndhcp-option DNS $dns\n';
}
