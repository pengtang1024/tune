import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards the localisation of the app.
///
/// Five rules are checked:
///
/// * every locale ships the same catalogue, so no language falls back to
///   another one by accident,
/// * every locale shows its own text, so the interface never mixes two
///   languages,
/// * every key the code reads exists, so a renamed message never silently
///   disappears from the interface,
/// * no locale borrows the script of another one,
/// * the interface itself carries no hardcoded text, so a new page cannot
///   reintroduce a single language,
/// * the interface writes no text of a language of its own, so a new page
///   cannot bring back a single English label.
void main() {
  const arbDirectory = 'lib/l10n';
  const generatedCatalogue = 'lib/l10n/app_localizations.dart';

  final locales =
      Directory(arbDirectory)
          .listSync()
          .whereType<File>()
          .map((file) => file.uri.pathSegments.last)
          .where((name) => name.startsWith('app_') && name.endsWith('.arb'))
          .toList()
        ..sort();

  test('every locale shows its own catalogue', () {
    final failures = <String>[];

    for (final file in locales) {
      final locale = file.substring('app_'.length, file.length - '.arb'.length);
      final body = _generatedClassBody(locale);
      if (body == null) {
        failures.add('$locale has no generated class');
        continue;
      }

      final texts = _literals(body);
      final catalogue =
          jsonDecode(File('$arbDirectory/$file').readAsStringSync())
              as Map<String, dynamic>;

      for (final entry in catalogue.entries) {
        if (entry.key.startsWith('@')) continue;
        final value = entry.value;
        if (value is! String || value.isEmpty) continue;

        final formatted = _formattedPlaceholders(catalogue['@${entry.key}']);
        for (final text in _expectedTexts(value, formatted)) {
          if (!texts.contains(text)) {
            failures.add('$locale ${entry.key}: "$text" is not shown');
          }
        }
      }
    }

    expect(
      failures,
      isEmpty,
      reason:
          'a locale does not show its own catalogue:\n${failures.join('\n')}',
    );
  });

  test('every locale ships the same catalogue', () {
    expect(locales, isNotEmpty);

    final catalogues = <String, Set<String>>{};
    for (final file in locales) {
      final json =
          jsonDecode(File('$arbDirectory/$file').readAsStringSync())
              as Map<String, dynamic>;
      catalogues[file] = json.keys.where((key) => !key.startsWith('@')).toSet();
    }

    final template = catalogues[locales.first]!;
    for (final entry in catalogues.entries) {
      expect(
        entry.value.difference(template),
        isEmpty,
        reason: '${entry.key} has keys the template does not know',
      );
      expect(
        template.difference(entry.value),
        isEmpty,
        reason: '${entry.key} is missing keys of the template',
      );
    }
  });

  test('every referenced key exists in the catalogue', () {
    final declared = _declaredKeys(File(generatedCatalogue).readAsStringSync());

    final referenced = <String>{};
    for (final file in _dartFiles('lib')) {
      final source = file.readAsStringSync();
      referenced.addAll(
        RegExp(
          r'context\.loc\.([A-Za-z_][A-Za-z0-9_]*)',
        ).allMatches(source).map((match) => match.group(1)!),
      );
      referenced.addAll(
        RegExp(
          r'AppStrings\.instance\.([A-Za-z_][A-Za-z0-9_]*)',
        ).allMatches(source).map((match) => match.group(1)!),
      );
    }

    expect(referenced, isNotEmpty);
    expect(
      referenced.difference(declared),
      isEmpty,
      reason: 'the code reads keys the catalogue does not declare',
    );
  });

  test('no locale falls back to the language of another one', () {
    final offenders = <String>[];

    for (final file in locales) {
      final json =
          jsonDecode(File('$arbDirectory/$file').readAsStringSync())
              as Map<String, dynamic>;
      final locale = file.replaceAll('app_', '').replaceAll('.arb', '');

      final forbidden = _foreignScripts[locale];
      if (forbidden == null) continue;

      for (final entry in json.entries) {
        if (entry.key.startsWith('@')) continue;
        final value = entry.value;
        if (value is! String || value.isEmpty) {
          offenders.add('${entry.key} in $locale is empty');
          continue;
        }
        final match = forbidden.firstMatch(value);
        if (match != null) {
          offenders.add(
            '${entry.key} in $locale uses ${match.group(0)}: $value',
          );
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'a locale shows text of another language:\n${offenders.join('\n')}',
    );
  });

  test('the interface carries no hardcoded text', () {
    final offenders = <String>[];

    for (final file in _interfaceFiles()) {
      final lines = file.readAsLinesSync();
      var insideLog = false;
      for (var index = 0; index < lines.length; index++) {
        final line = lines[index];
        final trimmed = line.trim();

        // A log message stays in the language of the developer, it never
        // reaches the interface.
        if (insideLog) {
          if (trimmed.startsWith(')')) insideLog = false;
          continue;
        }
        if (trimmed.startsWith('//')) continue;
        if (_logCall.hasMatch(trimmed)) {
          if (!_closesOnSameLine(trimmed)) insideLog = true;
          continue;
        }
        if (!_chinese.hasMatch(line)) continue;
        if (_onlyLanguageNames(line)) continue;
        offenders.add('${file.path}:${index + 1} $trimmed');
      }
    }

    expect(
      offenders,
      isEmpty,
      reason: 'hardcoded text in the interface:\n${offenders.join('\n')}',
    );
  });

  test('the interface writes no text of its own language', () {
    final offenders = <String>[];

    for (final file in _interfaceFiles()) {
      final lines = file.readAsLinesSync();
      var insideLog = false;
      for (var index = 0; index < lines.length; index++) {
        final line = lines[index];
        final trimmed = line.trim();

        // A log message stays in the language of the developer, it never
        // reaches the interface.
        if (insideLog) {
          if (trimmed.startsWith(')')) insideLog = false;
          continue;
        }
        if (trimmed.startsWith('//')) continue;
        if (_logCall.hasMatch(trimmed)) {
          if (!_closesOnSameLine(trimmed)) insideLog = true;
          continue;
        }

        final literal = _visibleLiteral(lines, index);
        if (literal == null) continue;

        final text = literal.replaceAll(_interpolation, '');
        if (!_latinWord.hasMatch(text)) continue;
        if (_properNames.contains(text.trim())) continue;

        offenders.add('${file.path}:${index + 1} "$literal"');
      }
    }

    expect(
      offenders,
      isEmpty,
      reason: 'hardcoded text in the interface:\n${offenders.join('\n')}',
    );
  });
}

/// The text of a widget that a reader can see.
final _textWidget = RegExp(r'\b(?:Text|TextSpan)\s*\(\s*');

/// The named arguments of a widget that a reader can see.
final _namedSlot = RegExp(
  r'\b(?:labelText|hintText|helperText|errorText|semanticLabel|tooltip|title|'
  r'subtitle|eyebrow|label|hint|message|content|placeholder|description|text|'
  r'name)\s*:\s*',
);

/// A string literal at the beginning of a text.
final _leadingLiteral = RegExp(r"^'((?:[^'\\\n]|\\.)*)'");

/// The part of a text that a variable fills in.
final _interpolation = RegExp(r'\$(?:\{[^}]*\}|[A-Za-z_][A-Za-z0-9_.]*)');

/// A word of the Latin script.
final _latinWord = RegExp(r'[A-Za-z]{2,}');

/// The names the app does not translate.
///
/// The app and the services it talks to carry a name of their own, so those
/// names stay the same in every language.
const _properNames = {
  'Tune',
  'TUNE',
  'Openverse',
  'Jamendo',
  'Internet Archive',
  'ccMixter',
  'iTunes',
  'Subsonic',
  'Audius',
  'Wikimedia Commons',
  'Jellyfin',
  'Radio Paradise Main',
  'Radio Paradise Mellow',
  'Radio Paradise Eclectic',
  'Radio Paradise Rock',
  'Radio Paradise World',
};

/// The text a reader can see at a line, if the line holds one.
///
/// Only the places a reader can see count: the argument of a text widget and
/// the named argument of a widget. Everything else is a key of a map, an
/// address or the name of a file.
String? _visibleLiteral(List<String> lines, int index) {
  final line = lines[index];

  final widget = _textWidget.firstMatch(line);
  if (widget != null) {
    return _literalAfter(lines, index, line.substring(widget.end));
  }

  final slot = _namedSlot.firstMatch(line);
  if (slot == null) return null;

  // The slot has to be a named argument and not a word of an expression.
  final before = line.substring(0, slot.start).trimRight();
  if (before.isNotEmpty && !before.endsWith('(') && !before.endsWith(',')) {
    return null;
  }

  return _literalAfter(lines, index, line.substring(slot.end));
}

/// The literal that follows a place, on the line or on the next one.
String? _literalAfter(List<String> lines, int index, String tail) {
  final literal = _leadingLiteral.firstMatch(tail);
  if (literal != null) return literal.group(1);

  // The text of a widget may stand on the next line.
  if (tail.trim().isEmpty && index + 1 < lines.length) {
    final next = _leadingLiteral.firstMatch(lines[index + 1].trimLeft());
    if (next != null) return next.group(1);
  }
  return null;
}

/// The files whose text a user can read.
Iterable<File> _interfaceFiles() sync* {
  for (final directory in ['lib/features', 'lib/shared', 'lib/app']) {
    for (final file in _dartFiles(directory)) {
      if (file.path.contains('/presentation/') ||
          file.path.contains('/shared/ui/') ||
          file.path.startsWith('lib/app/')) {
        yield file;
      }
    }
  }

  // The services report their failures to the interface, so their messages
  // have to be translated as well.
  for (final directory in ['lib/data', 'lib/core']) {
    yield* _dartFiles(directory);
  }
}

final _logCall = RegExp(r'\bLog\.(info|error|warning|debug)\(');

/// Whether the parenthesis of the call is closed on the same line.
bool _closesOnSameLine(String line) {
  var depth = 0;
  for (final rune in line.runes) {
    if (rune == 0x28) depth++;
    if (rune == 0x29) depth--;
  }
  return depth <= 0;
}

/// The language names the settings page lists in their own language.
const _languageNames = {
  '繁體中文',
  '简体中文',
  '日本語',
  '한국어',
  'Deutsch',
  'Français',
  'Español',
  'Русский',
  'English',
  'Italiano',
  'Português',
  'Türkçe',
  'Polski',
  'Nederlands',
  'Tiếng Việt',
  'Bahasa Indonesia',
  'Українська',
  'العربية',
};

final _chinese = RegExp(r'[\u4e00-\u9fff]');
final _stringLiteral = RegExp(r"'([^'\n]*)'");

/// The characters a locale must never contain.
///
/// Japanese and Traditional Chinese use Han characters, so the rule only
/// applies to the locales that spell their words with another script.
final _foreignScripts = <String, RegExp>{
  'en': RegExp(r'[\u4e00-\u9fff\u3040-\u30ff\uac00-\ud7af\u0400-\u04ff]'),
  'de': RegExp(r'[\u4e00-\u9fff\u3040-\u30ff\uac00-\ud7af\u0400-\u04ff]'),
  'fr': RegExp(r'[\u4e00-\u9fff\u3040-\u30ff\uac00-\ud7af\u0400-\u04ff]'),
  'es': RegExp(r'[\u4e00-\u9fff\u3040-\u30ff\uac00-\ud7af\u0400-\u04ff]'),
  'ru': RegExp(r'[\u4e00-\u9fff\u3040-\u30ff\uac00-\ud7af]'),
  'ko': RegExp(r'[\u3040-\u30ff]'),
  'ja': RegExp(r'[\uac00-\ud7af\u0400-\u04ff]'),
};

/// Whether every Chinese text of the line is the name of a language.
bool _onlyLanguageNames(String line) {
  final literals = _stringLiteral
      .allMatches(line)
      .map((match) => match.group(1)!)
      .where((literal) => _chinese.hasMatch(literal))
      .toList();
  if (literals.isEmpty) return false;
  return literals.every((literal) => _languageNames.contains(literal));
}

Set<String> _declaredKeys(String generatedSource) {
  return RegExp(
    r'^\s*String(?:\s+get)?\s+([A-Za-z_][A-Za-z0-9_]*)\s*[;(]',
    multiLine: true,
  ).allMatches(generatedSource).map((match) => match.group(1)!).toSet();
}

/// The body of the generated class of a locale.
///
/// The generator gives every locale a class of its own, the shared catalogue
/// lives in the abstract base class.
String? _generatedClassBody(String locale) {
  final className = 'AppLocalizations${_camelCase(locale)}';

  for (final file in Directory('lib/l10n').listSync().whereType<File>()) {
    if (!file.path.endsWith('.dart')) continue;
    final source = file.readAsStringSync();
    final start = source.indexOf('class $className ');
    if (start < 0) continue;

    final body = source.substring(start);
    final next = body.indexOf('\nclass ');
    return next < 0 ? body : body.substring(0, next);
  }

  return null;
}

/// The name of a locale as the generator writes it.
String _camelCase(String locale) {
  return locale
      .split('_')
      .where((part) => part.isNotEmpty)
      .map((part) => part[0].toUpperCase() + part.substring(1).toLowerCase())
      .join();
}

/// The texts the generated class writes down.
///
/// Only the code of the class counts, a comment never carries a message.
Set<String> _literals(String body) {
  final code = body
      .split('\n')
      .where((line) => !line.trimLeft().startsWith('//'))
      .join('\n');

  return RegExp(
    r"'((?:[^'\\]|\\.)*)'",
  ).allMatches(code).map((match) => _unescape(match.group(1)!)).toSet();
}

/// The text a string literal carries.
String _unescape(String raw) {
  final buffer = StringBuffer();
  for (var index = 0; index < raw.length; index++) {
    final char = raw[index];
    if (char != r'\' || index + 1 >= raw.length) {
      buffer.write(char);
      continue;
    }

    index++;
    switch (raw[index]) {
      case 'n':
        buffer.write('\n');
      case 't':
        buffer.write('\t');
      case 'r':
        buffer.write('\r');
      case "'":
        buffer.write("'");
      case r'$':
        buffer.write(r'$');
      case r'\':
        buffer.write(r'\');
      default:
        buffer.write(raw[index]);
    }
  }
  return buffer.toString();
}

/// The texts a message is made of.
///
/// A message that counts something is written as a plural, so the generator
/// splits it into the texts of its branches. Every other message stays one
/// text.
List<String> _expectedTexts(String message, Set<String> formatted) {
  final branches = _pluralBranches(message).toList();
  if (branches.isEmpty) return [_dartText(message, formatted)];
  return branches.map((branch) => _dartText(branch, formatted)).toList();
}

/// The texts of the plural branches of a message.
Iterable<String> _pluralBranches(String message) sync* {
  var index = 0;
  while (true) {
    final marker = message.indexOf(', plural,', index);
    if (marker < 0) return;

    var cursor = marker + ', plural,'.length;
    while (true) {
      final branch = _branchAt(message, cursor);
      if (branch == null) break;

      final end = _matchingBrace(message, branch.start);
      final text = message.substring(branch.start + 1, end);
      yield text;
      yield* _pluralBranches(text);

      cursor = end + 1;
    }

    index = cursor;
  }
}

/// The branch of a plural that starts at a position.
({int start})? _branchAt(String message, int cursor) {
  final match = RegExp(r'\s*[A-Za-z0-9_=]+\{').matchAsPrefix(message, cursor);
  if (match == null) return null;
  return (start: match.end - 1);
}

/// The brace that closes the one at a position.
int _matchingBrace(String message, int open) {
  var depth = 0;
  for (var index = open; index < message.length; index++) {
    if (message[index] == '{') depth++;
    if (message[index] == '}') {
      depth--;
      if (depth == 0) return index;
    }
  }
  return message.length - 1;
}

/// The text as the generator writes it into the class of a locale.
///
/// A placeholder of the catalogue becomes a variable of the generated code. A
/// placeholder the catalogue asks to format becomes a text instead, so the
/// generator names it after the placeholder.
String _dartText(String message, Set<String> formatted) {
  return message.replaceAllMapped(RegExp(r'\{(\w+)\}'), (match) {
    final name = match.group(1)!;
    final variable = formatted.contains(name) ? '${name}String' : name;
    final next = match.end < message.length ? message[match.end] : '';
    if (next.isNotEmpty && _identifier.hasMatch(next)) return '\${$variable}';
    return '\$$variable';
  });
}

/// The placeholders the generator turns into a formatted text.
Set<String> _formattedPlaceholders(Object? metadata) {
  if (metadata is! Map) return const {};
  final placeholders = metadata['placeholders'];
  if (placeholders is! Map) return const {};
  return placeholders.entries
      .where(
        (entry) =>
            entry.value is Map && (entry.value as Map)['format'] is String,
      )
      .map((entry) => entry.key as String)
      .toSet();
}

final _identifier = RegExp(r'[A-Za-z0-9_]');

Iterable<File> _dartFiles(String directory) {
  return Directory(directory)
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'))
      .where((file) => !file.path.contains('/l10n/app_localizations'))
      .where((file) => !file.path.endsWith('app_localizations.dart'));
}
