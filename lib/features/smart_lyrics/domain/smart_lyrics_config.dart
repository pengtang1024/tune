/// The endpoint templates the reader picks the pipeline's voice from.
///
/// Every preset is a place that speaks the OpenAI dialect; the names of its
/// models are defaults the reader can change in the advanced fold. The
/// brands travel as their own names in every language.
class SmartLyricsPreset {
  final String id;
  final String baseUrl;
  final List<String> asrModels;
  final String chatModel;

  const SmartLyricsPreset({
    required this.id,
    required this.baseUrl,
    required this.asrModels,
    required this.chatModel,
  });

  static const String openaiId = 'openai';
  static const String groqId = 'groq';
  static const String customId = 'custom';
  static const String _openaiBaseUrl = 'https://api.openai.com/v1';

  static const SmartLyricsPreset openai = SmartLyricsPreset(
    id: openaiId,
    baseUrl: _openaiBaseUrl,
    asrModels: ['whisper-1'],
    chatModel: 'gpt-4o-mini',
  );

  static const SmartLyricsPreset groq = SmartLyricsPreset(
    id: groqId,
    baseUrl: 'https://api.groq.com/openai/v1',
    asrModels: ['whisper-large-v3'],
    chatModel: 'llama-3.3-70b-versatile',
  );

  /// The reader's own endpoint: everything waits for what they type.
  static const SmartLyricsPreset custom = SmartLyricsPreset(
    id: customId,
    baseUrl: '',
    asrModels: [],
    chatModel: '',
  );

  static const List<SmartLyricsPreset> all = [openai, groq, custom];

  /// The preset of [id]; an id nothing knows is the reader's own.
  static SmartLyricsPreset byId(String id) => all.firstWhere(
    (preset) => preset.id == id,
    orElse: () => custom,
  );
}

/// What the reader pasted for the smart pipeline.
///
/// The app holds no key of its own: the fields stand prefilled with the
/// default template, so the one move left is pasting a key. The key sits in
/// the preferences like the credentials of the music sources do — same
/// machine, same treatment (docs/smart-lyrics.md §8).
class SmartLyricsConfig {
  final String presetId;
  final String baseUrl;
  final String apiKey;
  final List<String> asrModels;

  /// The text model the correction, the knowledge vote and the translation
  /// run on — the same endpoint, one more name.
  final String chatModel;

  /// The whisper model the local channel votes with — `''` when the local
  /// channel is off (docs/smart-lyrics.md §6.2).
  final String localModel;

  /// How many cloud songs one batch run may spend before it pauses itself
  /// (docs/smart-lyrics.md §7.2); `0` lets the run go without a cap.
  final int batchCloudBudget;

  const SmartLyricsConfig({
    this.presetId = SmartLyricsPreset.openaiId,
    this.baseUrl = SmartLyricsPreset._openaiBaseUrl,
    this.apiKey = '',
    this.asrModels = const ['whisper-1'],
    this.chatModel = 'gpt-4o-mini',
    this.localModel = '',
    this.batchCloudBudget = 500,
  });

  /// Whether the pipeline has a place to go and a key to knock with.
  ///
  /// A custom endpoint with no address waits for one, however loud the key.
  bool get isConfigured =>
      apiKey.trim().isNotEmpty &&
      baseUrl.trim().isNotEmpty &&
      asrModels.isNotEmpty;

  SmartLyricsConfig copyWith({
    String? presetId,
    String? baseUrl,
    String? apiKey,
    List<String>? asrModels,
    String? chatModel,
    String? localModel,
    int? batchCloudBudget,
  }) => SmartLyricsConfig(
    presetId: presetId ?? this.presetId,
    baseUrl: baseUrl ?? this.baseUrl,
    apiKey: apiKey ?? this.apiKey,
    asrModels: asrModels ?? this.asrModels,
    chatModel: chatModel ?? this.chatModel,
    localModel: localModel ?? this.localModel,
    batchCloudBudget: batchCloudBudget ?? this.batchCloudBudget,
  );

  Map<String, dynamic> toJson() => {
    'presetId': presetId,
    'baseUrl': baseUrl,
    'apiKey': apiKey,
    'asrModels': asrModels,
    'chatModel': chatModel,
    'localModel': localModel,
    'batchCloudBudget': batchCloudBudget,
  };

  /// Reads the config back; a broken field falls to the default of that
  /// field, so one bad paste cannot take the pipeline down with it.
  factory SmartLyricsConfig.fromJson(Map<String, dynamic> json) {
    final fallback = SmartLyricsConfig();
    final models = json['asrModels'];
    return SmartLyricsConfig(
      presetId: json['presetId'] is String
          ? json['presetId'] as String
          : fallback.presetId,
      baseUrl: json['baseUrl'] is String
          ? json['baseUrl'] as String
          : fallback.baseUrl,
      apiKey: json['apiKey'] is String ? json['apiKey'] as String : '',
      asrModels: models is List && models.every((model) => model is String)
          ? List<String>.from(models)
          : fallback.asrModels,
      chatModel: json['chatModel'] is String
          ? json['chatModel'] as String
          : fallback.chatModel,
      localModel: json['localModel'] is String
          ? json['localModel'] as String
          : fallback.localModel,
      batchCloudBudget: json['batchCloudBudget'] is int
          ? json['batchCloudBudget'] as int
          : fallback.batchCloudBudget,
    );
  }
}
