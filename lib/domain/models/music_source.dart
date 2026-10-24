/// One option of a setting that only allows a fixed set of values.
///
/// The value is what gets stored, the label is what the user reads, so a
/// source can offer translated labels without changing its saved data.
class MusicSourceChoice {
  final String value;
  final String label;

  const MusicSourceChoice(this.value, this.label);
}

/// How many tracks one scan of a source fetches.
///
/// A source counts its tracks in a unit of its own, and the interface shows
/// that number and its ceiling. Both live here, so the field the user reads
/// and the scan that runs never drift apart.
class MusicSourceLimit {
  /// How many tracks a scan fetches when the user set no limit.
  final int count;

  /// The most tracks one scan may fetch.
  final int max;

  const MusicSourceLimit(this.count, this.max);

  /// The limit a configuration asks for, inside the bounds of the source.
  int read(String? raw) {
    final parsed = int.tryParse(raw ?? '') ?? 0;
    if (parsed <= 0) return count;
    return parsed.clamp(1, max);
  }
}

/// One user-editable setting declared by a music source adapter.
///
/// Keeping the schema in the data layer lets the settings UI render any source
/// without knowing its id or implementation details.
class MusicSourceField {
  final String key;
  final String label;
  final String hint;
  final bool required;
  final bool numeric;

  /// Whether the value is a secret and must not be shown on screen.
  final bool secret;

  /// The values the setting allows.
  ///
  /// An empty list leaves the setting a free text field.
  final List<MusicSourceChoice> choices;

  /// Whether the setting is one that is rarely needed.
  ///
  /// The form keeps these out of the way until the reader asks for them: a
  /// type with a dozen settings is a wall of boxes otherwise.
  final bool advanced;

  /// The value the form starts with when nothing is filled in yet.
  ///
  /// A setting the reader has to write from scratch can start from a shape
  /// that is already right: a document to change, not to invent.
  final String defaultValue;

  /// Whether the value spans several lines.
  ///
  /// A setting that holds a list — a line of addresses, a header — is read
  /// better in a box than in a single line.
  final bool multiline;

  const MusicSourceField(
    this.key,
    this.label,
    this.hint, {
    this.required = false,
    this.numeric = false,
    this.secret = false,
    this.multiline = false,
    this.advanced = false,
    this.defaultValue = '',
    this.choices = const [],
  });
}

/// The id and the name of a new instance of [type].
///
/// Instances of one type are told apart by a number: the first is `type-1`,
/// the next is `type-2`. The number is the smallest one not in use, so
/// deleting an instance does not push the others around.
///
/// The number is joined with a dash and not with a colon: the id of an
/// instance is the host of the `tune://` address of its tracks, and a colon
/// in a host reads as the port.
///
/// The name is what the reader sees. An empty name falls back to the name of
/// the type and the number of the instance, so two instances of one type
/// never carry the same name.
({String id, String name}) newSourceInstance({
  required String type,
  required String typeName,
  required String name,
  required Iterable<MusicSourceConfig> sources,
}) {
  final used = <int>{};
  for (final source in sources) {
    if (source.sourceType != type) continue;
    final index = _instanceNumber(source.id);
    if (index != null) used.add(index);
  }

  var number = 1;
  while (used.contains(number)) {
    number++;
  }

  final trimmed = name.trim();
  return (
    id: '$type-$number',
    name: trimmed.isEmpty ? '$typeName $number' : trimmed,
  );
}

/// The number in the id of an instance, when the id carries one.
int? _instanceNumber(String id) {
  final separator = id.lastIndexOf('-');
  if (separator < 0) return null;
  return int.tryParse(id.substring(separator + 1));
}

/// The type of the sources the app used to run as scripts.
///
/// The app does not run scripts any more, so a configuration of this type is
/// dropped when the sources are read back: it has no adapter, and a source
/// that never opens is worse than no source at all.
const String retiredPluginType = 'plugin';

/// How a music source gets its tracks.
enum MusicSourceKind {
  /// Directories on this device.
  localDirectory,

  /// A public catalogue with openly licensed audio (Openverse, Jamendo, ...).
  openCatalog,

  /// A self-hosted or remote JSON API that behaves as a source.
  openApi,

  /// A source the reader added with its own parameters: a feed, an address,
  /// a mapped API.
  custom,
}

/// What the interface shows about a source.
///
/// The name is the name the source writes its own name with (a brand keeps
/// its own spelling in every language); the localized name is what the source
/// is called in the language of the reader. The two travel together, so a
/// source is never named in one place and named differently in another.
///
/// The type and the kind are what the interface needs to draw the source
/// without reading its name: the type picks the icon that stands for the
/// source, the kind picks one when the source has no icon of its own.
class SourceLabel {
  final String name;
  final String localizedName;
  final String type;
  final MusicSourceKind kind;

  const SourceLabel({
    required this.name,
    this.localizedName = '',
    this.type = '',
    this.kind = MusicSourceKind.openCatalog,
  });

  @override
  String toString() => 'SourceLabel($name, $localizedName)';
}

/// User-editable configuration for one music source.
///
/// Sources are identified by a stable [id]. The [settings] map keeps adapter
/// specific values (search keywords, client ids, API base URLs) without
/// teaching the rest of the app about every adapter.
class MusicSourceConfig {
  final String id;

  /// The type of the source: the key the adapter registry looks up.
  ///
  /// A type says *how* the tracks are fetched; an instance says *which* one.
  /// Several instances may share a type — a second Jamendo, another Subsonic
  /// server — so the type is not the id.
  final String type;
  final String name;

  /// The name of the source in the language of the reader.
  ///
  /// A source whose name is already in that language (a folder of local
  /// music, a podcast feed) has no second name; a source named after a brand
  /// has one, so the reader knows what the brand is.
  final String localizedName;
  final String description;
  final MusicSourceKind kind;
  final bool enabled;
  final Map<String, String> settings;

  /// Whether the source came with the app.
  ///
  /// A built-in source can be switched off but not deleted; a source the
  /// user added can be deleted with its tracks.
  final bool builtIn;

  /// Where the source stands in the reader's order.
  ///
  /// A higher number stands earlier. The local music is pinned at
  /// [SourceWeights.local]; the other sources may be moved, and a source
  /// below [SourceWeights.mainThreshold] waits in the folded "More sources"
  /// group. A configuration written before the weight existed has no number
  /// and receives a default when the controller reads it.
  final int? weight;

  const MusicSourceConfig({
    required this.id,
    this.type = '',
    required this.name,
    this.localizedName = '',
    this.description = '',
    required this.kind,
    this.enabled = true,
    this.settings = const {},
    this.builtIn = false,
    this.weight,
  });

  /// The type the adapter registry is asked for.
  ///
  /// A configuration written before the split carries no type: its id was
  /// the type, except for plugins, whose id carries a hash.
  String get sourceType => type.isNotEmpty ? type : legacyTypeOf(id);

  /// The type a configuration written before the split had.
  static String legacyTypeOf(String id) =>
      id.startsWith('plugin_') ? 'plugin' : id;

  bool get isLocal => kind == MusicSourceKind.localDirectory;

  String? setting(String key) {
    final value = settings[key];
    if (value == null) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  MusicSourceConfig copyWith({
    String? id,
    String? type,
    String? name,
    String? localizedName,
    String? description,
    MusicSourceKind? kind,
    bool? enabled,
    Map<String, String>? settings,
    bool? builtIn,
    int? weight,
  }) {
    return MusicSourceConfig(
      id: id ?? this.id,
      type: type ?? this.type,
      name: name ?? this.name,
      localizedName: localizedName ?? this.localizedName,
      description: description ?? this.description,
      kind: kind ?? this.kind,
      enabled: enabled ?? this.enabled,
      settings: settings ?? this.settings,
      builtIn: builtIn ?? this.builtIn,
      weight: weight ?? this.weight,
    );
  }

  factory MusicSourceConfig.fromJson(Map<String, dynamic> json) {
    final rawSettings = json['settings'];
    final settings = <String, String>{};
    if (rawSettings is Map) {
      rawSettings.forEach((key, value) {
        if (key is String && value != null) {
          settings[key] = value.toString();
        }
      });
    }

    final rawEnabled = json['enabled'];
    final rawWeight = json['weight'];

    final id = json['id']?.toString() ?? '';
    return MusicSourceConfig(
      id: id,
      type: json['type']?.toString() ?? legacyTypeOf(id),
      name: json['name']?.toString() ?? '',
      localizedName: json['localizedName']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      kind: _kindFromName(json['kind']?.toString()),
      enabled: rawEnabled is bool ? rawEnabled : true,
      settings: Map.unmodifiable(settings),
      builtIn: json['builtIn'] == true,
      weight: rawWeight is num ? rawWeight.toInt() : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': sourceType,
    'name': name,
    'localizedName': localizedName,
    'description': description,
    'kind': kind.name,
    'enabled': enabled,
    'settings': settings,
    if (weight != null) 'weight': weight,
  };

  static MusicSourceKind _kindFromName(String? name) {
    return MusicSourceKind.values.firstWhere(
      (kind) => kind.name == name,
      orElse: () => MusicSourceKind.openApi,
    );
  }

  @override
  String toString() => 'MusicSourceConfig($id, enabled: $enabled)';
}
