import 'package:flutter/material.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/domain/models/equalizer_settings.dart';
import 'package:tune/shared/ui/compact_sheet.dart';
import 'package:tune/shared/ui/settings_switch_row.dart';

/// The room the ten sliders share.
///
/// A band is a slider that stands on its end, so every step of the range has to
/// stay reachable under the thumb: the column is given a fixed height and the
/// slider takes whatever the two labels above and below it leave.
const double _bandHeight = 200;

/// Opens the music equalizer.
///
/// The panel is arguments and callbacks only: the player and the settings page
/// both open it, and a sheet shared by two features may not read the state of
/// either. The caller keeps the settings; the panel says what changed.
Future<void> showEqualizerPanel(
  BuildContext context, {
  required EqualizerSettings settings,
  required bool available,
  required ValueChanged<bool> onEnabledChanged,
  required void Function(int band, double gain) onGainChanged,
  required ValueChanged<String> onPresetChanged,
  required VoidCallback onReset,
}) async {
  await showCompactSheet<void>(
    context,
    (context) => EqualizerSheet(
      settings: settings,
      available: available,
      onEnabledChanged: onEnabledChanged,
      onGainChanged: onGainChanged,
      onPresetChanged: onPresetChanged,
      onReset: onReset,
    ),
  );
}

/// The equalizer panel: the switch, the curves and one slider per band.
///
/// The panel keeps the values it last handed to [onGainChanged] on its own. The
/// sheet is a route of its own and does not rebuild when the controller writes
/// the new settings down, so without the echo the thumb would jump back to the
/// value the panel opened with; the callbacks stay the only writer.
class EqualizerSheet extends StatefulWidget {
  const EqualizerSheet({
    super.key,
    required this.settings,
    required this.available,
    required this.onEnabledChanged,
    required this.onGainChanged,
    required this.onPresetChanged,
    required this.onReset,
  });

  /// The settings the panel opens with.
  final EqualizerSettings settings;

  /// Whether the backend of this platform can apply a curve at all.
  final bool available;

  final ValueChanged<bool> onEnabledChanged;

  final void Function(int band, double gain) onGainChanged;

  final ValueChanged<String> onPresetChanged;

  final VoidCallback onReset;

  @override
  State<EqualizerSheet> createState() => _EqualizerSheetState();
}

class _EqualizerSheetState extends State<EqualizerSheet> {
  late EqualizerSettings _settings = widget.settings;

  @override
  void didUpdateWidget(EqualizerSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.settings != widget.settings) {
      _settings = widget.settings;
    }
  }

  void _setEnabled(bool enabled) {
    setState(() => _settings = _settings.copyWith(enabled: enabled));
    widget.onEnabledChanged(enabled);
  }

  void _setGain(int band, double gain) {
    setState(() => _settings = _settings.withGain(band, gain));
    widget.onGainChanged(band, gain);
  }

  void _applyPreset(String presetId) {
    final preset = EqualizerPresets.byId(presetId);
    if (preset == null) return;
    setState(() => _settings = _settings.copyWith(gains: preset.gains));
    widget.onPresetChanged(presetId);
  }

  void _reset() {
    setState(() => _settings = _settings.resetGains());
    widget.onReset();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hintStyle = theme.textTheme.labelSmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(CompactTokens.sheetRadius),
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          CompactTokens.space20,
          CompactTokens.space16,
          CompactTokens.space20,
          CompactTokens.space24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    context.loc.equalizerTitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: widget.available ? _reset : null,
                  icon: const Icon(
                    Icons.restart_alt_rounded,
                    size: CompactTokens.icon16,
                  ),
                  label: Text(context.loc.equalizerReset),
                ),
              ],
            ),
            if (!widget.available) ...[
              const SizedBox(height: CompactTokens.space8),
              Row(
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    size: CompactTokens.icon16,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(width: CompactTokens.space8),
                  Expanded(
                    child: Text(
                      context.loc.equalizerUnavailable,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: CompactTokens.space12),
            // A platform without a filter chain still shows the panel: the
            // reader sees that the feature exists and why it is quiet. Every
            // control is dimmed and takes no pointer, so nothing promises a
            // change that cannot happen.
            Opacity(
              opacity: widget.available ? 1 : 0.45,
              child: IgnorePointer(
                ignoring: !widget.available,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SettingsSwitchRow(
                      title: context.loc.equalizerEnable,
                      description: _presetLabel(context, _settings.presetId),
                      value: _settings.enabled,
                      // The switch row of the app has no disabled state of its
                      // own; the dimmed block above keeps the pointer away and
                      // this guard keeps the value still for the keyboard.
                      onChanged: widget.available ? _setEnabled : _ignoreSwitch,
                    ),
                    const SizedBox(height: CompactTokens.space16),
                    _PresetRow(
                      presetId: _settings.presetId,
                      onSelected: widget.available ? _applyPreset : null,
                    ),
                    const SizedBox(height: CompactTokens.space16),
                    SizedBox(
                      height: _bandHeight,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (final band in EqualizerSettings.bands)
                            Expanded(
                              child: _BandSlider(
                                band: band,
                                gain: _settings.gainAt(band.index),
                                enabled: widget.available,
                                onChanged: (gain) => _setGain(band.index, gain),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: CompactTokens.space12),
            Text(context.loc.equalizerHint, style: hintStyle),
          ],
        ),
      ),
    );
  }

  void _ignoreSwitch(bool _) {}
}

/// The eight curves, and the mark that says the reader left all of them.
class _PresetRow extends StatelessWidget {
  const _PresetRow({required this.presetId, required this.onSelected});

  final String presetId;

  /// Null when the platform has no equalizer: the chips are still drawn, but a
  /// tap leads nowhere.
  final ValueChanged<String>? onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCustom = presetId == EqualizerPresets.customId;

    return Wrap(
      spacing: CompactTokens.space6,
      runSpacing: CompactTokens.space6,
      children: [
        for (final preset in EqualizerPresets.all)
          ChoiceChip(
            label: Text(_presetLabel(context, preset.id)),
            selected: preset.id == presetId,
            onSelected: onSelected == null
                ? null
                : (_) => onSelected!(preset.id),
          ),
        // The stored shape has no id: a curve the reader moved by hand matches
        // no preset, and the panel says so instead of lighting up a wrong chip.
        if (isCustom)
          Chip(
            label: Text(context.loc.equalizerCustom),
            backgroundColor: theme.colorScheme.primaryContainer,
            side: BorderSide.none,
          ),
      ],
    );
  }
}

/// One band: the gain it is set to, the slider that changes it, and the
/// frequency it acts on.
class _BandSlider extends StatelessWidget {
  const _BandSlider({
    required this.band,
    required this.gain,
    required this.enabled,
    required this.onChanged,
  });

  final EqualizerBand band;

  final double gain;

  final bool enabled;

  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labelStyle = theme.textTheme.labelSmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final frequency = _formatFrequency(band.frequency);
    final value = _formatGain(gain);

    return Semantics(
      label: context.loc.equalizerFrequencyHz(frequency),
      value: context.loc.equalizerGainDb(value),
      child: Column(
        children: [
          Text(
            context.loc.equalizerGainDb(value),
            style: labelStyle,
            maxLines: 1,
          ),
          Expanded(
            child: RotatedBox(
              // The slider is laid out across, then turned a quarter to the
              // left: the top of the column is the highest gain.
              quarterTurns: 3,
              child: Slider(
                key: ValueKey<String>('equalizer-band-${band.index}'),
                value: gain,
                min: EqualizerSettings.minGain,
                max: EqualizerSettings.maxGain,
                divisions:
                    ((EqualizerSettings.maxGain - EqualizerSettings.minGain) /
                            EqualizerSettings.step)
                        .round(),
                label: context.loc.equalizerGainDb(value),
                onChanged: enabled ? onChanged : null,
              ),
            ),
          ),
          const SizedBox(height: CompactTokens.space4),
          Text(
            context.loc.equalizerFrequencyHz(frequency),
            style: labelStyle,
            maxLines: 1,
          ),
        ],
      ),
    );
  }
}

/// The name of a curve, read through the localization of the window.
String _presetLabel(BuildContext context, String presetId) {
  final loc = context.loc;
  return switch (presetId) {
    EqualizerPresets.flatId => loc.equalizerPresetFlat,
    EqualizerPresets.popId => loc.equalizerPresetPop,
    EqualizerPresets.rockId => loc.equalizerPresetRock,
    EqualizerPresets.jazzId => loc.equalizerPresetJazz,
    EqualizerPresets.classicalId => loc.equalizerPresetClassical,
    EqualizerPresets.bassId => loc.equalizerPresetBass,
    EqualizerPresets.vocalId => loc.equalizerPresetVocal,
    EqualizerPresets.electronicId => loc.equalizerPresetElectronic,
    _ => loc.equalizerCustom,
  };
}

/// A gain as the panel spells it: a sign on the boosts, none on the cuts.
String _formatGain(double gain) {
  final rounded = gain.round();
  return rounded > 0 ? '+$rounded' : '$rounded';
}

/// A centre frequency without the fractional part the model keeps for the
/// arithmetic: 31 Hz, not 31.0 Hz.
String _formatFrequency(double frequency) {
  final rounded = frequency.roundToDouble();
  return frequency == rounded
      ? rounded.toStringAsFixed(0)
      : frequency.toString();
}
