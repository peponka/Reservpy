/// Normalizes a string by removing common accents/diacritics and converting to lowercase.
/// Used for matching category names between DB and code when labels vary by accents.
String normalizeString(String input) {
  final buffer = StringBuffer();
  for (final rune in input.trim().toLowerCase().runes) {
    switch (rune) {
      case 0x00E1:
      case 0x00E0:
      case 0x00E4:
      case 0x00E2:
        buffer.write('a');
        break;
      case 0x00E9:
      case 0x00E8:
      case 0x00EB:
      case 0x00EA:
        buffer.write('e');
        break;
      case 0x00ED:
      case 0x00EC:
      case 0x00EF:
      case 0x00EE:
        buffer.write('i');
        break;
      case 0x00F3:
      case 0x00F2:
      case 0x00F6:
      case 0x00F4:
        buffer.write('o');
        break;
      case 0x00FA:
      case 0x00F9:
      case 0x00FC:
      case 0x00FB:
        buffer.write('u');
        break;
      case 0x00F1:
        buffer.write('n');
        break;
      default:
        buffer.write(String.fromCharCode(rune));
    }
  }
  return buffer.toString();
}

/// Looks up a value in a map using normalized key comparison.
/// Returns the value if found, null otherwise.
V? normalizedLookup<V>(Map<String, V> map, String key) {
  final normalizedKey = normalizeString(key);
  for (final entry in map.entries) {
    if (normalizeString(entry.key) == normalizedKey) {
      return entry.value;
    }
  }
  return null;
}

/// Builds the canonical public booking URL for a business.
String publicBusinessUrl(String businessId) {
  if (businessId.trim().isEmpty) {
    return 'https://www.reservpy.com';
  }
  return 'https://www.reservpy.com/#/business-detail/$businessId';
}
