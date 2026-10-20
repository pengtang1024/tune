import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/data/services/music_sources/built_in_music_sources.dart';
import 'package:tune/data/services/music_sources/music_source_store.dart';
import 'package:tune/data/services/providers/music_source_providers.dart';
import 'package:tune/domain/models/music_source.dart';
import 'package:tune/features/sources/domain/music_sources_state.dart';
import 'package:tune/l10n/app_localizations.dart';
import 'package:tune/utils/logger.dart';

final musicSourcesControllerProvider =
    AsyncNotifierProvider<MusicSourcesController, MusicSourcesState>(
      MusicSourcesController.new,
    );

/// The sources of the app, named in the language the app renders in.
///
/// A built-in source is named by the catalogue, so picking another language
/// renames it; a source the user imported keeps the name it was given.
///
/// The translations are read from the caller, so the names are written in the
/// language the interface draws in.
List<MusicSourceConfig> localizedSources(
  AppLocalizations strings,
  List<MusicSourceConfig> sources,
) {
  final catalogue = BuiltInMusicSources.catalogueOf(strings);
  return sources
      .map((source) {
        final entry = catalogue[source.sourceType];
        if (entry == null) return source;
        return source.copyWith(
          name: entry.name,
          localizedName: entry.localizedName,
          description: entry.description,
        );
      })
      .toList(growable: false);
}

/// Label of every configured source, keyed by source id.
///
/// Track lists resolve the label of the source a track came from through this
/// map, so the same source is never named differently in two places. The
/// name is the name the source writes itself with; the localized name is what
/// the source is called in the language the interface draws in.
Map<String, SourceLabel> sourceLabelsOf(
  AppLocalizations strings,
  List<MusicSourceConfig> sources,
) {
  final catalogue = BuiltInMusicSources.catalogueOf(strings);
  return {
    for (final source in sources)
      source.id: SourceLabel(
        name: catalogue[source.sourceType]?.name ?? source.name,
        localizedName: catalogue[source.sourceType]?.localizedName ?? '',
        type: source.sourceType,
        kind: source.kind,
      ),
  };
}

/// Owns the user-facing source list (enable flags and adapter settings).
///
/// Scanned songs belong to the library controller; this controller never
/// triggers scans itself, so source configuration has a single owner.
class MusicSourcesController extends AsyncNotifier<MusicSourcesState> {
  late MusicSourceStore _store;
  bool _disposed = false;

  @override
  Future<MusicSourcesState> build() async {
    _disposed = false;
    _store = ref.read(musicSourceStoreProvider);
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
