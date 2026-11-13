import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/data/services/components/local_component.dart';
import 'package:tune/data/services/components/local_component_registry.dart';
import 'package:tune/data/services/components/local_components.dart';
import 'package:tune/data/services/providers/local_components_provider.dart';
import 'package:tune/features/local_components/application/local_components_controller.dart';

import '../../services/fake_http_adapter.dart';

/// The one state owner of every component (docs/local-components.md §5): the
/// settings cards read it, the download runs here, and nothing keeps a second
/// copy of "is it installed".
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory root;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('tune_components_state');
  });

  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  ProviderContainer containerWith(FakeHttpAdapter adapter) {
    final container = ProviderContainer(
      overrides: [
        localComponentsProvider.overrideWith(
          (ref) async => LocalComponents(
            supportDirectory: root,
            environment: {'PATH': '', 'HOME': root.path},
            dio: Dio(BaseOptions(responseType: ResponseType.plain))
              ..httpClientAdapter = adapter,
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('the first scan lists every component as not installed', () async {
    final container = containerWith(FakeHttpAdapter());

    final states = await container.read(
      localComponentsControllerProvider.future,
    );

    expect(
      states.keys,
      containsAll(LocalComponentRegistry.all.map((spec) => spec.id)),
    );
    for (final state in states.values) {
      expect(state.phase, LocalComponentPhase.notInstalled);
      expect(state.canDelete, isFalse);
    }
  });

  test('a component answers a checking placeholder before the scan ends', () {
    final container = containerWith(FakeHttpAdapter());

    expect(
      container.read(localComponentStateProvider('ffmpeg')).phase,
      LocalComponentPhase.checking,
    );
  });

  test('a download that fails its check leaves the component failed', () async {
    // The fake answers filler bytes, so the pinned size and digest miss.
    final container = containerWith(FakeHttpAdapter());

    await container.read(localComponentsControllerProvider.future);
    await container
        .read(localComponentsControllerProvider.notifier)
        .download('lyrics-whisper-model-tiny');

    expect(
      container.read(localComponentStateProvider('lyrics-whisper-model-tiny')).phase,
      LocalComponentPhase.failed,
    );
    final directory = Directory(
      '${root.path}/components/lyrics-whisper-model-tiny',
    );
    expect(await directory.exists(), isFalse);
  });

  test('removing a component that was never downloaded keeps the state', () async {
    final container = containerWith(FakeHttpAdapter());

    await container.read(localComponentsControllerProvider.future);
    await container
        .read(localComponentsControllerProvider.notifier)
        .remove('ffmpeg');

    expect(
      container.read(localComponentStateProvider('ffmpeg')).phase,
      LocalComponentPhase.notInstalled,
      reason: 'a copy that is not ours is not removed',
    );
  });
}
