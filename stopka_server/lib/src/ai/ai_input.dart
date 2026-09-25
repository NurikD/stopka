import 'dart:typed_data';

/// Something wrong with a request; carries the reason shown to the app.
class InvalidInput implements Exception {
  final String reason;

  const InvalidInput(this.reason);
}

const Set<String> _levels = {'', 'A1', 'A2', 'B1', 'B2'};
const Set<String> _imageTypes = {'image/jpeg', 'image/png', 'image/webp'};

String requireLevel(String level) {
  if (!_levels.contains(level)) throw const InvalidInput('level');
  return level;
}

/// A required text field: non-blank and within [maxChars].
String requireText(String name, String value, int maxChars) {
  if (value.trim().isEmpty) throw InvalidInput('$name is empty');
  if (value.length > maxChars) throw InvalidInput('$name is too long');
  return value.trim();
}

/// An optional text field: may be empty, still capped.
String optionalText(String name, String value, int maxChars) {
  if (value.length > maxChars) throw InvalidInput('$name is too long');
  return value.trim();
}

List<String> requireList(String name, List<String> values, {required int maxItems, required int maxChars}) {
  if (values.length > maxItems) throw InvalidInput('$name has too many items');
  return [for (final v in values) optionalText(name, v, maxChars)].where((v) => v.isNotEmpty).toList();
}

Uint8List requireImage(Uint8List bytes, String mimeType, int maxBytes) {
  if (!_imageTypes.contains(mimeType)) throw const InvalidInput('image type');
  if (bytes.isEmpty) throw const InvalidInput('image is empty');
  if (bytes.length > maxBytes) throw const InvalidInput('image is too large');
  return bytes;
}
