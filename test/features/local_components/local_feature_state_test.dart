import 'package:flutter_test/flutter_test.dart';
import 'package:tune/data/services/components/local_component.dart';
import 'package:tune/data/services/components/local_component_registry.dart';
import 'package:tune/data/services/components/local_feature.dart';
import 'package:tune/features/local_components/application/local_feature_state.dart';

/// The feature state is a pure projection of the component states
/// (docs/local-components.md §7.3); it owns no data of its own.
void main() {
  final feature = LocalFeatureRegistry.translation;
  final tier = feature.tiers.firstWhere((tier) => tier.id == 'standard');
  final runtime = LocalComponentRegistry.translationRuntime;
  final model = LocalComponentRegistry.translationModel;

  Map<String, LocalComponentState> states(
    LocalComponentState runtimeState,
    LocalComponentState modelState,
  ) => {runtime.id: runtimeState, model.id: modelState};

  test('a state map without entries is still being checked', () {
    final state = deriveFeatureState(feature, tier, const {});

    expect(state.phase, LocalFeaturePhase.checking);
    expect(state.busy, isTrue);
  });

  test('two missing components ask for their whole size', () {
    final state = deriveFeatureState(
      feature,
      tier,
      states(
        const LocalComponentState(LocalComponentPhase.notInstalled),
        const LocalComponentState(LocalComponentPhase.notInstalled),
      ),
    );

    expect(state.phase, LocalFeaturePhase.notInstalled);
    expect(state.missingBytes, runtime.totalBytes + model.totalBytes);
    expect(state.completed, 0);
    expect(state.canDelete, isFalse);
  });

  test('a download aggregates the finished half and the active bytes', () {
    final state = deriveFeatureState(
      feature,
      tier,
      states(
        const LocalComponentState(
          LocalComponentPhase.ready,
          installedBytes: 100,
        ),
        const LocalComponentState(
          LocalComponentPhase.downloading,
          received: 40,
          total: 200,
        ),
      ),
    );

    expect(state.phase, LocalFeaturePhase.downloading);
    expect(state.received, runtime.totalBytes + 40);
    expect(
      state.total,
      runtime.totalBytes + model.totalBytes,
      reason: 'the progress line covers the whole install, not one file',
    );
    expect(state.installedBytes, 100);
    expect(state.completed, 1);
    expect(state.required, 2);
  });

  test('one usable component and one missing reads as partial', () {
    final state = deriveFeatureState(
      feature,
      tier,
      states(
        const LocalComponentState(LocalComponentPhase.ready),
        const LocalComponentState(LocalComponentPhase.notInstalled),
      ),
    );

    expect(state.phase, LocalFeaturePhase.partial);
    expect(state.completed, 1);
    expect(state.required, 2);
    expect(state.missingBytes, model.totalBytes);
  });

  test('a failure with nothing installed reads as failed', () {
    final transcode = LocalFeatureRegistry.transcode;
    final ffmpeg = transcode.tiers.first.components.first;
    final state = deriveFeatureState(transcode, transcode.tiers.first, {
      ffmpeg.id: const LocalComponentState(
        LocalComponentPhase.failed,
        message: 'the mirror is down',
      ),
    });

    expect(state.phase, LocalFeaturePhase.failed);
    expect(state.message, 'the mirror is down');
  });

  test('system copies only make a ready feature that downloaded nothing', () {
    final state = deriveFeatureState(
      feature,
      tier,
      states(
        const LocalComponentState(
          LocalComponentPhase.notInstalled,
          systemAvailable: true,
        ),
        const LocalComponentState(
          LocalComponentPhase.notInstalled,
          systemAvailable: true,
        ),
      ),
    );

    expect(state.phase, LocalFeaturePhase.ready);
    expect(state.systemOnly, isTrue);
    expect(state.canDelete, isFalse);
  });

  test('the footprint counts tiers that are not selected', () {
    final otherTier = feature.tiers.firstWhere((tier) => tier.id == 'quality');
    final otherModel = otherTier.components.last;
    final state = deriveFeatureState(
      feature,
      tier,
      {
        runtime.id: const LocalComponentState(LocalComponentPhase.ready),
        model.id: const LocalComponentState(LocalComponentPhase.ready),
        otherModel.id: const LocalComponentState(
          LocalComponentPhase.ready,
          installedBytes: 500,
          canDelete: true,
        ),
      },
    );

    expect(state.installedBytes, 500,
        reason: 'deleting a feature removes every tier, so every byte counts');
    expect(state.canDelete, isTrue);
  });
}
