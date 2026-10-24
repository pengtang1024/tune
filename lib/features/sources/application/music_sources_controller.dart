import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/core/l10n/app_strings.dart';
import 'package:tune/data/services/music_sources/music_source_store.dart';
import 'package:tune/data/services/music_sources/source_type_catalogue.dart';
import 'package:tune/data/services/providers/music_source_providers.dart';
import 'package:tune/domain/models/music_source.dart';
import 'package:tune/domain/models/source_scan_result.dart';
import 'package:tune/features/sources/domain/music_sources_state.dart';
import 'package:tune/features/sources/domain/source_scan_health.dart';
import 'package:tune/features/sources/domain/source_weights.dart';
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

    final loaded = _store.loadConfigs();
    final normalised = _normaliseWeights(loaded);
    if (normalised.changed) {
      await _save(normalised.sources);
    }

    final sources = normalised.sources;
    final healthHistory = _store.loadHealthHistory();
    final lastScanAt = <String, DateTime>{};
    for (final source in sources) {
      final scannedAt = _store.lastScanAt(source.id);
      if (scannedAt != null) lastScanAt[source.id] = scannedAt;
    }

    return MusicSourcesState(
      sources: sources,
      lastScanAt: Map.unmodifiable(lastScanAt),
      healthHistory: Map.unmodifiable(healthHistory),
    );
  }

  /// Gives every source an explicit weight and puts the list in weight order.
  ///
  /// A configuration written before the weight existed has no number; it
  /// receives the default of its group. The local music is always pinned at
  /// [SourceWeights.local]. The result is saved once, so the next start reads
  /// the same order without touching the file.
  ({List<MusicSourceConfig> sources, bool changed}) _normaliseWeights(
    List<MusicSourceConfig> loaded,
  ) {
    final used = <int>{};
    final order = {
      for (var index = 0; index < loaded.length; index++)
        loaded[index].id: index,
    };
    final result = <MusicSourceConfig>[];
    var changed = false;

    for (final source in loaded) {
      var weight = source.weight;
      if (source.isLocal) {
        if (weight != SourceWeights.local) {
          weight = SourceWeights.local;
          changed = true;
        }
      } else {
        final valid =
            weight != null &&
            weight >= 0 &&
            weight < SourceWeights.local &&
            !used.contains(weight);
        if (!valid) {
          weight = _freeWeight(_defaultWeight(source), used);
          changed = true;
        }
      }

      used.add(weight!);
      result.add(
        weight == source.weight ? source : source.copyWith(weight: weight),
      );
    }

    result.sort((left, right) {
      final byWeight = (right.weight ?? 0).compareTo(left.weight ?? 0);
      if (byWeight != 0) return byWeight;
      return (order[left.id] ?? 0).compareTo(order[right.id] ?? 0);
    });

    return (
      sources: List<MusicSourceConfig>.unmodifiable(result),
      changed: changed,
    );
  }

  int _defaultWeight(MusicSourceConfig source) {
    if (!source.builtIn) return SourceWeights.added;
    return ref.read(musicSourceServiceProvider).isFeatured(source)
        ? SourceWeights.featured
        : SourceWeights.more;
  }

  /// A free weight at or below [base], so two sources never share a value.
  int _freeWeight(int base, Set<int> used) {
    var candidate = base.clamp(0, SourceWeights.local - 1);
    while (used.contains(candidate)) {
      candidate--;
      if (candidate < 0) {
        candidate = SourceWeights.local - 1;
        while (used.contains(candidate)) {
          candidate--;
        }
      }
    }
    return candidate;
  }

  /// Puts the list in weight order and saves it.
  Future<void> _saveOrdered(List<MusicSourceConfig> sources) async {
    final order = {
      for (var index = 0; index < sources.length; index++)
        sources[index].id: index,
    };
    final ordered = [...sources]
      ..sort((left, right) {
        final byWeight = (right.weight ?? 0).compareTo(left.weight ?? 0);
        if (byWeight != 0) return byWeight;
        return (order[left.id] ?? 0).compareTo(order[right.id] ?? 0);
      });
    final unmodifiable = List<MusicSourceConfig>.unmodifiable(ordered);
    state = AsyncData(_current.copyWith(sources: unmodifiable));
    await _save(unmodifiable);
  }

  /// Trades the weights of two sources.
  ///
  /// The caller passes the two sources that are adjacent in the list the
  /// reader sees, not the two adjacent in storage: health bands decide the
  /// coarse order, so the visible neighbours are not always the raw-weight
  /// neighbours. A pair that sits on different sides of the More boundary is
  /// left alone; use [setSourceInMore] for that move.
  Future<void> swapSources(String firstId, String secondId) async {
    if (_disposed || !state.hasValue || firstId == secondId) return;

    final sources = [..._current.sources];
    final firstIndex = sources.indexWhere((source) => source.id == firstId);
    final secondIndex = sources.indexWhere((source) => source.id == secondId);
    if (firstIndex < 0 || secondIndex < 0) return;

    final first = sources[firstIndex];
    final second = sources[secondIndex];
    if (first.isLocal || second.isLocal) return;

    final firstWeight = first.weight ?? _defaultWeight(first);
    final secondWeight = second.weight ?? _defaultWeight(second);
    if (SourceWeights.inMore(firstWeight) !=
        SourceWeights.inMore(secondWeight)) {
      return;
    }

    sources[firstIndex] = first.copyWith(weight: secondWeight);
    sources[secondIndex] = second.copyWith(weight: firstWeight);
    await _saveOrdered(sources);
  }

  /// Keeps the last scan outcomes and the last success times in sync.
  ///
  /// The library controller calls this after a scan. The source page reads
  /// the history for the stability dimension; the last success time is the
  /// same value the store uses, so a restart does not need a scan first.
  Future<void> recordScanResults(List<SourceScanResult> results) async {
    if (_disposed || !state.hasValue) return;

    final history = {..._current.healthHistory};
    final lastScanAt = {..._current.lastScanAt};
    for (final result in results) {
      final previous =
          history[result.sourceId] ?? const SourceScanHealthHistory();
      history[result.sourceId] = previous.append(
        SourceScanHealthRecord.fromResult(result),
      );
      if (result.isSuccess) {
        lastScanAt[result.sourceId] = result.scannedAt;
      }
    }

    state = AsyncData(
      _current.copyWith(
        lastScanAt: Map.unmodifiable(lastScanAt),
        healthHistory: Map.unmodifiable(history),
      ),
    );
    try {
      await _store.saveHealthHistory(history);
    } catch (error, stackTrace) {
      Log.error('保存音源健康历史失败: $error\n$stackTrace');
    }
  }

  /// Folds a source into the More group, or brings it back to the main list.
  Future<void> setSourceInMore(String sourceId, bool inMore) async {
    if (_disposed || !state.hasValue) return;

    final sources = [..._current.sources];
    final index = sources.indexWhere((source) => source.id == sourceId);
    if (index < 0 || sources[index].isLocal) return;

    final source = sources[index];
    final weight = source.weight ?? _defaultWeight(source);
    if (SourceWeights.inMore(weight) == inMore) return;

    final used = {
      for (final item in sources)
        if (item.weight != null) item.weight!,
    };
    var target = inMore
        ? SourceWeights.mainThreshold - 1
        : SourceWeights.mainThreshold + 1;
    while (used.contains(target)) {
      target += inMore ? -1 : 1;
    }

    sources[index] = source.copyWith(weight: target);
    await _saveOrdered(sources);
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

    final used = {
      for (final source in _current.sources)
        if (source.weight != null) source.weight!,
    };
    var weight = SourceWeights.added;
    while (used.contains(weight)) {
      weight--;
    }

    final config = MusicSourceConfig(
      id: instance.id,
      type: type,
      name: instance.name,
      kind: descriptor.kind,
      enabled: true,
      settings: Map.unmodifiable(settings),
      weight: weight,
    );

    await _saveOrdered([..._current.sources, config]);
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
