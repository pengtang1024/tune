import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/data/services/music_sources/source_type_catalogue.dart';
import 'package:tune/domain/models/music_source.dart';
import 'package:tune/features/sources/application/music_sources_controller.dart';
import 'package:tune/l10n/app_localizations.dart';

/// The form of a source: the fields its type declares.
///
/// The form writes to an instance that exists, or writes a new one. It knows
/// no source of its own: the fields come from the type, so one form serves
/// every type.
class SourceFormDialog extends ConsumerStatefulWidget {
  /// The instance being edited.
  final MusicSourceConfig? source;

  /// The type of the instance being added.
  final SourceTypeDescriptor? type;

  final List<MusicSourceField> fields;

  const SourceFormDialog.edit({
    super.key,
    required MusicSourceConfig this.source,
    required this.fields,
  }) : type = null;

  const SourceFormDialog.add({
    super.key,
    required SourceTypeDescriptor this.type,
    required this.fields,
  }) : source = null;

  /// Whether the form writes a new instance.
  bool get adds => source == null;

  /// The title the dialog carries.
  String title(AppLocalizations strings) {
    final source = this.source;
    if (source != null) return strings.sourcesConfigureTitle(source.name);
    return strings.sourcesAddTitle(type!.name);
  }

  @override
  ConsumerState<SourceFormDialog> createState() => _SourceFormDialogState();
}

class _SourceFormDialogState extends ConsumerState<SourceFormDialog> {
  late final Map<String, TextEditingController> _controllers;
  late final TextEditingController _name;
  final Map<String, String> _errors = {};

  @override
  void initState() {
    super.initState();
    _controllers = {
      for (final field in widget.fields)
        field.key: TextEditingController(
          text: widget.source?.setting(field.key) ?? '',
        ),
    };
    _name = TextEditingController(text: widget.source?.name ?? '');
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _name.dispose();
    super.dispose();
  }

  /// Whether the name of the instance is the reader's to change.
  ///
  /// A built-in source is named by its type, so the form does not offer a
  /// name the reader could not keep.
  bool get _editsName {
    final source = widget.source;
    return source == null || !source.builtIn;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title(context.loc)),
      content: SizedBox(
        width: 360,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_editsName) ...[
                TextField(
                  key: const ValueKey('source-field-name'),
                  controller: _name,
                  decoration: InputDecoration(
                    labelText: context.loc.sourcesFieldName,
                    hintText: context.loc.sourcesFieldNameHint,
                    isDense: true,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              for (final field in widget.fields) ...[
                if (field.choices.isNotEmpty)
                  _ChoiceField(
                    field: field,
                    value: _choiceValue(field),
                    onChanged: (value) => _selectChoice(field, value),
                  )
                else
                  TextField(
                    key: ValueKey('source-field-${field.key}'),
                    controller: _controllers[field.key],
                    obscureText: field.secret,
                    decoration: InputDecoration(
                      labelText: field.label,
                      hintText: field.hint,
                      errorText: _errors[field.key],
                      isDense: true,
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: field.numeric
                        ? const TextInputType.numberWithOptions(decimal: false)
                        : TextInputType.text,
                    maxLines: field.multiline ? 4 : 1,
                    minLines: field.multiline ? 3 : 1,
                  ),
                const SizedBox(height: 10),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.loc.cancel),
        ),
        FilledButton(
          key: const ValueKey('source-form-save'),
          onPressed: _save,
          child: Text(context.loc.save),
        ),
      ],
    );
  }

  Future<void> _save() async {
    _errors.clear();
    final settings = <String, String>{};

    for (final field in widget.fields) {
      final value = field.choices.isEmpty
          ? (_controllers[field.key]?.text.trim() ?? '')
          : _choiceValue(field);
      if (field.required && value.isEmpty) {
        _errors[field.key] = context.loc.sourcesFieldRequired(field.label);
      }
      if (field.numeric && value.isNotEmpty && int.tryParse(value) == null) {
        _errors[field.key] = context.loc.sourcesFieldNumeric;
      }
      settings[field.key] = value;
    }

    if (_errors.isNotEmpty) {
      setState(() {});
      return;
    }

    final controller = ref.read(musicSourcesControllerProvider.notifier);
    final source = widget.source;
    if (source == null) {
      await controller.addInstance(
        type: widget.type!.type,
        name: _name.text,
        settings: settings,
      );
    } else {
      await controller.updateSettings(
        source.id,
        settings,
        name: _editsName ? _name.text : null,
      );
    }
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  /// The value a setting of a fixed set of choices shows.
  String _choiceValue(MusicSourceField field) {
    final current = _controllers[field.key]?.text ?? '';
    for (final choice in field.choices) {
      if (choice.value == current) return current;
    }
    return field.choices.first.value;
  }

  /// Keeps the value of a choice in the controller of its field.
  void _selectChoice(MusicSourceField field, String value) {
    _controllers[field.key]?.text = value;
    setState(() {});
  }
}

/// A setting that only allows a fixed set of values.
///
/// The source declares the options, so the interface does not have to know
/// which setting of which source it is showing.
class _ChoiceField extends StatelessWidget {
  const _ChoiceField({
    required this.field,
    required this.value,
    required this.onChanged,
  });

  final MusicSourceField field;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isDense: true,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: field.label,
        hintText: field.hint,
        isDense: true,
        border: const OutlineInputBorder(),
      ),
      items: [
        for (final choice in field.choices)
          DropdownMenuItem(value: choice.value, child: Text(choice.label)),
      ],
      onChanged: (selected) {
        if (selected != null) onChanged(selected);
      },
    );
  }
}
