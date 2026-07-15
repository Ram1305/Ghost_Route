String flagEmojiForCountryName(String country) {
  final c = country.trim().toLowerCase();
  if (c.contains('united states') || c == 'usa' || c.contains('america')) {
    return '🇺🇸';
  }
  if (c.contains('singapore')) return '🇸🇬';
  if (c.contains('india')) return '🇮🇳';
  if (c.contains('japan')) return '🇯🇵';
  if (c.contains('united kingdom') || c == 'uk' || c.contains('britain')) {
    return '🇬🇧';
  }
  if (c.contains('germany')) return '🇩🇪';
  if (c.contains('france')) return '🇫🇷';
  if (c.contains('canada')) return '🇨🇦';
  if (c.contains('australia')) return '🇦🇺';
  if (c.contains('netherlands')) return '🇳🇱';
  return '🌐';
}
