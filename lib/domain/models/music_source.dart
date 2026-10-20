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

  const MusicSourceField(
    this.key,
    this.label,
    this.hint, {
    this.required = false,
    this.numeric = false,
    this.secret = false,
    this.choices = const [],
  });
}

/// How a music source gets its tracks.
enum MusicSourceKind {
  /// Directories on this device.
  localDirectory,

  /// A public catalogue with openly licensed audio (Openverse, Jamendo, ...).
  openCatalog,

  /// A self-hosted or remote JSON API that behaves as a source.
  openApi,

  /// A user-imported JavaScript plugin (MusicFree protocol).
  plugin,
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

  /// Extra settings declared by a plugin (cookies, tokens, ...).
  final List<MusicSourceField> customFields;

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
    this.customFields = const [],
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

  bool get isPlugin => kind == MusicSourceKind.plugin;

  String? get pluginFile => setting('pluginFile');

  /// Address the plugin script was downloaded from.
  ///
  /// Only plugins that were imported by URL can be updated.
  String? get pluginUrl => setting('pluginUrl');

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
    List<MusicSourceField>? customFields,
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
      customFields: customFields ?? this.customFields,
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
    final fields = <MusicSourceField>[];
    final rawFields = json['customFields'];
    if (rawFields is List) {
      for (final item in rawFields) {
        if (item is! Map) continue;
        final key = item['key']?.toString() ?? '';
        if (key.isEmpty) continue;
        fields.add(
          MusicSourceField(
            key,
            item['label']?.toString() ?? key,
            item['hint']?.toString() ?? '',
            required: item['required'] == true,
            numeric: item['numeric'] == true,
            secret: item['secret'] == true,
            choices: _choicesFromJson(item['choices']),
          ),
        );
      }
    }

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
      customFields: List.unmodifiable(fields),
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
    if (customFields.isNotEmpty)
      'customFields': [
        for (final field in customFields)
          {
            'key': field.key,
            'label': field.label,
            'hint': field.hint,
            'required': field.required,
            'numeric': field.numeric,
            'secret': field.secret,
            if (field.choices.isNotEmpty)
              'choices': [
                for (final choice in field.choices)
                  {'value': choice.value, 'label': choice.label},
              ],
          },
      ],
  };

  static MusicSourceKind _kindFromName(String? name) {
    return MusicSourceKind.values.firstWhere(
      (kind) => kind.name == name,
      orElse: () => MusicSourceKind.openApi,
    );
  }

  /// Reads the options of a setting back from the stored schema.
  static List<MusicSourceChoice> _choicesFromJson(Object? raw) {
    if (raw is! List) return const [];
    final choices = <MusicSourceChoice>[];
    for (final item in raw) {
      if (item is! Map) continue;
      final value = item['value']?.toString() ?? '';
      if (value.isEmpty) continue;
      choices.add(MusicSourceChoice(value, item['label']?.toString() ?? value));
    }
    return List.unmodifiable(choices);
  }

  @override
  String toString() => 'MusicSourceConfig($id, enabled: $enabled)';
}
