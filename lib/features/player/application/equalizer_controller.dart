import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/data/services/audio_equalizer_backend.dart';
import 'package:tune/data/services/persistence_service.dart';
import 'package:tune/domain/models/equalizer_settings.dart';
import 'package:tune/utils/logger.dart';

/// The preference the curve is stored under.
const String equalizerPreferenceKey = 'audio_equalizer_v1';

/// How long the writes to the preference are coalesced.
const Duration equalizerSaveDelay = Duration(milliseconds: 400);

/// Owns the equalizer settings: reads them once, writes the curve to the
/// backend and stores it behind a debounce.
///
/// It is the only writer of the preference and the only caller of the
/// backend, so the panel and the filter chain cannot drift apart.
class EqualizerController extends StateNotifier<EqualizerSettings> {
  EqualizerController(this._persistence, this._backend)
    : _storedJson = null,
      super(_readInitial(_persistence)) {
    _storedJson = state.toJson();
  }

  final PersistenceService _persistence;
  final AudioEqualizerBackend? _backend;

  Timer? _saveTimer;
  String? _storedJson;

  static EqualizerSettings _readInitial(PersistenceService persistence) =>
      EqualizerSettings.fromJson(
        persistence.getString(equalizerPreferenceKey),
      );

  /// Whether the backend of this platform can carry a curve at all.
  bool get isAvailable => _backend?.isAvailable ?? false;

  /// Sends the stored curve to the backend once it is ready.
  ///
  /// Called by the startup sequence after the audio service probed the filter
  /// graph; a stored curve that is never sent would read as "on" in the panel
  /// while the sound stayed flat.
  Future<void> restore() async {
    final backend = _backend;
    if (backend == null || !backend.isAvailable) return;
    await _apply(backend);
  }

  void setEnabled(bool enabled) {
    if (state.enabled == enabled) return;
    state = state.copyWith(enabled: enabled);
    _changed();
  }

  void setGain(int band, double gain) {
    final next = state.withGain(band, gain);
    if (next == state) return;
    state = next;
    _changed();
  }

  void applyPreset(String presetId) {
    final preset = EqualizerPresets.byId(presetId);
    if (preset == null) return;
    // Compare the derived id, not the lists: List has no element-wise ==,
    // so two equal curves are two different objects and a reference check
    // would let every tap on the lit chip rewrite the filter graph.
    if (state.presetId == preset.id) return;
    state = state.copyWith(gains: preset.gains);
    _changed();
  }

  void reset() {
    final next = state.resetGains();
    if (next == state) return;
    state = next;
    _changed();
  }

  void _changed() {
    final backend = _backend;
    if (backend != null && backend.isAvailable) {
      unawaited(_apply(backend));
    }
    _saveTimer?.cancel();
    _saveTimer = Timer(equalizerSaveDelay, _save);
  }

  Future<void> _apply(AudioEqualizerBackend backend) async {
    try {
      await backend.apply(state);
    } catch (error, stackTrace) {
      Log.error('应用均衡器失败: $error', stackTrace);
    }
  }

  void _save() {
    final json = state.toJson();
    if (json == _storedJson) return;
    _storedJson = json;
    unawaited(_persist(json));
  }

  /// Writes one snapshot and swallows its failure into the log.
  ///
  /// The write is best effort: losing a preference must not break playback,
  /// but it also must not be silent, otherwise a broken settings file looks
  /// like a broken equalizer.
  Future<void> _persist(String json) async {
    try {
      await _persistence.setString(equalizerPreferenceKey, json);
    } catch (error, stackTrace) {
      Log.error('保存均衡器设置失败: $error', stackTrace);
    }
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    // The last value of a drag may still be in the debounce; write it before
    // the controller goes away instead of dropping the reader's last move.
    if (state.toJson() != _storedJson) {
      _storedJson = state.toJson();
      unawaited(_persist(_storedJson!));
    }
    super.dispose();
  }
}
