import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/features/player/application/equalizer_providers.dart';
import 'package:tune/shared/ui/equalizer_sheet.dart';

/// Opens the equalizer from a player surface.
///
/// The dock and the header of the now-playing page lead to the same panel, so
/// the wiring to the controller is written once here: two copies of it would
/// drift apart the first time one of them learned something new.
///
/// This is the quick panel — a switch and four curves. The full editor with ten
/// sliders opens from the settings page, where there is room for it.
Future<void> openEqualizerPanel(BuildContext context, WidgetRef ref) {
  final controller = ref.read(equalizerControllerProvider.notifier);
  return showEqualizerQuickPanel(
    context,
    settings: ref.read(equalizerControllerProvider),
    available: ref.read(equalizerAvailableProvider),
    onEnabledChanged: controller.setEnabled,
    onPresetChanged: controller.applyPreset,
  );
}
