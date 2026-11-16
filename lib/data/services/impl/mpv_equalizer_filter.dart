import 'package:tune/domain/models/equalizer_settings.dart';

/// Translates [EqualizerSettings] into the `af` value of mpv.
///
/// mpv runs an ffmpeg filter graph here: `volume` is the preamp and one
/// `equalizer` instance carries each band. Commas inside the `lavfi=[...]`
/// brackets belong to the graph, not to mpv's filter separator — verified
/// against mpv 0.41 / ffmpeg 8.0 (docs/equalizer.md).
class MpvEqualizerFilter {
  const MpvEqualizerFilter._();

  /// The `af` value for [settings], or null when nothing should be applied.
  ///
  /// A band at 0 dB is left out of the graph: mpv evaluates every filter in
  /// the chain, and a filter that does nothing still costs samples.
  static String? build(EqualizerSettings settings) {
    if (!settings.enabled || settings.isFlat) return null;
    final filters = <String>[];
    final preamp = settings.preampDb;
    if (preamp != 0) {
      filters.add('volume=${_db(preamp)}dB');
    }
    for (var i = 0; i < EqualizerSettings.bandCount; i++) {
      final gain = settings.gains[i];
      if (gain == 0) continue;
      final frequency = EqualizerSettings.frequencies[i];
      filters.add(
        'equalizer=f=${_hz(frequency)}'
        ':width_type=o:width=${_octaves(settings.bandWidth)}:g=${_db(gain)}',
      );
    }
    if (filters.isEmpty) return null;
    return 'lavfi=[${filters.join(',')}]';
  }

  /// A whole number is written without a decimal part; ffmpeg accepts both,
  /// but the shorter chain is the one that is read in a log.
  static String _db(double value) =>
      value == value.roundToDouble() ? value.toInt().toString() : value.toString();

  static String _hz(double value) =>
      value == value.roundToDouble() ? value.toInt().toString() : value.toString();

  /// A band width in octaves, rounded to a thousandth: two thirds of an octave
  /// is written 0.667, not the repeating decimal the division produces.
  static String _octaves(double value) {
    final rounded = (value * 1000).round() / 1000;
    return rounded == rounded.roundToDouble()
        ? rounded.toInt().toString()
        : rounded.toString();
  }
}
