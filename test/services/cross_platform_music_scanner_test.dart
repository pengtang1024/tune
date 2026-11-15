import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tune/data/services/cross_platform_music_scanner.dart';

/// A scan is read from its two lines: the start says where it reads and in
/// which mode, the finish says what it found. A batch must write exactly one
/// of each, whatever entry the library came through (docs/conventions.md).
void main() {
  late Directory root;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('tune_scan_log');
  });

  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  /// Runs the scan and collects the lines the app itself writes.
  Future<List<String>> linesOf(Future<Object?> Function() run) async {
    final lines = <String>[];
    await runZoned(
      run,
      zoneSpecification: ZoneSpecification(
        print: (self, parent, zone, line) => lines.add(line),
      ),
    );
    return lines;
  }

  test('the background entry writes one start line and one finish line',
      () async {
    final scanner = CrossPlatformMusicScannerImpl();
    final lines = await linesOf(
      () => scanner.scanMusicInDirectories([root.path]),
    );

    expect(
      lines.where((line) => line.contains('Scan started:')),
      hasLength(1),
    );
    expect(
      lines.where((line) => line.contains('Scan started: 1 directories, background mode')),
      hasLength(1),
    );
    expect(
      lines.where((line) => line.contains('Scan finished:')),
      hasLength(1),
    );
  });

  test('the progress entry writes one start line and one finish line',
      () async {
    final scanner = CrossPlatformMusicScannerImpl();
    final lines = await linesOf(
      () => scanner.scanMusicInDirectoriesWithProgress([root.path], (_) {}),
    );

    expect(
      lines.where((line) => line.contains('Scan started:')),
      hasLength(1),
    );
    expect(
      lines.where((line) => line.contains('Scan started: 1 directories, progress mode')),
      hasLength(1),
    );
    expect(
      lines.where((line) => line.contains('Scan finished:')),
      hasLength(1),
    );
  });
}
