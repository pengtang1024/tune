import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/features/smart_lyrics/application/smart_lyrics_batch_controller.dart';
import 'package:tune/features/settings/application/settings_controller.dart';

/// The library filling itself (2026-10-29 用户拍板: 默认自动补到 100% 有词):
/// a periodic look — when the toggle is on and no batch is already
/// running, the queue drains until every song carries words. The reader
/// never presses a button for it; the toggle just closes the door.
///
/// Started once at boot next to the free check; every tick decides for
/// itself whether the machine is busy enough to leave the batch alone.
class SmartLyricsAutoFillController {
  final Ref _ref;

  Timer? _timer;
  var _busy = false;

  SmartLyricsAutoFillController(this._ref);

  /// Starts the periodic look; the app calls this once.
  void start() {
    _timer?.cancel();
    // The first look comes right away — the reader should not wait a
    // full cycle to see the library move — then the loop keeps house.
    unawaited(_tick());
    _timer = Timer.periodic(
      const Duration(minutes: 30),
      (_) => unawaited(_tick()),
    );
  }

  void dispose() => _timer?.cancel();

  Future<void> _tick() async {
    if (_busy) return;
    final enabled = _ref.read(
      settingsControllerProvider.select((state) => state.smartLyrics.autoFill),
    );
    if (!enabled) return;
    final batch = _ref.read(smartLyricsBatchControllerProvider);
    if (batch.running) return;

    _busy = true;
    try {
      await _ref
          .read(smartLyricsBatchControllerProvider.notifier)
          .start();
    } finally {
      _busy = false;
    }
  }
}

/// The auto-fill loop; the app starts it once at boot.
final smartLyricsAutoFillControllerProvider =
    Provider<SmartLyricsAutoFillController>((ref) {
      final controller = SmartLyricsAutoFillController(ref);
      ref.onDispose(controller.dispose);
      return controller;
    });
