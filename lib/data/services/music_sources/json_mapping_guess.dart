import 'package:tune/data/services/music_sources/json_source_mapping.dart';

/// The names an answer usually gives each value the app reads.
///
/// The reader writes the paths of the fields by hand; the app can read them
/// off the answer itself. These are the names interfaces use most often, so a
/// guess is worth offering — and the reader corrects it.
const Map<String, List<String>> jsonFieldCandidates = {
  'idPath': ['id', 'trackId', 'songId', 'uuid', 'guid', 'hash'],
  'titlePath': ['title', 'name', 'songName', 'trackName', 'song', 'label'],
  'artistPath': [
    'artist',
    'artistName',
    'author',
    'singer',
    'performer',
    'creator',
    'uploader',
  ],
  'albumPath': ['album', 'albumName', 'albumTitle', 'collection', 'release'],
  'coverPath': [
    'cover',
    'coverUrl',
    'artwork',
    'artworkUrl',
    'image',
    'imageUrl',
    'picture',
    'thumbnail',
    'poster',
  ],
  'urlPath': [
    'url',
    'streamUrl',
    'audioUrl',
    'playUrl',
    'fileUrl',
    'downloadUrl',
    'src',
    'link',
    'file',
    'audio',
    'source',
    'mp3',
  ],
  'durationPath': [
    'duration',
    'length',
    'seconds',
    'time',
    'playtime',
    'runtime',
  ],
  'genrePath': [
    'genre',
    'genres',
    'category',
    'categories',
    'style',
    'tags',
    'mood',
  ],
};

/// The names a list of tracks is usually given.
const List<String> jsonListNames = [
  'data',
  'results',
  'items',
  'tracks',
  'songs',
  'list',
  'records',
  'entries',
  'rows',
  'docs',
  'payload',
  'response',
  'content',
  'collection',
  'audios',
  'media',
  'feed',
];

/// The mapping an answer suggests.
///
/// The paths the reader filled in are kept: the guess fills in what is still
/// empty, so a correction of the reader is never lost. A path that names a
/// value inside a value — `artist.name` — is read the same way as a plain
/// one, so the guess names it the way the answer nests it.
JsonSourceMapping guessJsonMapping(
  Object? answer, {
  JsonSourceMapping current = const JsonSourceMapping(),
}) {
  try {
    return _guess(answer, current);
  } on Object {
    // A shape the guess does not know is not a failure: the reader writes
    // the paths by hand then.
    return current;
  }
}

JsonSourceMapping _guess(Object? answer, JsonSourceMapping current) {
  final list = _findList(answer);
  if (list == null) return current;

  final settings = current.toSettings();
  if (settings['listPath']!.isEmpty) {
    settings['listPath'] = list.path;
  }

  final sample = _firstMap(list.items);
  if (sample == null) return JsonSourceMapping.fromSettings(settings);

  final used = <String>{};
  for (final field in const [
    'idPath',
    'titlePath',
    'artistPath',
    'albumPath',
    'coverPath',
    'urlPath',
    'durationPath',
    'genrePath',
  ]) {
    if (settings[field]!.isNotEmpty) continue;

    final key = _keyFor(sample, field, used);
    if (key == null) continue;

    settings[field] = _pathTo(sample, key);
    used.add(key);
  }

  return JsonSourceMapping.fromSettings(settings);
}

/// The settings the answer suggests, in the settings the form knows.
///
/// Only the paths that are still empty are suggested: a path the reader wrote
/// is theirs, and the guess does not take it away.
Map<String, String> jsonPathSuggestions({
  required JsonSourceMapping current,
  required JsonSourceMapping guessed,
}) {
  final before = current.toSettings();
  final after = guessed.toSettings();
  return {
    for (final entry in after.entries)
      if (entry.value.isNotEmpty && before[entry.key] != entry.value)
        entry.key: entry.value,
  };
}

/// The list of tracks in an answer, and where it sits.
({String path, List<dynamic> items})? _findList(Object? answer) {
  if (answer is List) {
    if (answer.any((item) => item is Map)) return (path: '', items: answer);
    return null;
  }
  if (answer is! Map) return null;
  return _search(answer, '', 0);
}

({String path, List<dynamic> items})? _search(
  Map<dynamic, dynamic> node,
  String prefix,
  int depth,
) {
  for (final name in jsonListNames) {
    final value = node[name];
    if (value is List && value.any((item) => item is Map)) {
      return (path: _join(prefix, name), items: value);
    }
  }

  for (final entry in node.entries) {
    final value = entry.value;
    if (value is List && value.any((item) => item is Map)) {
      return (path: _join(prefix, '${entry.key}'), items: value);
    }
  }

  if (depth >= 3) return null;

  for (final entry in node.entries) {
    final value = entry.value;
    if (value is! Map) continue;

    final found = _search(value, _join(prefix, '${entry.key}'), depth + 1);
    if (found != null) return found;
  }

  return null;
}

/// The first entry of a list that is a map.
Map<dynamic, dynamic>? _firstMap(List<dynamic> items) {
  for (final item in items) {
    if (item is Map) return item;
  }
  return null;
}

/// The key of an answer that holds the value of a field.
String? _keyFor(Map<dynamic, dynamic> sample, String field, Set<String> used) {
  for (final name in jsonFieldCandidates[field] ?? const <String>[]) {
    final key = _keyNamed(sample, name);
    if (key == null || used.contains(key)) continue;
    if (_isCoverName(key) && field != 'coverPath') continue;
    return key;
  }

  return switch (field) {
    'coverPath' => _keyByValue(sample, used, _isCoverName, _isAddress),
    'urlPath' => _keyByValue(sample, used, (_) => true, _isAddress),
    'durationPath' => _keyByValue(sample, used, _isDurationName, _isNumber),
    'genrePath' => _keyByValue(sample, used, _isGenreName, _isText),
    _ => null,
  };
}

/// The key of an answer that is called [name], in any spelling.
String? _keyNamed(Map<dynamic, dynamic> sample, String name) {
  final wanted = _normalize(name);
  for (final entry in sample.entries) {
    if (_normalize('${entry.key}') == wanted) return '${entry.key}';
  }
  return null;
}

/// The key of an answer whose name looks like [looksLike] and whose value
/// looks like [valueLooksLike].
String? _keyByValue(
  Map<dynamic, dynamic> sample,
  Set<String> used,
  bool Function(String key) looksLike,
  bool Function(Object? value) valueLooksLike,
) {
  for (final entry in sample.entries) {
    final key = '${entry.key}';
    if (used.contains(key)) continue;
    if (!looksLike(key)) continue;
    if (!valueLooksLike(entry.value)) continue;
    return key;
  }
  return null;
}

/// The path of a value inside an entry.
String _pathTo(Map<dynamic, dynamic> sample, String key) {
  final value = sample[key];
  if (value is! Map) return key;

  for (final inner in const ['name', 'title', 'url']) {
    if (value.containsKey(inner)) return '$key.$inner';
  }
  return key;
}

String _join(String prefix, String step) =>
    prefix.isEmpty ? step : '$prefix.$step';

String _normalize(String name) =>
    name.toLowerCase().replaceAll(RegExp(r'[_\-\s]'), '');

bool _isCoverName(String key) {
  final name = _normalize(key);
  return name.contains('cover') ||
      name.contains('artwork') ||
      name.contains('image') ||
      name.contains('thumb') ||
      name.contains('poster') ||
      name.contains('pic');
}

bool _isDurationName(String key) {
  final name = _normalize(key);
  if (name.contains('ms') || name.contains('milli')) return false;
  return name.contains('dur') ||
      name.contains('length') ||
      name.contains('len') ||
      name.contains('time') ||
      name.contains('sec');
}

bool _isGenreName(String key) {
  final name = _normalize(key);
  return name.contains('genre') ||
      name.contains('categor') ||
      name.contains('style') ||
      name.contains('tag') ||
      name.contains('mood');
}

bool _isAddress(Object? value) {
  if (value is! String) return false;
  return value.startsWith('http://') || value.startsWith('https://');
}

bool _isNumber(Object? value) => value is num;

bool _isText(Object? value) => value is String || value is List;
