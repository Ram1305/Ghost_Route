/// URL normalization and search fallback for the in-app browser.
class BrowserHelper {
  BrowserHelper._();

  static const String defaultStartUrl = 'https://duckduckgo.com';

  /// Turns user input into a loadable URL or a search query URL.
  static String resolveInput(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return defaultStartUrl;

    if (_looksLikeUrl(trimmed)) {
      return _normalizeUrl(trimmed);
    }

    final query = Uri.encodeComponent(trimmed);
    return 'https://duckduckgo.com/?q=$query';
  }

  static bool _looksLikeUrl(String value) {
    if (value.contains(' ')) return false;
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return true;
    }
    if (value.startsWith('localhost') || value.startsWith('127.0.0.1')) {
      return true;
    }
    return value.contains('.') && !value.startsWith('.');
  }

  static String _normalizeUrl(String value) {
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }
    return 'https://$value';
  }

  /// Display-friendly URL for the address bar (no scheme).
  static String displayUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    return url
        .replaceFirst(RegExp(r'^https?://'), '')
        .replaceFirst(RegExp(r'/$'), '');
  }
}
