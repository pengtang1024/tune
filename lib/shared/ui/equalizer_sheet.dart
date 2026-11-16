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

/// Opens the quick panel: the switch and the curves most listeners pick by
/// mood, and nothing else.
///
/// The panel is arguments and callbacks only: the player and the settings page
/// both open a sheet, and a sheet shared by two features may not read the state
/// of either. The caller keeps the settings; the panel says what changed.
Future<void> showEqualizerQuickPanel(
  BuildContext context, {
  required EqualizerSettings settings,
  required bool available,
  required ValueChanged<bool> onEnabledChanged,
  required ValueChanged<String> onPresetChanged,
}) async {
  await showCompactSheet<void>(
    context,
    (context) => EqualizerQuickSheet(
      settings: settings,
      available: available,
      onEnabledChanged: onEnabledChanged,
      onPresetChanged: onPresetChanged,
    ),
  );
}

/// Opens the full editor: every curve, one slider per band, and the reset.
///
/// The settings page is the only caller. The player keeps its panel small on
/// purpose: ten sliders do not fit beside a track row and a volume thumb.
Future<void> showEqualizerEditorPanel(
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
    (context) => EqualizerEditorSheet(
      settings: settings,
      available: available,
      onEnabledChanged: onEnabledChanged,
      onGainChanged: onGainChanged,
      onPresetChanged: onPresetChanged,
      onReset: onReset,
    ),
  );
}

/// The name of a curve, read through the localization of the window.
///
/// The quick panel, the editor and the settings row all name a curve, so the
/// switch lives here instead of being written three times.
String equalizerPresetLabel(BuildContext context, String presetId) {
  final loc = context.loc;
  return switch (presetId) {
    EqualizerPresets.flatId => loc.equalizerPresetFlat,
    EqualizerPresets.popId => loc.equalizerPresetPop,
    EqualizerPresets.rockId => loc.equalizerPresetRock,
    EqualizerPresets.jazzId => loc.equalizerPresetJazz,
    EqualizerPresets.classicalId => loc.equalizerPresetClassical,
    EqualizerPresets.acousticId => loc.equalizerPresetAcoustic,
    EqualizerPresets.bassId => loc.equalizerPresetBass,
    EqualizerPresets.vocalId => loc.equalizerPresetVocal,
    EqualizerPresets.hiphopId => loc.equalizerPresetHiphop,
    EqualizerPresets.electronicId => loc.equalizerPresetElectronic,
    EqualizerPresets.liveId => loc.equalizerPresetLive,
    EqualizerPresets.softId => loc.equalizerPresetSoft,
    _ => loc.equalizerCustom,
  };
}

/// The panel the player opens: switch and four curves.
///
/// The panel keeps the values it last handed to the callbacks on its own. The
/// sheet is a route of its own and does not rebuild when the controller writes
/// the new settings down, so without the echo the chips would fall back to the
/// values the panel opened with; the callbacks stay the only writer.
class EqualizerQuickSheet extends StatefulWidget {
  const EqualizerQuickSheet({
    super.key,
    required this.settings,
    required this.available,
    required this.onEnabledChanged,
    required this.onPresetChanged,
  });

  /// The settings the panel opens with.
  final EqualizerSettings settings;

  /// Whether the backend of this platform can apply a curve at all.
  final bool available;

  final ValueChanged<bool> onEnabledChanged;

  final ValueChanged<String> onPresetChanged;

  @override
  State<EqualizerQuickSheet> createState() => _EqualizerQuickSheetState();
}

class _EqualizerQuickSheetState extends State<EqualizerQuickSheet> {
  late EqualizerSettings _settings = widget.settings;

  @override
  void didUpdateWidget(EqualizerQuickSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.settings != widget.settings) {
      _settings = widget.settings;
    }
  }

  void _setEnabled(bool enabled) {
    setState(() => _settings = _settings.copyWith(enabled: enabled));
    widget.onEnabledChanged(enabled);
  }

  void _applyPreset(String presetId) {
    final preset = EqualizerPresets.byId(presetId);
    if (preset == null) return;
    setState(() => _settings = _settings.copyWith(gains: preset.gains));
    widget.onPresetChanged(presetId);
  }

  @override
  Widget build(BuildContext context) {
    return _EqualizerFrame(
      available: widget.available,
      hint: context.loc.equalizerQuickHint,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SettingsSwitchRow(
            title: context.loc.equalizerEnable,
            description: equalizerPresetLabel(context, _settings.presetId),
            value: _settings.enabled,
            // The switch row of the app has no disabled state of its own; the
            // dimmed block of the frame keeps the pointer away and this guard
            // keeps the value still for the keyboard.
            onChanged: widget.available ? _setEnabled : _ignoreSwitch,
          ),
          const SizedBox(height: CompactTokens.space16),
          _PresetChips(
            presets: EqualizerPresets.quick,
            presetId: _settings.presetId,
            onSelected: widget.available ? _applyPreset : null,
          ),
        ],
      ),
    );
  }

  void _ignoreSwitch(bool _) {}
}

/// The panel the settings page opens: every curve and one slider per band.
class EqualizerEditorSheet extends StatefulWidget {
  const EqualizerEditorSheet({
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
  State<EqualizerEditorSheet> createState() => _EqualizerEditorSheetState();
}

class _EqualizerEditorSheetState extends State<EqualizerEditorSheet> {
  late EqualizerSettings _settings = widget.settings;

  @override
  void didUpdateWidget(EqualizerEditorSheet oldWidget) {
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
    return _EqualizerFrame(
      available: widget.available,
      hint: context.loc.equalizerHint,
      trailing: TextButton.icon(
        onPressed: widget.available ? _reset : null,
        icon: const Icon(
          Icons.restart_alt_rounded,
          size: CompactTokens.icon16,
        ),
        label: Text(context.loc.equalizerReset),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SettingsSwitchRow(
            title: context.loc.equalizerEnable,
            description: equalizerPresetLabel(context, _settings.presetId),
            value: _settings.enabled,
            onChanged: widget.available ? _setEnabled : _ignoreSwitch,
          ),
          const SizedBox(height: CompactTokens.space16),
          _PresetChips(
            presets: EqualizerPresets.all,
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
    );
  }

  void _ignoreSwitch(bool _) {}
}

/// The chrome both panels share: title, the mark that the platform cannot do
/// this, the controls, and one line of small print.
///
/// A platform without a filter chain still shows the panel: the reader sees
/// that the feature exists and why it is quiet. The controls are dimmed and
/// take no pointer, so nothing promises a change that cannot happen.
class _EqualizerFrame extends StatelessWidget {
  const _EqualizerFrame({
    required this.available,
    required this.hint,
    required this.child,
    this.trailing,
  });

  final bool available;

  final String hint;

  /// An action that belongs in the title row; the quick panel has none.
  final Widget? trailing;

  final Widget child;

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
                ?trailing,
              ],
            ),
            if (!available) ...[
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
            Opacity(
              opacity: available ? 1 : 0.45,
              child: IgnorePointer(ignoring: !available, child: child),
            ),
            const SizedBox(height: CompactTokens.space12),
            Text(hint, style: hintStyle),
          ],
        ),
      ),
    );
  }
}

/// A row of curves, and the mark that says the reader left all of them.
class _PresetChips extends StatelessWidget {
  const _PresetChips({
    required this.presets,
    required this.presetId,
    required this.onSelected,
  });

  final List<EqualizerPreset> presets;

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
        for (final preset in presets)
          ChoiceChip(
            label: Text(equalizerPresetLabel(context, preset.id)),
            selected: preset.id == presetId,
            onSelected:
                onSelected == null ? null : (_) => onSelected!(preset.id),
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
