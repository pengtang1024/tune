import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards the rule of the chip system: a chip carries an icon and a colour,
/// never a word.
///
/// The rules live in [docs/chips.md]. This test reads the source, the way
/// the localization guard reads it, because the leftovers of the old chip
/// style are all in the source: a chip that writes a word again.
void main() {
  final sources = _dartFilesOf('lib');

  test('the chip that writes words stays in the details panel', () {
    final offenders = <String>[];

    for (final file in sources) {
      if (file.path.endsWith('shared/ui/meta_chip.dart')) continue;
      if (file.path.endsWith('shared/ui/track_detail_sheet.dart')) continue;
      if (file.path.contains('MetaChip(')) offenders.add(file.path);
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'a chip that writes words belongs to the details panel:\n'
          '${offenders.join('\n')}',
    );
  });

  test('the chip widgets live in one file', () {
    final offenders = <String>[];

    for (final file in sources) {
      if (file.path.endsWith('shared/ui/meta_chip.dart')) continue;
      if (RegExp(r'class \w*Chip\b').hasMatch(file.readAsStringSync())) {
        offenders.add(file.path);
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'a new chip widget has to join the chip family:\n'
          '${offenders.join('\n')}',
    );
  });

  test('a pill does not write a word', () {
    final offenders = <String>[];

    for (final file in sources) {
      final lines = file.readAsLinesSync();
      for (var index = 0; index < lines.length; index++) {
        if (!lines[index].contains('BorderRadius.circular(999)')) continue;
        final block = lines.sublist(index, (index + 40).clamp(0, lines.length));
        // A control may show its own value: a dropdown writes the language
        // it holds, and the menu it opens lists the choices.
        if (block.any((line) => line.contains('DropdownButton'))) continue;
        if (block.any((line) => line.contains('PopupMenuButton'))) continue;
        if (block.any((line) => RegExp(r'\bText\s*\(').hasMatch(line))) {
          offenders.add('${file.path}:${index + 1}');
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'a pill that writes a word grows and shrinks with it:\n'
          '${offenders.join('\n')}',
    );
  });
}

/// Every Dart file of a directory.
List<File> _dartFilesOf(String directory) {
  final root = Directory(directory);
  if (!root.existsSync()) return const [];

  return root
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'))
      .where((file) => !file.path.contains('/l10n/'))
      .toList(growable: false);
}
