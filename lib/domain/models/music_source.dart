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

  const MusicSourceField(
    this.key,
    this.label,
    this.hint, {
    this.required = false,
    this.numeric = false,
    this.secret = false,
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

/// User-editable configuration for one music source.
///
/// Sources are identified by a stable [id]. The [settings] map keeps adapter
/// specific values (search keywords, client ids, API base URLs) without
/// teaching the rest of the app about every adapter.
class MusicSourceConfig {
  final String id;
  final String name;
  final String description;
  final MusicSourceKind kind;
  final bool enabled;
  final Map<String, String> settings;

  /// Extra settings declared by a plugin (cookies, tokens, ...).
  final List<MusicSourceField> customFields;

  const MusicSourceConfig({
    required this.id,
    required this.name,
    this.description = '',
    required this.kind,
    this.enabled = true,
    this.settings = const {},
    this.customFields = const [],
  });

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
    String? name,
    String? description,
    MusicSourceKind? kind,
    bool? enabled,
    Map<String, String>? settings,
    List<MusicSourceField>? customFields,
  }) {
    return MusicSourceConfig(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      kind: kind ?? this.kind,
      enabled: enabled ?? this.enabled,
      settings: settings ?? this.settings,
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
          ),
        );
      }
    }

    return MusicSourceConfig(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      kind: _kindFromName(json['kind']?.toString()),
      enabled: rawEnabled is bool ? rawEnabled : true,
      settings: Map.unmodifiable(settings),
      customFields: List.unmodifiable(fields),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
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
          },
      ],
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
