import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/core/l10n/app_strings.dart';
import 'package:tune/data/services/music_sources/music_source_store.dart';
import 'package:tune/data/services/music_sources/source_type_catalogue.dart';
import 'package:tune/data/services/providers/music_source_providers.dart';
import 'package:tune/domain/models/music_source.dart';
import 'package:tune/domain/models/source_scan_result.dart';
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
  final catalogue = SourceTypeCatalogue.byType(strings);
  return sources
      .map((source) {
        final entry = catalogue[source.sourceType];
        if (entry == null) return source;
        // A built-in source is named by the catalogue, so the reader meets it
        // in their own language. A source the reader added keeps the name
        // they gave it: two instances of one type are told apart by it.
        return source.copyWith(
          name: source.builtIn ? entry.name : source.name,
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
  final catalogue = SourceTypeCatalogue.byType(strings);
  return {
    for (final source in sources)
      source.id: SourceLabel(
        // The name of a built-in source is the name of its type; a source the
        // reader added keeps the name they gave it.
        name: source.builtIn
            ? (catalogue[source.sourceType]?.name ?? source.name)
            : source.name,
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

  /// Saves what the reader filled into the form of an instance.
  ///
  /// The name is only written when the form shows it: a built-in source is
  /// named by its type, so its name is not the reader's to change.
  Future<void> updateSettings(
    String sourceId,
    Map<String, String> settings, {
    String? name,
  }) {
    return _update(
      sourceId,
      (config) => config.copyWith(
        name: name ?? config.name,
        settings: Map.unmodifiable({...config.settings, ...settings}),
      ),
    );
  }

  /// Adds an instance of a type the reader picked.
  ///
  /// The instance gets the next free id of its type and is enabled right
  /// away: the reader asked for it, so it should work.
  Future<void> addInstance({
    required String type,
    required String name,
    required Map<String, String> settings,
  }) async {
    if (_disposed || !state.hasValue) return;

    final descriptor = SourceTypeCatalogue.byType(AppStrings.instance)[type];
    if (descriptor == null) return;

    final instance = newSourceInstance(
      type: type,
      typeName: descriptor.name,
      name: name,
      sources: _current.sources,
    );

    final config = MusicSourceConfig(
      id: instance.id,
      type: type,
      name: instance.name,
      kind: descriptor.kind,
      enabled: true,
      settings: Map.unmodifiable(settings),
    );

    final updated = List<MusicSourceConfig>.unmodifiable([
      ..._current.sources,
      config,
    ]);
    state = AsyncData(_current.copyWith(sources: updated));
    await _save(updated);
  }

  /// Asks the type of a configuration what it would make of it.
  ///
  /// The reader tries a mapping out before it keeps it: the interface is
  /// asked once, nothing is saved and no track is added.
  Future<SourcePreview?> previewMapping(MusicSourceConfig config) async {
    if (_disposed) return null;

    final service = ref.read(musicSourceServiceProvider);
    return service.preview(config);
  }

  /// Removes an instance the reader added.
  ///
  /// A built-in instance is never removed: it came with the app, so it can be
  /// switched off but not deleted.
  Future<void> removeInstance(String sourceId) async {
    if (_disposed || !state.hasValue) return;

    final current = _current.sources;
    final matching = current.where((config) => config.id == sourceId);
    if (matching.isEmpty || matching.first.builtIn) return;

    final updated = List<MusicSourceConfig>.unmodifiable(
      current.where((config) => config.id != sourceId),
    );
    state = AsyncData(_current.copyWith(sources: updated));
    await _save(updated);
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
