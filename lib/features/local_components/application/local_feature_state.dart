import 'package:tune/data/services/components/local_component.dart';
import 'package:tune/data/services/components/local_feature.dart';

/// What one feature item is doing, derived from its components.
enum LocalFeaturePhase {
  checking,
  notInstalled,
  downloading,
  verifying,
  ready,
  partial,
  failed,
}

/// The reader-facing state of one feature item.
///
/// It is a pure projection of [LocalComponentState], never a second source of
/// truth: the components stay the only thing that is written
/// (docs/local-components.md §7.3).
class LocalFeatureState {
  final LocalFeaturePhase phase;
  final int received;
  final int total;

  /// Everything the feature owns on disk, including tiers not selected.
  final int installedBytes;

  /// Bytes still needed by the selected tier.
  final int missingBytes;

  final int completed;
  final int required;
  final String? message;

  /// Every required component comes from the system, nothing was downloaded.
  final bool systemOnly;
  final bool canDelete;

  const LocalFeatureState(
    this.phase, {
    this.received = 0,
    this.total = 0,
    this.installedBytes = 0,
    this.missingBytes = 0,
    this.completed = 0,
    this.required = 0,
    this.message,
    this.systemOnly = false,
    this.canDelete = false,
  });

  bool get busy =>
      phase == LocalFeaturePhase.checking ||
      phase == LocalFeaturePhase.downloading ||
      phase == LocalFeaturePhase.verifying;

  double? get progress => total > 0 ? received / total : null;
}

/// Reads one tier through the states of its components.
LocalFeatureState deriveFeatureState(
  LocalFeatureSpec feature,
  LocalFeatureTier tier,
  Map<String, LocalComponentState> states,
) {
  LocalComponentState stateOf(LocalComponentSpec spec) =>
      states[spec.id] ?? const LocalComponentState(LocalComponentPhase.checking);

  final required = tier.components;
  var installedBytes = 0;
  var canDelete = false;
  for (final spec in feature.allComponents) {
    final state = states[spec.id];
    installedBytes += state?.installedBytes ?? 0;
    canDelete = canDelete || (state?.canDelete ?? false);
  }

  var completed = 0;
  var missingBytes = 0;
  var doneBytes = 0;
  var pendingBytes = 0;
  var anyChecking = false;
  var anyDownloading = false;
  var anyVerifying = false;
  String? failure;
  LocalComponentState? active;

  for (final spec in required) {
    final state = stateOf(spec);
    if (state.usable) {
      completed++;
      doneBytes += spec.totalBytes;
      continue;
    }
    missingBytes += spec.totalBytes;
    pendingBytes += spec.totalBytes;
    switch (state.phase) {
      case LocalComponentPhase.checking:
        anyChecking = true;
      case LocalComponentPhase.downloading:
        anyDownloading = true;
        active = state;
      case LocalComponentPhase.verifying:
        anyVerifying = true;
        active = state;
      case LocalComponentPhase.failed:
        failure ??= state.message;
      case LocalComponentPhase.notInstalled:
      case LocalComponentPhase.ready:
        break;
    }
  }

  final allUsable = completed == required.length;
  final systemOnly =
      allUsable &&
      required.every((spec) {
        final state = stateOf(spec);
        return state.systemAvailable && !state.ready;
      });

  if (anyDownloading) {
    return LocalFeatureState(
      LocalFeaturePhase.downloading,
      received: doneBytes + (active?.received ?? 0),
      total: doneBytes + pendingBytes,
      installedBytes: installedBytes,
      missingBytes: missingBytes,
      completed: completed,
      required: required.length,
      canDelete: canDelete,
    );
  }
  if (anyVerifying) {
    return LocalFeatureState(
      LocalFeaturePhase.verifying,
      received: doneBytes,
      total: doneBytes + pendingBytes,
      installedBytes: installedBytes,
      missingBytes: missingBytes,
      completed: completed,
      required: required.length,
      canDelete: canDelete,
    );
  }
  if (allUsable) {
    return LocalFeatureState(
      LocalFeaturePhase.ready,
      installedBytes: installedBytes,
      completed: completed,
      required: required.length,
      systemOnly: systemOnly,
      canDelete: canDelete,
    );
  }
  if (anyChecking) {
    return LocalFeatureState(
      LocalFeaturePhase.checking,
      installedBytes: installedBytes,
      missingBytes: missingBytes,
      completed: completed,
      required: required.length,
      canDelete: canDelete,
    );
  }
  if (completed > 0) {
    return LocalFeatureState(
      LocalFeaturePhase.partial,
      installedBytes: installedBytes,
      missingBytes: missingBytes,
      completed: completed,
      required: required.length,
      message: failure,
      canDelete: canDelete,
    );
  }
  if (failure != null) {
    return LocalFeatureState(
      LocalFeaturePhase.failed,
      installedBytes: installedBytes,
      missingBytes: missingBytes,
      message: failure,
      canDelete: canDelete,
    );
  }
  return LocalFeatureState(
    LocalFeaturePhase.notInstalled,
    installedBytes: installedBytes,
    missingBytes: missingBytes,
    canDelete: canDelete,
  );
}
