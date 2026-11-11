import 'dart:convert';

/// The instruction both engines send.
String translationInstruction(String targetLanguage) =>
    'You translate music metadata. Translate every item into '
    '$targetLanguage. Keep artist names, brand names, numbers and text that '
    'is already in the target language unchanged. Never explain, never add '
    'notes. Answer with JSON only, an array of objects shaped '
    '{"id": <number>, "text": "<translation>"}.';

/// The user message: the items are data, never instructions.
String translationPayload(List<String> texts) => jsonEncode([
  for (var i = 0; i < texts.length; i++) {'id': i, 'text': texts[i]},
]);

/// Reads the answer back into the source text it belongs to.
///
/// A model that wraps the JSON in prose, or repeats an id, still yields the
/// items it did answer. Answers that are missing, empty or absurdly long are
/// dropped, so a runaway generation never replaces a title on screen.
Map<String, String> parseTranslationPayload(
  String raw,
  List<String> sources,
) {
  final start = raw.indexOf('[');
  final end = raw.lastIndexOf(']');
  if (start < 0 || end <= start) {
    return _singleFallback(raw, sources);
  }
  try {
    final decoded = jsonDecode(raw.substring(start, end + 1));
    if (decoded is! List) return _singleFallback(raw, sources);
    final result = <String, String>{};
    for (final item in decoded) {
      if (item is! Map) continue;
      final id = item['id'];
      final text = item['text'];
      if (id is! num || text is! String) continue;
      final index = id.toInt();
      if (index < 0 || index >= sources.length) continue;
      final value = text.trim();
      if (!_plausible(sources[index], value)) continue;
      result[sources[index]] = value;
    }
    return result;
  } catch (_) {
    return _singleFallback(raw, sources);
  }
}

/// One text has no id to echo, so a bare answer is accepted when it is sane.
Map<String, String> _singleFallback(String raw, List<String> sources) {
  if (sources.length != 1) return const {};
  var value = raw.trim();
  if (value.startsWith('"') && value.endsWith('"') && value.length > 2) {
    value = value.substring(1, value.length - 1).trim();
  }
  if (!_plausible(sources.single, value)) return const {};
  return {sources.single: value};
}

bool _plausible(String source, String value) {
  if (value.isEmpty) return false;
  if (value.length > source.length * 4 + 80) return false;
  if (value.contains('\n')) return false;
  return true;
}
