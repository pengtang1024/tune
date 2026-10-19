import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/l10n/app_localizations.dart';

/// Guards the localisation of the app.
///
/// Three rules are checked:
///
/// * every locale ships the same catalogue, so no language falls back to
///   another one by accident,
/// * every key the code reads exists, so a renamed message never silently
///   disappears from the interface,
/// * the interface itself carries no hardcoded text, so a new page cannot
///   reintroduce a single language.
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

  test('every locale resolves its own translation', () {
    final failures = <String>[];

    for (final locale in AppLocalizations.supportedLocales) {
      final catalogue = _catalogue(locale);
      final strings = lookupAppLocalizations(locale);

      for (final sample in _samples.entries) {
        final expected = _render(
          catalogue[sample.key]! as String,
          catalogue['@${sample.key}'],
        );
        final actual = sample.value(strings);
        if (expected != actual) {
          failures.add(
            '$locale ${sample.key}: expected "$expected", got "$actual"',
          );
        }
      }
    }

    expect(
      failures,
      isEmpty,
      reason: 'a locale does not resolve its own catalogue:\n'
          '${failures.join('\n')}',
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
          'a locale shows text of another language:\n'
          '${offenders.join('\n')}',
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

/// A sample of the catalogue, one per area of the app.
///
/// The values are read at runtime, so the test fails as soon as the app
/// stops resolving the catalogue of the locale the user picked.
final _samples = <String, String Function(AppLocalizations)>{
  'navLibrary': (s) => s.navLibrary,
  'navQueue': (s) => s.navQueue,
  'navSources': (s) => s.navSources,
  'navSettings': (s) => s.navSettings,
  'sourcesTitle': (s) => s.sourcesTitle,
  'searchOnlineTitle': (s) => s.searchOnlineTitle,
  'libraryNoMatchTitle': (s) => s.libraryNoMatchTitle,
  'settingsTitle': (s) => s.settingsTitle,
  'sourcesPluginImported': (s) => s.sourcesPluginImported(_text['name']!),
  'libraryTrackCount': (s) => s.libraryTrackCount(_numbers['count']!),
  'scanSummary': (s) => s.scanSummary(_numbers['songs']!, _numbers['sources']!),
  'pluginStepFailed': (s) =>
      s.pluginStepFailed(_text['error']!, _text['label']!),
};

/// The value every text placeholder is filled with.
final _text = <String, String>{
  'name': 'N',
  'error': 'E',
  'label': 'L',
  'time': 'T',
  'hint': 'H',
  'paths': 'P',
  'query': 'Q',
  'title': 'Ti',
  'version': 'V',
  'method': 'M',
  'message': 'Ms',
  'limit': 'Li',
  'key': 'K',
  'interval': 'I',
};

/// The value every number placeholder is filled with.
final _numbers = <String, int>{
  'count': 7,
  'songs': 7,
  'sources': 3,
  'failed': 1,
  'percent': 50,
  'seconds': 2,
  'status': 500,
};

/// The catalogue of a locale as it sits on disk.
Map<String, dynamic> _catalogue(Locale locale) {
  final name = locale.countryCode == null
      ? 'app_${locale.languageCode}.arb'
      : 'app_${locale.languageCode}_${locale.countryCode}.arb';
  return jsonDecode(File('lib/l10n/$name').readAsStringSync())
      as Map<String, dynamic>;
}

/// Fills the placeholders of a message with the values of the sample.
String _render(String message, Object? metadata) {
  if (metadata is! Map) return message;

  final placeholders = metadata['placeholders'];
  if (placeholders is! Map) return message;

  return message.replaceAllMapped(RegExp(r'\{(\w+)\}'), (match) {
    final name = match.group(1)!;
    final type = placeholders[name] is Map ? placeholders[name]['type'] : null;
    if (type == 'int') return '${_numbers[name]}';
    return _text[name] ?? match.group(0)!;
  });
}

Iterable<File> _dartFiles(String directory) {
  return Directory(directory)
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'))
      .where((file) => !file.path.contains('/l10n/app_localizations'))
      .where((file) => !file.path.endsWith('app_localizations.dart'));
}
