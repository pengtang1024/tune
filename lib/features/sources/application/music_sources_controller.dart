import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/core/l10n/app_strings.dart';
import 'package:tune/data/services/music_sources/music_source_store.dart';
import 'package:tune/data/services/music_sources/plugins/music_plugin_repository.dart';
import 'package:tune/data/services/music_sources/plugins/music_plugin_runtime.dart';
import 'package:tune/data/services/providers/music_source_providers.dart';
import 'package:tune/domain/models/music_source.dart';
import 'package:tune/features/sources/domain/music_sources_state.dart';
import 'package:tune/utils/logger.dart';

final musicSourcesControllerProvider =
    AsyncNotifierProvider<MusicSourcesController, MusicSourcesState>(
      MusicSourcesController.new,
    );

/// Display names of every configured source, keyed by source id.
///
/// Track lists resolve the name of the source a track came from through this
/// map, so the same source is never named differently in two places.
final musicSourceNamesProvider = Provider<Map<String, String>>((ref) {
  final sources = ref.watch(
    musicSourcesControllerProvider.select(
      (value) => value.valueOrNull?.sources ?? const <MusicSourceConfig>[],
    ),
  );
  return {for (final source in sources) source.id: source.name};
});

/// Owns the user-facing source list (enable flags and adapter settings).
///
/// Scanned songs belong to the library controller; this controller never
/// triggers scans itself, so source configuration has a single owner.
class MusicSourcesController extends AsyncNotifier<MusicSourcesState> {
  late MusicSourceStore _store;
  late MusicPluginRepository _plugins;
  bool _disposed = false;

  @override
  Future<MusicSourcesState> build() async {
    _disposed = false;
    _store = ref.read(musicSourceStoreProvider);
    _plugins = ref.read(musicPluginRepositoryProvider);
    ref.onDispose(() => _disposed = true);

    final sources = _store.loadConfigs();
    final lastScanAt = <String, DateTime>{};
    for (final source in sources) {
      final scannedAt = _store.lastScanAt(source.id);
      if (scannedAt != null) lastScanAt[source.id] = scannedAt;
    }

    return MusicSourcesState(
      sources: sources,
      lastScanAt: Map.unmodifiable(lastScanAt),
    );
  }

  MusicSourcesState get _current =>
      state.valueOrNull ?? const MusicSourcesState();

  Future<void> setEnabled(String sourceId, bool enabled) {
    return _update(sourceId, (config) => config.copyWith(enabled: enabled));
  }

  Future<void> updateSettings(String sourceId, Map<String, String> settings) {
    return _update(
      sourceId,
      (config) => config.copyWith(
        settings: Map.unmodifiable({...config.settings, ...settings}),
      ),
    );
  }

  /// Imports a MusicFree plugin script and adds it disabled, so the caller can
  /// ask for a search keyword before the plugin joins a scan.
  Future<MusicSourceConfig> installPlugin({
    required String originalName,
    required String script,
  }) async {
    return _install(
      () => _plugins.install(originalName: originalName, script: script),
    );
  }

  /// Downloads a plugin from [url] and adds it to the source list.
  ///
  /// The address is remembered, so the plugin can be updated later.
  Future<MusicSourceConfig> installPluginFromUrl(String url) async {
    return _install(() => _plugins.installFromUrl(url));
  }

  /// Replaces the script of a plugin with the current one from its URL.
  Future<MusicPluginUpdate> updatePlugin(String sourceId) async {
    if (_disposed || !state.hasValue) {
      throw MusicPluginException(AppStrings.instance.sourcesNotLoaded);
    }
    final config = _current.byId(sourceId);
    if (config == null || !config.isPlugin) {
      throw MusicPluginException(AppStrings.instance.pluginUpdateNoUrl);
    }
    return _plugins.update(config);
  }

  Future<MusicSourceConfig> _install(
    Future<MusicSourceConfig> Function() install,
  ) async {
    if (_disposed || !state.hasValue) {
      throw MusicPluginException(AppStrings.instance.sourcesNotLoaded);
    }
    if (!_plugins.supportsPlugins) {
      throw MusicPluginException(AppStrings.instance.sourcesPlatformNoPlugin);
    }

    final config = await install();

    final existing = _current.byId(config.id);
    final next = [
      for (final source in _current.sources)
        if (source.id != config.id) source,
      if (existing == null)
        config
      else
        config.copyWith(
          enabled: existing.enabled,
          settings: Map.unmodifiable({
            ...config.settings,
            ...existing.settings,
          }),
        ),
    ];

    final updated = List<MusicSourceConfig>.unmodifiable(next);
    state = AsyncData(_current.copyWith(sources: updated));
    await _save(updated);
    return _current.byId(config.id) ?? config;
  }

  Future<void> removePlugin(String sourceId) async {
    if (_disposed || !state.hasValue) return;
    final config = _current.byId(sourceId);
    if (config == null || !config.isPlugin) return;

    final updated = List<MusicSourceConfig>.unmodifiable(
      _current.sources.where((source) => source.id != sourceId),
    );
    state = AsyncData(_current.copyWith(sources: updated));
    await _save(updated);
    await _plugins.remove(config);
  }

  Future<void> _save(List<MusicSourceConfig> sources) async {
    try {
      await _store.saveConfigs(sources);
    } catch (error, stackTrace) {
      Log.error('保存音源配置失败: $error\n$stackTrace');
    }
  }

  Future<void> _update(
    String sourceId,
    MusicSourceConfig Function(MusicSourceConfig config) transform,
  ) async {
    if (_disposed || !state.hasValue) return;

    var changed = false;
    final next = _current.sources
        .map((config) {
          if (config.id != sourceId) return config;
          changed = true;
          return transform(config);
        })
        .toList(growable: false);

    if (!changed) return;

    final updated = List<MusicSourceConfig>.unmodifiable(next);
    state = AsyncData(_current.copyWith(sources: updated));
    await _save(updated);
  }
}
