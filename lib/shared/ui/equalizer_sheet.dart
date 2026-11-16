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
  required ValueChanged<double> onBandWidthChanged,
  required ValueChanged<double?> onPreampChanged,
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
      onBandWidthChanged: onBandWidthChanged,
      onPreampChanged: onPreampChanged,
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
    required this.onBandWidthChanged,
    required this.onPreampChanged,
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

  /// How much of the spectrum one band moves, in octaves.
  final ValueChanged<double> onBandWidthChanged;

  /// The preamp set by hand, or null to follow the loudest boost.
  final ValueChanged<double?> onPreampChanged;

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
    // The model snaps a typed tenth onto the half-decibel step; reporting the
    // snapped value keeps the controller on exactly what the panel drew.
    final snapped = EqualizerSettings.clampGain(gain);
    setState(() => _settings = _settings.withGain(band, snapped));
    widget.onGainChanged(band, snapped);
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

  void _setBandWidth(double width) {
    setState(() => _settings = _settings.copyWith(bandWidth: width));
    widget.onBandWidthChanged(_settings.bandWidth);
  }

  void _setPreampManual(bool manual) {
    final value = manual ? _settings.preampDb : null;
    setState(
      () => _settings = manual
          ? _settings.copyWith(preampOverrideDb: value)
          : _settings.copyWith(useAutoPreamp: true),
    );
    widget.onPreampChanged(value);
  }

  void _setPreamp(double decibels) {
    setState(() => _settings = _settings.copyWith(preampOverrideDb: decibels));
    widget.onPreampChanged(_settings.preampDb);
  }

  /// Asks for a gain in decibels: a slider reaches a half decibel, typing
  /// reaches the tenth the reader hears but cannot drag to.
  Future<void> _editGain(int band) async {
    final value = await showDialog<double>(
      context: context,
      builder: (context) => _GainInputDialog(
        frequency: _formatFrequency(EqualizerSettings.bands[band].frequency),
        initial: _settings.gainAt(band),
      ),
    );
    if (!mounted || value == null) return;
    _setGain(band, value);
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
          _BandWidthPicker(
            width: _settings.bandWidth,
            onSelected: widget.available ? _setBandWidth : null,
          ),
          const SizedBox(height: CompactTokens.space8),
          SettingsSwitchRow(
            title: context.loc.equalizerPreamp,
            description: _settings.preampOverrideDb == null
                ? context.loc.equalizerPreampAuto
                : context.loc.equalizerPreampManual,
            value: _settings.preampOverrideDb != null,
            onChanged: widget.available ? _setPreampManual : _ignoreSwitch,
          ),
          if (_settings.preampOverrideDb != null)
            _PreampSlider(
              decibels: _settings.preampDb,
              enabled: widget.available,
              onChanged: _setPreamp,
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
                      onGainTap: () => _editGain(band.index),
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

/// The width of every band, widest first.
///
/// One octave is the layout the ten centres were chosen for. Narrower widths
/// turn a band into a notch that leaves its neighbours alone, which is how a
/// hum or a whistle gets cut without dulling the music around it.
class _BandWidthPicker extends StatelessWidget {
  const _BandWidthPicker({required this.width, required this.onSelected});

  final double width;

  /// Null when the platform has no equalizer.
  final ValueChanged<double>? onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSelected = this.onSelected;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.loc.equalizerBandWidth,
          style: theme.textTheme.labelLarge,
        ),
        const SizedBox(height: CompactTokens.space4),
        Text(
          context.loc.equalizerBandWidthHint,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: CompactTokens.space8),
        Wrap(
          spacing: CompactTokens.space6,
          runSpacing: CompactTokens.space6,
          children: [
            for (var i = 0; i < EqualizerSettings.bandWidths.length; i++)
              ChoiceChip(
                key: ValueKey<String>('equalizer-width-$i'),
                label: Text(
                  _widthLabel(context, EqualizerSettings.bandWidths[i]),
                ),
                selected: EqualizerSettings.bandWidths[i] == width,
                onSelected: onSelected == null
                    ? null
                    : (_) => onSelected(EqualizerSettings.bandWidths[i]),
              ),
          ],
        ),
      ],
    );
  }
}

/// A width in octaves as the panel names it.
String _widthLabel(BuildContext context, double octaves) {
  final loc = context.loc;
  if (octaves >= 1) return loc.equalizerWidthOne;
  if (octaves > 0.5) return loc.equalizerWidthTwoThirds;
  if (octaves >= 0.5) return loc.equalizerWidthHalf;
  return loc.equalizerWidthThird;
}

/// The preamp, once the reader took it off the loudest boost.
class _PreampSlider extends StatelessWidget {
  const _PreampSlider({
    required this.decibels,
    required this.enabled,
    required this.onChanged,
  });

  final double decibels;

  final bool enabled;

  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final value = decibels.clamp(
      EqualizerSettings.minPreampDb,
      EqualizerSettings.maxPreampDb,
    );

    return Row(
      children: [
        Expanded(
          child: Slider(
            key: const ValueKey<String>('equalizer-preamp'),
            value: value,
            min: EqualizerSettings.minPreampDb,
            max: EqualizerSettings.maxPreampDb,
            divisions:
                (EqualizerSettings.maxPreampDb - EqualizerSettings.minPreampDb)
                    .round(),
            label: context.loc.equalizerGainDb(_formatGain(decibels)),
            onChanged: enabled ? onChanged : null,
          ),
        ),
        SizedBox(
          width: 44,
          child: Text(
            context.loc.equalizerGainDb(_formatGain(decibels)),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}

/// Asks for a gain in decibels.
///
/// The slider moves in halves; typing reaches a tenth. The model snaps what
/// comes back to its own step, so a typo lands on the nearest half instead of
/// putting the filter graph on a value the panel cannot draw.
class _GainInputDialog extends StatefulWidget {
  const _GainInputDialog({required this.frequency, required this.initial});

  final String frequency;

  final double initial;

  @override
  State<_GainInputDialog> createState() => _GainInputDialogState();
}

class _GainInputDialogState extends State<_GainInputDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: _formatGain(widget.initial),
  );
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final parsed = double.tryParse(_controller.text.trim().replaceAll(',', '.'));
    if (parsed == null) {
      setState(() => _error = context.loc.equalizerGainDialogHint);
      return;
    }
    if (parsed < EqualizerSettings.minGain ||
        parsed > EqualizerSettings.maxGain) {
      setState(() => _error = context.loc.equalizerGainDialogHint);
      return;
    }
    Navigator.of(context).pop(parsed);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.loc.equalizerGainDialogTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.loc.equalizerFrequencyHz(widget.frequency)),
          const SizedBox(height: CompactTokens.space8),
          TextField(
            key: const ValueKey<String>('equalizer-gain-input'),
            controller: _controller,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(
              signed: true,
              decimal: true,
            ),
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              labelText: context.loc.equalizerGainDialogTitle,
              helperText: context.loc.equalizerGainDialogHint,
              errorText: _error,
              border: const OutlineInputBorder(),
              isDense: true,
            ),
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.loc.cancel),
        ),
        FilledButton(
          key: const ValueKey<String>('equalizer-gain-input-save'),
          onPressed: _submit,
          child: Text(context.loc.save),
        ),
      ],
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
    required this.onGainTap,
  });

  final EqualizerBand band;

  final double gain;

  final bool enabled;

  final ValueChanged<double> onChanged;

  /// Opens the field where a gain can be typed: halves are what the slider
  /// gives, a tenth is what the reader sometimes wants.
  final VoidCallback onGainTap;

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
          InkWell(
            key: ValueKey<String>('equalizer-gain-${band.index}'),
            onTap: enabled ? onGainTap : null,
            borderRadius: BorderRadius.circular(CompactTokens.radius4),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: CompactTokens.space4,
                vertical: 2,
              ),
              child: Text(
                context.loc.equalizerGainDb(value),
                style: labelStyle,
                maxLines: 1,
              ),
            ),
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
  final snapped = (gain * 10).round() / 10;
  if (snapped == 0) return '0';
  final text = snapped == snapped.roundToDouble()
      ? snapped.toStringAsFixed(0)
      : snapped.toStringAsFixed(1);
  return snapped > 0 ? '+$text' : text;
}

/// A centre frequency without the fractional part the model keeps for the
/// arithmetic: 31 Hz, not 31.0 Hz.
String _formatFrequency(double frequency) {
  final rounded = frequency.roundToDouble();
  return frequency == rounded
      ? rounded.toStringAsFixed(0)
      : frequency.toString();
}
