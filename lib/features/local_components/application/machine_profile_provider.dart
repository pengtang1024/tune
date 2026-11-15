import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/data/services/system/machine_profile.dart';

/// Swapped in tests so the page can be driven with a known machine.
final machineProfileProbeProvider = Provider<MachineProfileProbe>(
  (ref) => const HostMachineProfileProbe(),
);

/// Read once when the settings page asks; a failed probe degrades to
/// "unknown" instead of blocking the page.
final machineProfileProvider = FutureProvider<MachineProfile>((ref) async {
  try {
    return await ref.watch(machineProfileProbeProvider).read();
  } catch (_) {
    return const MachineProfile();
  }
});
