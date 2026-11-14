import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/core/config/app_capabilities.dart';
import 'package:tune/data/services/components/local_component.dart';
import 'package:tune/data/services/components/local_component_registry.dart';
import 'package:tune/data/services/components/local_components.dart';
import 'package:tune/data/services/providers/local_components_provider.dart';
import 'package:tune/utils/logger.dart';

/// The install state of every local component, keyed by id.
///
/// The one place a download runs and the one place the page reads from: the
/// translation card, the lyrics card and the components card all watch this
/// map instead of keeping their own flags (docs/local-components.md §5).
final localComponentsControllerProvider =
    AsyncNotifierProvider<
      LocalComponentsController,
      Map<String, LocalComponentState>
    >(LocalComponentsController.new);

class LocalComponentsController
    extends AsyncNotifier<Map<String, LocalComponentState>> {
  final Map<String, CancelToken> _cancels = {};

  @override
  Future<Map<String, LocalComponentState>> build() async {
    final components = await ref.watch(localComponentsProvider.future);
    ref.onDispose(() {
      for (final token in _cancels.values) {
        token.cancel();
      }
    });
    return _inspectAll(components);
  }

  Future<Map<String, LocalComponentState>> _inspectAll(
    LocalComponents components,
  ) async {
    final states = <String, LocalComponentState>{};
    final platform = AppCapabilities.current.platform;
    for (final spec in LocalComponentRegistry.all) {
      // A desktop binary is not offered on a phone it could never run on.
      if (!spec.supports(platform)) continue;
      states[spec.id] = await _inspect(spec, components);
    }
    return states;
  }

  Future<LocalComponentState> _inspect(
    LocalComponentSpec spec,
    LocalComponents components,
  ) async {
    final system = await components.systemAvailable(spec);
    final installed = await components.installer.inspect(spec);
    if (installed.installed) {
      return LocalComponentState(
        LocalComponentPhase.ready,
        installedBytes: installed.bytes,
        systemAvailable: system,
        canDelete: true,
      );
    }
    return LocalComponentState(
      LocalComponentPhase.notInstalled,
      systemAvailable: system,
    );
  }

  /// Re-reads every component from disk.
  Future<void> refresh() async {
    final components = await ref.read(localComponentsProvider.future);
    state = AsyncData(await _inspectAll(components));
  }

  /// Downloads one component, replacing the copy in place when it succeeds.
  Future<void> download(String id) async {
    final spec = LocalComponentRegistry.byId(id);
    final components = await ref.read(localComponentsProvider.future);
    final before = state.valueOrNull?[id];
    if (before != null && before.busy) return;

    final token = CancelToken();
    _cancels[id] = token;
    _put(
      id,
      LocalComponentState(
        LocalComponentPhase.downloading,
        total: spec.totalBytes,
        systemAvailable: before?.systemAvailable ?? false,
      ),
    );

    try {
      await components.installer.install(
        spec,
        cancelToken: token,
        onProgress: (received, total) {
          final current = state.valueOrNull?[id];
          if (current == null ||
              current.phase != LocalComponentPhase.downloading) {
            return;
          }
          _put(id, current.copyWith(received: received, total: total));
        },
      );
      _put(
        id,
        LocalComponentState(
          LocalComponentPhase.verifying,
          total: spec.totalBytes,
          systemAvailable: before?.systemAvailable ?? false,
        ),
      );
      await _refreshOne(spec, components);
      ref.read(localComponentsRevisionProvider.notifier).state++;
    } on DioException catch (error) {
      if (CancelToken.isCancel(error)) {
        await _refreshOne(spec, components);
      } else {
        Log.error('组件下载失败($id): ${error.message}');
        _put(
          id,
          LocalComponentState(
            LocalComponentPhase.failed,
            message: error.message,
            systemAvailable: before?.systemAvailable ?? false,
          ),
        );
      }
    } catch (error, stackTrace) {
      Log.error('组件安装失败($id): $error', stackTrace);
      _put(
        id,
        LocalComponentState(
          LocalComponentPhase.failed,
          message: '$error',
          systemAvailable: before?.systemAvailable ?? false,
        ),
      );
    } finally {
      _cancels.remove(id);
    }
  }

  /// Stops a running download; the staging folder is dropped and the old
  /// copy, if any, stays.
  void cancel(String id) {
    _cancels[id]?.cancel();
  }

  /// Deletes the downloaded copy. A system or legacy copy is not touched.
  Future<void> remove(String id) async {
    final spec = LocalComponentRegistry.byId(id);
    final components = await ref.read(localComponentsProvider.future);
    final before = state.valueOrNull?[id];
    if (before == null || before.busy || !before.canDelete) return;
    try {
      await components.installer.remove(spec);
      await _refreshOne(spec, components);
      ref.read(localComponentsRevisionProvider.notifier).state++;
    } catch (error, stackTrace) {
      Log.error('组件删除失败($id): $error', stackTrace);
      _put(
        id,
        LocalComponentState(
          LocalComponentPhase.failed,
          message: '$error',
          systemAvailable: before.systemAvailable,
        ),
      );
    }
  }

  Future<void> _refreshOne(
    LocalComponentSpec spec,
    LocalComponents components,
  ) async {
    _put(spec.id, await _inspect(spec, components));
  }

  void _put(String id, LocalComponentState value) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData({...current, id: value});
  }
}

/// The state of one component, or a checking placeholder while the first
/// scan runs.
final localComponentStateProvider =
    Provider.family<LocalComponentState, String>((ref, id) {
      final states = ref.watch(localComponentsControllerProvider);
      return states.valueOrNull?[id] ??
          const LocalComponentState(LocalComponentPhase.checking);
    });

/// The translation model the reader is actually using: the first tier that
/// is usable, default first. A card reports this one, so downloading the
/// low-memory tier instead of the default does not look like a missing model.
final activeTranslationModelProvider = Provider<LocalComponentSpec>((ref) {
  final states = ref.watch(localComponentsControllerProvider).valueOrNull;
  for (final spec in LocalComponentRegistry.translationModels) {
    if (states?[spec.id]?.usable ?? false) return spec;
  }
  return LocalComponentRegistry.translationModel;
});
