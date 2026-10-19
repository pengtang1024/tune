/// One user-editable variable declared by a plugin.
class MusicPluginUserVariable {
  final String key;
  final String title;
  final String defaultValue;

  const MusicPluginUserVariable({
    required this.key,
    this.title = '',
    this.defaultValue = '',
  });

  factory MusicPluginUserVariable.fromJson(Map<String, dynamic> json) {
    return MusicPluginUserVariable(
      key: json['key']?.toString().trim() ?? '',
      title: json['title']?.toString().trim() ?? '',
      defaultValue: json['default']?.toString() ?? '',
    );
  }
}

/// Metadata exported by a MusicFree-compatible plugin.
class MusicPluginMetadata {
  final String platform;
  final String version;
  final String author;
  final String description;
  final bool hasSearch;
  final bool hasMediaSource;
  final bool hasMusicInfo;
  final bool hasLyric;
  final List<MusicPluginUserVariable> userVariables;

  const MusicPluginMetadata({
    required this.platform,
    this.version = '0.0.0',
    this.author = '',
    this.description = '',
    this.hasSearch = false,
    this.hasMediaSource = false,
    this.hasMusicInfo = false,
    this.hasLyric = false,
    this.userVariables = const [],
  });

  bool get supportsScan => hasSearch;

  factory MusicPluginMetadata.fromJson(Map<String, dynamic> json) {
    return MusicPluginMetadata(
      platform: json['platform']?.toString().trim() ?? '',
      version: json['version']?.toString().trim() ?? '0.0.0',
      author: json['author']?.toString().trim() ?? '',
      description: json['description']?.toString().trim() ?? '',
      hasSearch: json['hasSearch'] == true,
      hasMediaSource: json['hasMediaSource'] == true,
      hasMusicInfo: json['hasMusicInfo'] == true,
      hasLyric: json['hasLyric'] == true,
      userVariables: json['userVariables'] is List
          ? [
                  for (final item in json['userVariables'] as List)
                    if (item is Map)
                      MusicPluginUserVariable.fromJson(
                        Map<String, dynamic>.from(item),
                      ),
                ]
                .where((variable) => variable.key.isNotEmpty)
                .toList(growable: false)
          : const [],
    );
  }

  bool get isValid => platform.isNotEmpty && supportsScan;
}

/// One loaded JavaScript plugin instance.
///
/// Implementations must serialize calls: a QuickJS instance cannot execute
/// two scripts at the same time.
abstract class MusicPluginRuntime {
  MusicPluginMetadata get metadata;

  Future<void> load(
    String script, {
    Map<String, String> userVariables = const {},
  });

  /// Calls `search(query, page, 'music')`.
  Future<List<Map<String, dynamic>>> search(String query, {int page = 1});

  /// Calls `getMediaSource(item, quality)`.
  Future<Map<String, dynamic>> getMediaSource(
    Map<String, dynamic> item, {
    String quality = 'standard',
  });

  /// Calls `getLyric(item)` when the plugin implements it.
  Future<Map<String, dynamic>?> getLyric(Map<String, dynamic> item);

  /// Calls `getMusicInfo(item)` when the plugin implements it.
  Future<Map<String, dynamic>?> getMusicInfo(Map<String, dynamic> item);

  Future<void> dispose();
}

class MusicPluginException implements Exception {
  final String message;

  const MusicPluginException(this.message);

  @override
  String toString() => message;
}
