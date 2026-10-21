import 'package:flutter_test/flutter_test.dart';
import 'package:tune/shared/utils/readable_address.dart';

/// An address is written by a program, and a reader reads it better when the
/// program stops spelling out what the reader already knows.
void main() {
  test('a path stays a path', () {
    expect(
      readableAddress('/home/pt/Music/Beatles/Yesterday.mp3'),
      '/home/pt/Music/Beatles/Yesterday.mp3',
    );
  });

  test('the scheme of a file goes, the path stays', () {
    expect(
      readableAddress('file:///home/pt/Music/Beatles/Yesterday.mp3'),
      '/home/pt/Music/Beatles/Yesterday.mp3',
    );
  });

  test('an escaped character is written as the character', () {
    expect(
      readableAddress('http://host/a%20track%2Fone.mp3'),
      'http://host/a track/one.mp3',
    );
  });

  test('an address of a source keeps its scheme', () {
    expect(
      readableAddress('tune://openverse/12345'),
      'tune://openverse/12345',
    );
  });

  test('a broken escape stays as it is', () {
    expect(readableAddress('/music/100%'), '/music/100%');
    expect(readableAddress('/music/100%zz'), '/music/100%zz');
  });

  test('the room around an address is dropped', () {
    expect(readableAddress('  /music/night.flac  '), '/music/night.flac');
  });
}
