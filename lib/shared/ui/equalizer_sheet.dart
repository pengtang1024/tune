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

/// Opens the full editor: every curve, one slider per band, the save and the
/// reset.
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
  required String? Function(String name) onSavePreset,
  required ValueChanged<String> onDeletePreset,
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
      onSavePreset: onSavePreset,
      onDeletePreset: onDeletePreset,
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

/// The name of the curve the settings are on.
///
/// A built-in curve is named by the localization, a curve the reader kept by
/// itself; the fallback covers a curve moved by hand. The settings row names a
/// curve too, so the resolver is public.
String equalizerCurrentPresetLabel(
  BuildContext context,
  EqualizerSettings settings,
) {
  final preset = settings.findPreset(settings.presetId);
  final name = preset?.name;
  if (name != null && name.isNotEmpty) return name;
  return equalizerPresetLabel(context, settings.presetId);
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
            description: equalizerCurrentPresetLabel(context, _settings),
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
    required this.onSavePreset,
    required this.onDeletePreset,
  });

  /// The settings the panel opens with.
  final EqualizerSettings settings;

  /// Whether the backend of this platform can apply a curve at all.
  final bool available;

  final ValueChanged<bool> onEnabledChanged;

  final void Function(int band, double gain) onGainChanged;

  final ValueChanged<String> onPresetChanged;

  final VoidCallback onReset;

  /// Keeps the curve under a name and answers with the id it landed on, so the
  /// panel can draw the new chip before the sheet is opened again. Null when
  /// the caller could not keep it.
  final String? Function(String name) onSavePreset;

  final ValueChanged<String> onDeletePreset;

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
    final preset = _settings.findPreset(presetId);
    if (preset == null) return;
    setState(() => _settings = _settings.copyWith(gains: preset.gains));
    widget.onPresetChanged(presetId);
  }

  void _reset() {
    setState(() => _settings = _settings.resetGains());
    widget.onReset();
  }

  Future<void> _savePreset() async {
    final current = _settings.findPreset(_settings.presetId);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => _PresetNameDialog(initialName: current?.name ?? ''),
    );
    if (!mounted || name == null || name.trim().isEmpty) return;
    final trimmed = name.trim();
    final presetId = widget.onSavePreset(trimmed);
    if (presetId == null) return;
    setState(() {
      _settings = _settings.saveCurrentAsPreset(trimmed, id: presetId);
    });
  }

  void _deletePreset(String presetId) {
    setState(() => _settings = _settings.removePreset(presetId));
    widget.onDeletePreset(presetId);
  }

  @override
  Widget build(BuildContext context) {
    return _EqualizerFrame(
      available: widget.available,
      hint: context.loc.equalizerHint,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextButton.icon(
            key: const ValueKey<String>('equalizer-save-preset'),
            onPressed: widget.available ? _savePreset : null,
            icon: const Icon(
              Icons.bookmark_add_outlined,
              size: CompactTokens.icon16,
            ),
            label: Text(context.loc.equalizerSavePreset),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SettingsSwitchRow(
            title: context.loc.equalizerEnable,
            description: equalizerCurrentPresetLabel(context, _settings),
            value: _settings.enabled,
            onChanged: widget.available ? _setEnabled : _ignoreSwitch,
          ),
          const SizedBox(height: CompactTokens.space16),
          _PresetChips(
            presets: _settings.allPresets,
            presetId: _settings.presetId,
            onSelected: widget.available ? _applyPreset : null,
            onDeleted: widget.available ? _deletePreset : null,
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
    this.onDeleted,
  });

  final List<EqualizerPreset> presets;

  final String presetId;

  /// Null when the platform has no equalizer: the chips are still drawn, but a
  /// tap leads nowhere.
  final ValueChanged<String>? onSelected;

  /// Only the editor passes this: the curves the reader kept can be dropped
  /// again, the built-in ones are part of the app.
  final ValueChanged<String>? onDeleted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCustom = presetId == EqualizerPresets.customId;

    return Wrap(
      spacing: CompactTokens.space6,
      runSpacing: CompactTokens.space6,
      children: [
        for (final preset in presets) _chip(context, preset),
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

  /// A built-in curve is a name from the localization; a curve the reader kept
  /// carries its own name and can be dropped again.
  Widget _chip(BuildContext context, EqualizerPreset preset) {
    final name = preset.name;
    final selected = preset.id == presetId;
    final onSelected = this.onSelected;

    if (name == null) {
      return ChoiceChip(
        label: Text(equalizerPresetLabel(context, preset.id)),
        selected: selected,
        onSelected: onSelected == null ? null : (_) => onSelected(preset.id),
      );
    }

    final onDeleted = this.onDeleted;
    return InputChip(
      key: ValueKey<String>('equalizer-preset-${preset.id}'),
      label: Text(name),
      selected: selected,
      onSelected: onSelected == null ? null : (_) => onSelected(preset.id),
      onDeleted: onDeleted == null ? null : () => onDeleted(preset.id),
      deleteIcon: const Icon(Icons.close_rounded, size: CompactTokens.icon14),
      deleteButtonTooltipMessage: context.loc.equalizerPresetDelete,
    );
  }
}

/// Asks the reader for the name a curve is kept under.
///
/// An input error, or the back of the sheet, answers with null: no name, no
/// curve. A name that is already taken overwrites that curve, which is what
/// the reader means when they type it a second time.
class _PresetNameDialog extends StatefulWidget {
  const _PresetNameDialog({required this.initialName});

  final String initialName;

  @override
  State<_PresetNameDialog> createState() => _PresetNameDialogState();
}

class _PresetNameDialogState extends State<_PresetNameDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialName,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    Navigator.of(context).pop(_controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.loc.equalizerSavePreset),
      content: TextField(
        key: const ValueKey<String>('equalizer-preset-name'),
        controller: _controller,
        autofocus: true,
        textInputAction: TextInputAction.done,
        decoration: InputDecoration(
          labelText: context.loc.equalizerPresetName,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.loc.cancel),
        ),
        FilledButton(
          key: const ValueKey<String>('equalizer-preset-name-save'),
          onPressed: _submit,
          child: Text(context.loc.save),
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
