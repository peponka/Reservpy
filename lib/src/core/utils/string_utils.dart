/// Normalizes a string by removing accents/diacritics and converting to lowercase.
/// Used for matching category names between DB (accented) and code (unaccented).
String normalizeString(String input) {
  const accents = 'áéíóúÁÉÍÓÚàèìòùÀÈÌÒÙäëïöüÄËÏÖÜâêîôûÂÊÎÔÛñÑ';
  const noAccents = 'aeiouAEIOUaeiouAEIOUaeiouAEIOUaeiouAEIOUnN';

  var result = input;
  for (var i = 0; i < accents.length; i++) {
    result = result.replaceAll(accents[i], noAccents[i]);
  }
  return result.toLowerCase().trim();
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
