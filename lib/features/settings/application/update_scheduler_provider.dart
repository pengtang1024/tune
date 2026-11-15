import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/features/settings/application/update_controller.dart';
import 'package:tune/features/settings/application/update_scheduler.dart';

/// The scheduler of the running app (docs/update-cdn.md §4.3).
///
/// The timing lives in [UpdateScheduler] and knows nothing about Riverpod;
/// this is the wiring that runs the check of the settings.
final updateSchedulerProvider = Provider<UpdateScheduler>((ref) {
  final scheduler = UpdateScheduler(
    check: () async {
      await ref.read(updateControllerProvider.notifier).check(automatic: true);
      return ref.read(updateControllerProvider).status != UpdateStatus.failed;
    },
  );
  ref.onDispose(scheduler.stop);
  return scheduler;
});
