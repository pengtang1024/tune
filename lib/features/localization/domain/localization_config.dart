/// Where the text translations come from.
enum TranslationEngineKind {
  /// The small model that ships with the app and runs on the CPU.
  local,

  /// Any endpoint that speaks the OpenAI chat dialect.
  openAiCompatible,
}

/// The settings of the automatic localisation of dynamic text.
///
/// The switches live in [SettingsState] like every other preference: this
/// object is the value of that field, not a second source of truth.
class LocalizationConfig {
  /// The model the offline engine runs.
  static const String localModelId = 'qwen2.5-0.5b-instruct-q4_k_m';

  /// Whether missing text is translated at all.
  final bool enabled;

  /// Whether the line keeps the original text under the translation.
  final bool showOriginal;

  final TranslationEngineKind engine;

  /// The advanced endpoint. Empty until the reader fills it in.
  final String apiBaseUrl;
  final String apiKey;
  final String apiModel;

  const LocalizationConfig({
    this.enabled = true,
    this.showOriginal = true,
    this.engine = TranslationEngineKind.local,
    this.apiBaseUrl = '',
    this.apiKey = '',
    this.apiModel = '',
  });

  bool get apiConfigured =>
      apiBaseUrl.trim().isNotEmpty && apiModel.trim().isNotEmpty;

  LocalizationConfig copyWith({
    bool? enabled,
    bool? showOriginal,
    TranslationEngineKind? engine,
    String? apiBaseUrl,
    String? apiKey,
    String? apiModel,
  }) {
    return LocalizationConfig(
      enabled: enabled ?? this.enabled,
      showOriginal: showOriginal ?? this.showOriginal,
      engine: engine ?? this.engine,
      apiBaseUrl: apiBaseUrl ?? this.apiBaseUrl,
      apiKey: apiKey ?? this.apiKey,
      apiModel: apiModel ?? this.apiModel,
    );
  }

  factory LocalizationConfig.fromJson(Map<String, dynamic> json) {
    final name = json['engine'] as String?;
    final engine = TranslationEngineKind.values.firstWhere(
      (value) => value.name == name,
      orElse: () => TranslationEngineKind.local,
    );
    return LocalizationConfig(
      enabled: json['enabled'] as bool? ?? true,
      showOriginal: json['showOriginal'] as bool? ?? true,
      engine: engine,
      apiBaseUrl: json['apiBaseUrl'] as String? ?? '',
      apiKey: json['apiKey'] as String? ?? '',
      apiModel: json['apiModel'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'showOriginal': showOriginal,
    'engine': engine.name,
    'apiBaseUrl': apiBaseUrl,
    'apiKey': apiKey,
    'apiModel': apiModel,
  };

  @override
  bool operator ==(Object other) =>
      other is LocalizationConfig &&
      other.enabled == enabled &&
      other.showOriginal == showOriginal &&
      other.engine == engine &&
      other.apiBaseUrl == apiBaseUrl &&
      other.apiKey == apiKey &&
      other.apiModel == apiModel;

  @override
  int get hashCode =>
      Object.hash(enabled, showOriginal, engine, apiBaseUrl, apiKey, apiModel);
}
