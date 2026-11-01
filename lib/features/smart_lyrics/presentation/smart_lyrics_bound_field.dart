import 'package:flutter/material.dart';
import 'package:tune/app/theme/compact_tokens.dart';

/// One dense input that carries a value of the config both ways.
///
/// It keeps its own controller, so a keystroke inside it never fights the
/// rebuild the settings state asks for; a change from outside — a preset
/// that brought new names with it, a config read back after a restart —
/// lands without disturbing what the reader is typing.
class SmartLyricsBoundField extends StatefulWidget {
  final String fieldKey;
  final String label;
  final String text;
  final ValueChanged<String> onChanged;

  const SmartLyricsBoundField({
    super.key,
    required this.fieldKey,
    required this.label,
    required this.text,
    required this.onChanged,
  });

  @override
  State<SmartLyricsBoundField> createState() => _SmartLyricsBoundFieldState();
}

class _SmartLyricsBoundFieldState extends State<SmartLyricsBoundField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.text,
  );

  @override
  void didUpdateWidget(SmartLyricsBoundField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.text != oldWidget.text && widget.text != _controller.text) {
      _controller.value = TextEditingValue(text: widget.text);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: CompactTokens.space8),
      child: TextField(
        key: ValueKey(widget.fieldKey),
        controller: _controller,
        decoration: InputDecoration(
          labelText: widget.label,
          isDense: true,
          border: const OutlineInputBorder(),
        ),
        onChanged: widget.onChanged,
      ),
    );
  }
}
