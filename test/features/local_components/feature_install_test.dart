import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/data/services/components/local_component.dart';
import 'package:tune/data/services/components/local_component_registry.dart';
import 'package:tune/data/services/components/local_feature.dart';
import 'package:tune/features/local_components/application/local_components_controller.dart';

/// A bulk install goes one component at a time, skips what is already usable,
/// stops at the first failure and resumes from there (docs/local-components.md
/// §7.4). This fake replaces only the download, so the loop itself is the code
/// under test.
class _BatchController extends LocalComponentsController {
  _BatchController(this.initial, {this.failIds = const {}});

  final Map<String, LocalComponentState> initial;
  final Set<String> failIds;
  final List<String> attempts = [];
  final List<String> removed = [];

  @override
  Future<Map<String, LocalComponentState>> build() async => initial;

  @override
  Future<bool> download(String id) async {
    attempts.add(id);
    if (failIds.contains(id)) return false;
    state = AsyncData({
      ...?state.valueOrNull,
      id: const LocalComponentState(
        LocalComponentPhase.ready,
        installedBytes: 1024,
        canDelete: true,
      ),
    });
    return true;
  }

  @override
  Future<void> remove(String id) async {
    removed.add(id);
  }
}

void main() {
  Future<_BatchController> run(
    _BatchController controller,
    Future<void> Function(LocalComponentsController notifier) action,
  ) async {
    final container = ProviderContainer(
      overrides: [
        localComponentsControllerProvider.overrideWith(() => controller),
      ],
    );
    addTearDown(container.dispose);
    await container.read(localComponentsControllerProvider.future);
    await action(container.read(localComponentsControllerProvider.notifier));
    return controller;
  }

  Map<String, LocalComponentState> missingFor(List<LocalComponentSpec> specs) => {
    for (final spec in specs)
      spec.id: const LocalComponentState(LocalComponentPhase.notInstalled),
  };

  test('a feature install goes in order and skips a finished part', () async {
    final tier = LocalFeatureRegistry.translation.tiers
        .firstWhere((tier) => tier.id == 'standard');
    final runtime = tier.components.first;
    final model = tier.components.last;
    final controller = _BatchController({
      ...missingFor(tier.components),
      model.id: const LocalComponentState(
        LocalComponentPhase.ready,
        installedBytes: 1,
      ),
    });

    final result = await run(
      controller,
      (notifier) => notifier.installFeature(
        LocalFeatureRegistry.translation,
        tier,
      ),
    );

    expect(result.attempts, [runtime.id],
        reason: 'a usable component is not downloaded again');
  });

  test('a failure keeps the finished parts and a retry continues after them',
      () async {
    final specs = [
      LocalComponentRegistry.ffmpeg,
      LocalComponentRegistry.whisperRuntime,
      LocalComponentRegistry.whisperModel('tiny'),
    ];
    final controller = _BatchController(
      missingFor(specs),
      failIds: {specs[1].id},
    );
    final container = ProviderContainer(
      overrides: [
        localComponentsControllerProvider.overrideWith(() => controller),
      ],
    );
    addTearDown(container.dispose);
    await container.read(localComponentsControllerProvider.future);
    final notifier = container.read(localComponentsControllerProvider.notifier);

    await notifier.installComponents(specs);

    expect(controller.attempts, [specs[0].id, specs[1].id],
        reason: 'the first failure stops the batch; the third never starts');

    controller.failIds.clear();
    await notifier.installComponents(specs);

    expect(
      controller.attempts,
      [specs[0].id, specs[1].id, specs[1].id, specs[2].id],
      reason: 'the retry picks up at the failed one, not at the top',
    );
  });

  test('cancelling a feature only stops the active component', () async {
    final tier = LocalFeatureRegistry.lyrics.tiers
        .firstWhere((tier) => tier.id == 'small');
    final runtime = tier.components.first;
    final downloading = LocalComponentState(
      LocalComponentPhase.downloading,
      received: 1,
      total: 2,
    );
    final controller = _BatchController({
      for (final spec in tier.components)
        spec.id: spec.id == runtime.id
            ? downloading
            : const LocalComponentState(LocalComponentPhase.notInstalled),
    });
    final container = ProviderContainer(
      overrides: [
        localComponentsControllerProvider.overrideWith(() => controller),
      ],
    );
    addTearDown(container.dispose);
    await container.read(localComponentsControllerProvider.future);

    container
        .read(localComponentsControllerProvider.notifier)
        .cancelFeature(LocalFeatureRegistry.lyrics, tier);

    expect(
      controller.attempts,
      isEmpty,
      reason: 'cancelling does not start anything and keeps what finished',
    );
    expect(
      controller.state.valueOrNull?[runtime.id]?.phase,
      LocalComponentPhase.downloading,
      reason: 'the component map is untouched; only its token was stopped',
    );
  });

  test('removing a feature skips copies that belong to the system', () async {
    final feature = LocalFeatureRegistry.translation;
    final controller = _BatchController({
      LocalComponentRegistry.translationRuntime.id:
          const LocalComponentState(
            LocalComponentPhase.ready,
            canDelete: true,
          ),
      LocalComponentRegistry.translationModel.id:
          const LocalComponentState(
            LocalComponentPhase.notInstalled,
            systemAvailable: true,
          ),
    });

    await run(controller, (notifier) => notifier.removeFeature(feature));

    expect(controller.removed, [LocalComponentRegistry.translationRuntime.id],
        reason: 'a system copy is not ours to delete');
  });
}
