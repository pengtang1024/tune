import 'dart:convert';

import 'package:tune/core/l10n/app_strings.dart';
import 'package:tune/data/services/music_sources/plugins/music_plugin_downloader.dart';
import 'package:tune/data/services/music_sources/plugins/music_plugin_runtime.dart';
import 'package:tune/data/services/music_sources/plugins/music_plugin_runtime_factory.dart';
import 'package:tune/data/services/music_sources/plugins/music_plugin_source_adapter.dart';
import 'package:tune/data/services/music_sources/plugins/music_plugin_store.dart';
import 'package:tune/data/services/music_sources/source_song_factory.dart';
import 'package:tune/domain/models/music_source.dart';
import 'package:tune/utils/logger.dart';

class _CachedPluginAdapter {
  final String path;
  final DateTime modified;
  final String signature;
  final MusicPluginSourceAdapter adapter;

  const _CachedPluginAdapter({
    required this.path,
    required this.modified,
    required this.signature,
    required this.adapter,
  });
}

/// Outcome of a plugin update.
class MusicPluginUpdate {
  /// Whether the script behind the source changed.
  final bool changed;

  /// Version of the plugin after the update.
  final String version;

  const MusicPluginUpdate({required this.changed, required this.version});
}

/// Loads imported MusicFree plugins and keeps one runtime per script.
class MusicPluginRepository {
  final MusicPluginStore _store;
  final MusicPluginDownloader _downloader;
  final Future<MusicPluginRuntime> Function() _runtimeFactory;
  final Map<String, _CachedPluginAdapter> _adapters = {};
  bool _disposed = false;

  MusicPluginRepository({
    MusicPluginStore? store,
    MusicPluginDownloader? downloader,
    Future<MusicPluginRuntime> Function()? runtimeFactory,
  }) : _store = store ?? MusicPluginStore(),
       _downloader = downloader ?? MusicPluginDownloader(),
       _runtimeFactory = runtimeFactory ?? createMusicPluginRuntime;

  bool get supportsPlugins => isMusicPluginRuntimeSupported;

  static final _queryField = MusicSourceField(
    'query',
    AppStrings.instance.pluginFieldQuery,
    AppStrings.instance.pluginFieldHint,
    required: true,
  );

  List<MusicSourceField> fieldsFor(MusicSourceConfig config) => [
    _queryField,
    ...config.customFields,
  ];

  bool isConfigured(MusicSourceConfig config) {
    return config.isPlugin &&
        config.setting('query') != null &&
        config.pluginFile != null;
  }

  /// Loads a plugin only to read its metadata. Used by the import flow.
  Future<MusicPluginMetadata> inspect(String script) async {
    final runtime = await _runtimeFactory();
    try {
      await runtime.load(script);
      return runtime.metadata;
    } finally {
      await runtime.dispose();
    }
  }

  /// Copies a plugin script into app storage and returns its source config.
  ///
  /// The returned config starts disabled; the UI asks for a search keyword
  /// before enabling it so an unconfigured plugin never joins a scan.
  ///
  /// [originUrl] is remembered when the script came from the network, so the
  /// plugin can be updated later without asking for the link again.
  Future<MusicSourceConfig> install({
    required String originalName,
    required String script,
    String? originUrl,
  }) async {
    final metadata = await inspect(script);
    final id =
        'plugin_${SourceSongFactory.stableId('$originalName:$script').toRadixString(16)}';
    final fileName = await _store.write(id, script);

    return MusicSourceConfig(
      id: id,
      name: metadata.platform,
      description: metadata.description.isEmpty
          ? AppStrings.instance.pluginImportedVersion(metadata.version)
          : metadata.description,
      kind: MusicSourceKind.plugin,
      enabled: false,
      settings: {
        'pluginFile': fileName,
        'query': '',
        'pluginUrl': ?originUrl,
        for (final variable in metadata.userVariables)
          variable.key: variable.defaultValue,
      },
      customFields: [
        for (final variable in metadata.userVariables)
          MusicSourceField(
            variable.key,
            variable.title.isEmpty ? variable.key : variable.title,
            AppStrings.instance.pluginVariable(variable.key),
          ),
      ],
    );
  }

  /// Downloads a plugin from [url] and installs it.
  Future<MusicSourceConfig> installFromUrl(String url) async {
    final script = await _downloader.download(url);
    return install(
      originalName: MusicPluginDownloader.fileNameFor(url),
      script: script,
      originUrl: url.trim(),
    );
  }

  /// Replaces the script of [config] with the current one from its URL.
  ///
  /// The source keeps its id, so the songs that were scanned with the old
  /// script stay in the library.
  Future<MusicPluginUpdate> update(MusicSourceConfig config) async {
    final url = config.pluginUrl;
    if (url == null) {
      throw MusicPluginException(AppStrings.instance.pluginUpdateNoUrl);
    }

    final script = await _downloader.download(url);
    final current = await _store.read(config);
    if (current == script) {
      return MusicPluginUpdate(changed: false, version: config.name);
    }

    await _store.writeScript(config, script);
    final cached = _adapters.remove(config.id);
    await cached?.adapter.runtime.dispose();

    final metadata = await inspect(script);
    return MusicPluginUpdate(changed: true, version: metadata.version);
  }

  Future<MusicPluginSourceAdapter> adapterFor(MusicSourceConfig config) async {
    final file = await _store.fileFor(config);
    if (file == null || !await file.exists()) {
      throw StateError(AppStrings.instance.pluginFileMissing);
    }

    final modified = await file.lastModified();
    final userVariables = {
      for (final field in config.customFields)
        field.key: config.setting(field.key) ?? '',
    };
    final signature = jsonEncode(userVariables);
    final cached = _adapters[config.id];
    final reusable =
        cached != null &&
        cached.path == file.path &&
        cached.modified == modified &&
        cached.signature == signature &&
        cached.adapter.runtime.isUsable;
    if (reusable) {
      return cached.adapter;
    }

    if (cached != null) {
      await cached.adapter.runtime.dispose();
      _adapters.remove(config.id);
    }

    final script = await file.readAsString();
    final runtime = await _runtimeFactory();
    try {
      await runtime.load(script, userVariables: userVariables);
      final adapter = MusicPluginSourceAdapter(
        config: config,
        runtime: runtime,
      );
      _adapters[config.id] = _CachedPluginAdapter(
        path: file.path,
        modified: modified,
        signature: signature,
        adapter: adapter,
      );
      return adapter;
    } catch (_) {
      await runtime.dispose();
      rethrow;
    }
  }

  Future<void> remove(MusicSourceConfig config) async {
    final cached = _adapters.remove(config.id);
    await cached?.adapter.runtime.dispose();
    await _store.delete(config);
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    for (final cached in _adapters.values) {
      try {
        await cached.adapter.runtime.dispose();
      } catch (error, stackTrace) {
        Log.error('释放插件运行时失败: $error\n$stackTrace');
      }
    }
    _adapters.clear();
  }
}
