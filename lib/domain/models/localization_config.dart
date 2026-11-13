/// What one vendor's key and model are for the current reader.
class ProviderCredential {
  final String apiKey;
  final String model;

  /// The endpoint, only for the custom entry. Empty means "use the catalog".
  final String baseUrl;

  const ProviderCredential({
    this.apiKey = '',
    this.model = '',
    this.baseUrl = '',
  });

  ProviderCredential copyWith({
    String? apiKey,
    String? model,
    String? baseUrl,
  }) {
    return ProviderCredential(
      apiKey: apiKey ?? this.apiKey,
      model: model ?? this.model,
      baseUrl: baseUrl ?? this.baseUrl,
    );
  }

  factory ProviderCredential.fromJson(Map<String, dynamic> json) {
    return ProviderCredential(
      apiKey: json['apiKey'] as String? ?? '',
      model: json['model'] as String? ?? '',
      baseUrl: json['baseUrl'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'apiKey': apiKey,
    'model': model,
    'baseUrl': baseUrl,
  };

  @override
  bool operator ==(Object other) =>
      other is ProviderCredential &&
      other.apiKey == apiKey &&
      other.model == model &&
      other.baseUrl == baseUrl;

  @override
  int get hashCode => Object.hash(apiKey, model, baseUrl);
}

/// The settings of the automatic localisation of dynamic text.
///
/// The switches live in [SettingsState] like every other preference: this
/// object is the value of that field, not a second source of truth.
class LocalizationConfig {
  /// The model the offline engine runs.
  static const String localModelId = 'qwen2.5-0.5b-instruct-q4_k_m';

  /// The backend that runs the optional local model.
  static const String localBackendId = 'local';

  /// The backend that talks to a reader-supplied OpenAI-compatible endpoint.
  static const String customBackendId = 'custom';

  /// Whether missing text is translated at all.
  final bool enabled;

  /// Whether the line keeps the original text under the translation.
  final bool showOriginal;

  /// The chosen vendor, or the local model. Empty means none is chosen.
  final String backendId;

  /// One key and model per vendor, so switching vendors keeps both.
  final Map<String, ProviderCredential> credentials;

  /// Whether the reader has confirmed what leaves the device.
  final bool privacyAccepted;

  const LocalizationConfig({
    this.enabled = true,
    this.showOriginal = true,
    this.privacyAccepted = false,
    this.backendId = '',
    this.credentials = const {},
  });

  bool get hasBackend => backendId.trim().isNotEmpty;

  bool get usesLocalModel => backendId == localBackendId;

  bool get isCustom => backendId == customBackendId;

  ProviderCredential credentialFor(String id) =>
      credentials[id] ?? const ProviderCredential();

  ProviderCredential get activeCredential => credentialFor(backendId);

  /// The keys of every vendor that carries one, by the id of the vendor.
  Map<String, String> get keyMap => Map<String, String>.unmodifiable({
    for (final entry in credentials.entries)
      if (entry.value.apiKey.trim().isNotEmpty)
        entry.key: entry.value.apiKey.trim(),
  });

  /// Puts the keys read from the key file into the credentials.
  ///
  /// A key replaces the one of its vendor and nothing else: the model and the
  /// endpoint the reader typed stay where they were.
  LocalizationConfig withKeys(Map<String, String> keys) {
    final merged = Map<String, ProviderCredential>.of(credentials);
    for (final entry in keys.entries) {
      final id = entry.key.trim();
      final apiKey = entry.value.trim();
      if (id.isEmpty || apiKey.isEmpty) continue;
      merged[id] = (merged[id] ?? const ProviderCredential()).copyWith(
        apiKey: apiKey,
      );
    }
    if (_sameCredentials(merged, credentials)) return this;
    return copyWith(
      credentials: Map<String, ProviderCredential>.unmodifiable(merged),
    );
  }

  LocalizationConfig withCredential(String id, ProviderCredential credential) {
    return copyWith(
      credentials: Map<String, ProviderCredential>.unmodifiable({
        ...credentials,
        id: credential,
      }),
    );
  }

  LocalizationConfig copyWith({
    bool? enabled,
    bool? showOriginal,
    bool? privacyAccepted,
    String? backendId,
    Map<String, ProviderCredential>? credentials,
  }) {
    return LocalizationConfig(
      enabled: enabled ?? this.enabled,
      showOriginal: showOriginal ?? this.showOriginal,
      privacyAccepted: privacyAccepted ?? this.privacyAccepted,
      backendId: backendId ?? this.backendId,
      credentials: credentials ?? this.credentials,
    );
  }

  factory LocalizationConfig.fromJson(Map<String, dynamic> json) {
    final credentials = _readCredentials(json['credentials']);
    final backendId = (json['backendId'] as String?)?.trim() ?? '';
    if (backendId.isNotEmpty) {
      return LocalizationConfig(
        enabled: json['enabled'] as bool? ?? true,
        showOriginal: json['showOriginal'] as bool? ?? true,
        privacyAccepted: json['privacyAccepted'] as bool? ?? false,
        backendId: backendId,
        credentials: credentials,
      );
    }
    return LocalizationConfig._fromLegacy(json, credentials);
  }

  /// Reads the single-endpoint shape written before the vendor catalog.
  factory LocalizationConfig._fromLegacy(
    Map<String, dynamic> json,
    Map<String, ProviderCredential> credentials,
  ) {
    final engine = json['engine'] as String?;
    final enabled = json['enabled'] as bool? ?? true;
    final showOriginal = json['showOriginal'] as bool? ?? true;
    final privacyAccepted = json['privacyAccepted'] as bool? ?? false;
    if (engine == 'openAiCompatible') {
      final baseUrl = json['apiBaseUrl'] as String? ?? '';
      final apiKey = json['apiKey'] as String? ?? '';
      final model = json['apiModel'] as String? ?? '';
      final next = Map<String, ProviderCredential>.unmodifiable({
        ...credentials,
        customBackendId: ProviderCredential(
          apiKey: apiKey,
          model: model,
          baseUrl: baseUrl,
        ),
      });
      return LocalizationConfig(
        enabled: enabled,
        showOriginal: showOriginal,
        privacyAccepted: privacyAccepted,
        backendId: customBackendId,
        credentials: next,
      );
    }
    if (engine == 'local') {
      return LocalizationConfig(
        enabled: enabled,
        showOriginal: showOriginal,
        privacyAccepted: privacyAccepted,
        backendId: localBackendId,
        credentials: credentials,
      );
    }
    return LocalizationConfig(
      enabled: enabled,
      showOriginal: showOriginal,
      privacyAccepted: privacyAccepted,
      credentials: credentials,
    );
  }

  static Map<String, ProviderCredential> _readCredentials(Object? raw) {
    if (raw is! Map) return const {};
    final credentials = <String, ProviderCredential>{};
    raw.forEach((key, value) {
      if (key is String && value is Map) {
        credentials[key] = ProviderCredential.fromJson(
          Map<String, dynamic>.from(value),
        );
      }
    });
    return Map<String, ProviderCredential>.unmodifiable(credentials);
  }

  /// The settings as the preferences file keeps them.
  ///
  /// The keys are not part of this document: they are written to their own
  /// file by `TranslationKeyStore`. `fromJson` still reads an `apiKey` that an
  /// older build left here, so an upgrade keeps the keys it was given.
  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'showOriginal': showOriginal,
    'privacyAccepted': privacyAccepted,
    'backendId': backendId,
    'credentials': {
      for (final entry in credentials.entries)
        entry.key: {'model': entry.value.model, 'baseUrl': entry.value.baseUrl},
    },
  };

  @override
  bool operator ==(Object other) =>
      other is LocalizationConfig &&
      other.enabled == enabled &&
      other.showOriginal == showOriginal &&
      other.privacyAccepted == privacyAccepted &&
      other.backendId == backendId &&
      _sameCredentials(other.credentials, credentials);

  static bool _sameCredentials(
    Map<String, ProviderCredential> a,
    Map<String, ProviderCredential> b,
  ) {
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      if (b[entry.key] != entry.value) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
    enabled,
    showOriginal,
    privacyAccepted,
    backendId,
    Object.hashAllUnordered(
      credentials.entries.map((entry) => Object.hash(entry.key, entry.value)),
    ),
  );
}
