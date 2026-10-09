import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../../../core/services/places/place_result.dart';

/// Provider-neutral, stable identity of a venue.
///
/// `providerId` is not allowed to persist (retention policy), so reactions are
/// keyed by the content the traveller sees instead:
///
///     sha256(normalize(name) + '|' + (normalize(address) | lat,lon))
///
/// The address wins when present; otherwise the coordinates rounded to four
/// decimals (about 11 m) are used; with neither, only the name is keyed.
///
/// Known and accepted consequence: two genuinely different venues that
/// normalise to the same name and address collapse into one key, and the second
/// one is treated as already seen.
String placeKey({
  required String name,
  String? address,
  double? latitude,
  double? longitude,
}) {
  final normalizedAddress = address == null ? '' : normalizePlaceText(address);
  final String locator;
  if (normalizedAddress.isNotEmpty) {
    locator = normalizedAddress;
  } else if (latitude != null &&
      longitude != null &&
      latitude.isFinite &&
      longitude.isFinite) {
    locator = '${_roundCoordinate(latitude)},${_roundCoordinate(longitude)}';
  } else {
    locator = '';
  }
  final input = '${normalizePlaceText(name)}|$locator';
  return sha256.convert(utf8.encode(input)).toString();
}

/// [placeKey] for a gateway result. Provider id and photo reference are
/// deliberately not part of the key.
String placeKeyOf(PlaceResult place) => placeKey(
      name: place.name,
      address: place.address,
      latitude: place.latitude,
      longitude: place.longitude,
    );

/// Trim, collapse inner whitespace, casefold and strip accents.
///
/// Dart has no full Unicode casefold, so lower-casing plus an explicit
/// Latin fold table is used. Combining marks are removed too, so decomposed
/// input (`e` + U+0301) matches its precomposed form.
String normalizePlaceText(String input) {
  final folded = StringBuffer();
  for (final rune in input.toLowerCase().runes) {
    final char = String.fromCharCode(rune);
    folded.write(_latinFold[char] ?? char);
  }
  return folded
      .toString()
      .replaceAll(_combiningMarks, '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

String _roundCoordinate(double value) {
  final fixed = value.toStringAsFixed(4);
  return fixed == '-0.0000' ? '0.0000' : fixed;
}

final RegExp _combiningMarks = RegExp('[\u0300-\u036f]');

const _foldGroups = <String, String>{
  'a': 'àáâãäåāăąǎ',
  'c': 'çćĉċč',
  'd': 'ďđ',
  'e': 'èéêëēĕėęě',
  'g': 'ĝğġģ',
  'h': 'ĥħ',
  'i': 'ìíîïĩīĭįıǐ',
  'j': 'ĵ',
  'k': 'ķ',
  'l': 'ĺļľŀł',
  'n': 'ñńņňŉ',
  'o': 'òóôõöøōŏőǒ',
  'r': 'ŕŗř',
  's': 'śŝşš',
  't': 'ţťŧ',
  'u': 'ùúûüũūŭůűųǔ',
  'w': 'ŵ',
  'y': 'ýÿŷ',
  'z': 'źżž',
};

final Map<String, String> _latinFold = {
  for (final entry in _foldGroups.entries)
    for (final char in entry.value.split('')) char: entry.key,
  'ß': 'ss',
  'æ': 'ae',
  'œ': 'oe',
};
