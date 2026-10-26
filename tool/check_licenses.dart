import 'dart:io';

/// Structural license check for the repository.
///
/// This is not a full legal audit. It guards the invariants that are easy to
/// break while editing: the root license, the third-party notices, the OFL
/// files next to the fonts, and the removed JavaScript bundle. The full
/// dependency audit still has to read `pubspec.lock` and the pub cache.
void main() {
  final errors = <String>[];

  final license = File('LICENSE');
  if (!license.existsSync()) {
    errors.add('LICENSE is missing');
  } else if (!license.readAsStringSync().contains('MIT License')) {
    errors.add('LICENSE does not look like the MIT license');
  }

  final notices = File('THIRD_PARTY_NOTICES.md');
  if (!notices.existsSync()) {
    errors.add('THIRD_PARTY_NOTICES.md is missing');
  } else {
    final text = notices.readAsStringSync();
    for (final needle in const ['SIL OPEN FONT LICENSE', 'libmpv', 'dbus']) {
      if (!text.contains(needle)) {
        errors.add('THIRD_PARTY_NOTICES.md does not mention "$needle"');
      }
    }
  }

  final fonts = Directory('assets/fonts');
  if (!fonts.existsSync()) {
    errors.add('assets/fonts is missing');
  } else {
    for (final family in fonts.listSync().whereType<Directory>()) {
      final ofl = File('${family.path}/OFL.txt');
      if (!ofl.existsSync()) {
        errors.add('${family.path} has no OFL.txt');
      }
    }
  }

  if (Directory('assets/js').existsSync()) {
    errors.add('assets/js must not be shipped; the plugin bundle was removed');
  }

  for (final bundlePath in const [
    'build/linux/x64/release/bundle',
    'build/linux/x64/debug/bundle',
  ]) {
    final bundle = Directory(bundlePath);
    if (!bundle.existsSync()) continue;
    for (final entity in bundle.listSync(recursive: true)) {
      if (entity is File && entity.path.contains('libmpv')) {
        errors.add('$bundlePath contains libmpv; do not bundle GPL code');
      }
    }
  }

  final pubspec = File('pubspec.yaml');
  if (!pubspec.existsSync()) {
    errors.add('pubspec.yaml is missing');
  } else {
    final text = pubspec.readAsStringSync();
    if (!text.contains('- THIRD_PARTY_NOTICES.md')) {
      errors.add('pubspec.yaml does not bundle THIRD_PARTY_NOTICES.md');
    }
    if (!text.contains('- LICENSE')) {
      errors.add('pubspec.yaml does not bundle LICENSE');
    }
    if (text.contains('- assets/js/')) {
      errors.add('pubspec.yaml still bundles assets/js/');
    }
  }

  for (final line in _gitFiles()) {
    final file = File(line);
    if (!file.existsSync() || !_isSource(line)) continue;
    final text = file.readAsStringSync();
    for (final needle in const [
      'GNU General Public License',
      'GNU Affero General Public License',
      'Server Side Public License',
      'Business Source License',
      'Commons Clause',
    ]) {
      if (text.contains(needle)) {
        errors.add('$line contains "$needle"');
      }
    }
  }

  if (errors.isEmpty) {
    stdout.writeln('license check: OK');
    return;
  }

  stderr.writeln('license check failed:');
  for (final error in errors) {
    stderr.writeln('  - $error');
  }
  exitCode = 1;
}

Iterable<String> _gitFiles() {
  final result = Process.runSync('git', ['ls-files']);
  if (result.exitCode != 0) return const [];
  return (result.stdout as String).split('\n').where((line) => line.isNotEmpty);
}

bool _isSource(String path) {
  const extensions = {
    '.dart',
    '.cc',
    '.cpp',
    '.c',
    '.h',
    '.swift',
    '.m',
    '.java',
    '.kt',
    '.gradle',
    '.js',
    '.ts',
    '.yaml',
    '.yml',
  };
  return extensions.any(path.endsWith);
}
