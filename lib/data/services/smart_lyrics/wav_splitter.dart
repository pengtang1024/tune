import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:tune/data/services/smart_lyrics/wav_file.dart';

/// One piece of a WAV file, ready to be handed to a binary on its own.
typedef WavPart = ({File file, Duration offset, Duration length});

/// Cutting a WAV into pieces the recognizer can hold at once.
///
/// The encoder builds a T×T self-attention map from the whole file, so a
/// 42-minute track asks for tens of gigabytes (docs/smart-lyrics.md §6.2).
/// The pieces are byte ranges of the same PCM data with a fresh header, so
/// no decoding happens here, and each piece is a plain file the binary reads
/// exactly as it would read the original.
extension WavSplitting on WavFile {
  int get _frameBytes => channels * (bitsPerSample ~/ 8);

  int _bytesOf(Duration chunk) {
    final frames = chunk.inMicroseconds * sampleRate ~/ 1000000;
    final bytes = frames * _frameBytes;
    // A chunk shorter than one frame would loop forever on a divided size.
    return bytes < _frameBytes ? _frameBytes : bytes;
  }

  /// How many pieces [chunk] long the audio becomes.
  int partCount(Duration chunk) {
    final bytes = _bytesOf(chunk);
    return (dataSize + bytes - 1) ~/ bytes;
  }

  /// Writes the audio as at most [chunk] long pieces into [folder].
  ///
  /// One piece exists at a time — the caller deletes it after the run —
  /// because an hour of 16 kHz mono audio is 115 MB.
  Stream<WavPart> parts({
    required Directory folder,
    required Duration chunk,
  }) async* {
    final bytes = _bytesOf(chunk);
    final source = await file.open();
    try {
      for (var start = 0; start < dataSize; start += bytes) {
        final span = math.min(bytes, dataSize - start);
        await source.setPosition(dataOffset + start);
        final samples = await _readFully(source, span);
        if (samples.isEmpty) break;
        // A file that ended early gets a header for what it actually
        // holds, never for the bytes it promised.
        final actual = samples.length;
        final target = File('${folder.path}/part-${start ~/ bytes}.wav');
        final sink = await target.open(mode: FileMode.write);
        try {
          await sink.writeFrom(_headerFor(actual));
          await sink.writeFrom(samples);
        } finally {
          await sink.close();
        }
        yield (
          file: target,
          offset: Duration(
            microseconds: start * 1000000 ~/ (_frameBytes * sampleRate),
          ),
          length: Duration(
            microseconds: actual * 1000000 ~/ (_frameBytes * sampleRate),
          ),
        );
      }
    } finally {
      await source.close();
    }
  }

  /// Reads [count] bytes, or what is left when the file ends early.
  static Future<Uint8List> _readFully(
    RandomAccessFile source,
    int count,
  ) async {
    final builder = BytesBuilder(copy: false);
    var remaining = count;
    while (remaining > 0) {
      final chunk = await source.read(remaining);
      if (chunk.isEmpty) break;
      builder.add(chunk);
      remaining -= chunk.length;
    }
    return builder.takeBytes();
  }

  /// A canonical 44-byte header for one piece of 16-bit PCM.
  Uint8List _headerFor(int bytes) {
    final header = ByteData(44);
    void ascii(int at, String text) {
      for (var i = 0; i < text.length; i++) {
        header.setUint8(at + i, text.codeUnitAt(i));
      }
    }

    ascii(0, 'RIFF');
    header.setUint32(4, 36 + bytes, Endian.little);
    ascii(8, 'WAVE');
    ascii(12, 'fmt ');
    header.setUint32(16, 16, Endian.little);
    header.setUint16(20, audioFormat, Endian.little);
    header.setUint16(22, channels, Endian.little);
    header.setUint32(24, sampleRate, Endian.little);
    header.setUint32(28, sampleRate * _frameBytes, Endian.little);
    header.setUint16(32, _frameBytes, Endian.little);
    header.setUint16(34, bitsPerSample, Endian.little);
    ascii(36, 'data');
    header.setUint32(40, bytes, Endian.little);
    return header.buffer.asUint8List();
  }
}
