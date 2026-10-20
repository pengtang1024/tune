import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tune/data/services/desktop/audio_mime_types.dart';
import 'package:tune/data/services/desktop/startup_files.dart';

void main() {
  group('the files of the command line', () {
    test('keeps the paths and drops the switches', () {
      final files = startupFiles([
        '--verbose',
        '/music/a.mp3',
        '',
        '-',
        '/music/b.flac',
      ]);

      expect(files, ['/music/a.mp3', '/music/b.flac']);
    });

    test('is empty when the command line names no file', () {
      expect(startupFiles(['--verbose']), isEmpty);
    });

    test('reads the words of the command line of the process', () {
      final bytes = utf8.encode('tune\x00/music/a.mp3\x00--quiet\x00');

      expect(commandLineArguments(bytes), ['/music/a.mp3', '--quiet']);
    });

    test('has no argument when the command line is empty', () {
      expect(commandLineArguments(const []), isEmpty);
    });
  });

  group('the desktop entry', () {
    final entry = File('linux/cn.iouf.tune.desktop').readAsLinesSync();

    test('names the audio types the player understands', () {
      final mimeLine = entry.firstWhere(
        (line) => line.startsWith('MimeType='),
        orElse: () => fail('the desktop entry names no audio type'),
      );
      final types = mimeLine
          .substring('MimeType='.length)
          .split(';')
          .where((type) => type.isNotEmpty)
          .toList();

      expect(types, supportedAudioMimeTypes);
    });

    test('takes the files the desktop hands over', () {
      final execLine = entry.firstWhere(
        (line) => line.startsWith('Exec='),
        orElse: () => fail('the desktop entry names no command'),
      );

      expect(execLine, contains('%U'));
    });
  });
}
