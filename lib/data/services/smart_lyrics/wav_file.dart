import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

typedef _Format = ({int audioFormat, int channels, int rate, int bits});

/// The header facts of a local WAV file, read without decoding the audio.
///
/// The ASR binaries read the header to size their buffers, so the header is
/// also where an impossible file comes from: a `data` chunk that promises
/// more bytes than the file holds turns into a sample count no machine can
/// hold (docs/smart-lyrics.md §6.2). Reading it here is cheap — a few dozen
/// bytes — and it is the only place that knows what a readable WAV is.
class WavFile {
  final File file;

  /// 1 is plain PCM, the only encoding the binaries read.
  final int audioFormat;
  final int sampleRate;
  final int channels;
  final int bitsPerSample;

  /// Where the samples start and how many bytes of them there are.
  final int dataOffset;
  final int dataSize;

  const WavFile({
    required this.file,
    required this.audioFormat,
    required this.sampleRate,
    required this.channels,
    required this.bitsPerSample,
    required this.dataOffset,
    required this.dataSize,
  });

  int get _frameBytes => channels * (bitsPerSample ~/ 8);

  Duration get duration =>
      Duration(microseconds: dataSize * 1000000 ~/ (_frameBytes * sampleRate));

  /// Whether the audio is what the engines expect: 16 kHz mono 16-bit PCM.
  bool get isSpeechReady =>
      audioFormat == 1 &&
      sampleRate == 16000 &&
      channels == 1 &&
      bitsPerSample == 16;

  /// Reads the header, or `null` when the file is not a WAV this machine can
  /// read: no RIFF/WAVE mark, no `fmt ` chunk, or a `data` chunk longer than
  /// the file itself.
  static Future<WavFile?> read(File file) async {
    RandomAccessFile? handle;
    try {
      handle = await file.open();
      final length = await handle.length();
      if (length < 44) return null;
      final head = await _readAt(handle, 0, 12);
      if (String.fromCharCodes(head, 0, 4) != 'RIFF' ||
          String.fromCharCodes(head, 8, 12) != 'WAVE') {
        return null;
      }
      _Format? format;
      var position = 12;
      while (position + 8 <= length) {
        final header = await _readAt(handle, position, 8);
        final id = String.fromCharCodes(header, 0, 4);
        final size = ByteData.sublistView(
          header,
          4,
          8,
        ).getUint32(0, Endian.little);
        final body = position + 8;
        if (id == 'fmt ') {
          format = await _formatAt(handle, body, size);
        } else if (id == 'data') {
          return _dataAt(
            file: file,
            format: format,
            length: length,
            body: body,
            size: size,
          );
        }
        // Chunks are word aligned: an odd size carries one byte of padding.
        position = body + size + (size.isOdd ? 1 : 0);
      }
      return null;
    } on FileSystemException {
      return null;
    } finally {
      await handle?.close();
    }
  }

  static Future<_Format?> _formatAt(
    RandomAccessFile handle,
    int body,
    int size,
  ) async {
    final fmt = await _readAt(handle, body, math.min(size, 40));
    if (fmt.length < 16) return null;
    final view = ByteData.sublistView(fmt);
    return (
      audioFormat: view.getUint16(0, Endian.little),
      channels: view.getUint16(2, Endian.little),
      rate: view.getUint32(4, Endian.little),
      bits: view.getUint16(14, Endian.little),
    );
  }

  static WavFile? _dataAt({
    required File file,
    required _Format? format,
    required int length,
    required int body,
    required int size,
  }) {
    // A header promising more than the file holds is a broken file, not a
    // long one: the sample count would be fiction.
    if (format == null || size == 0 || size > length - body) return null;
    if (format.channels == 0 || format.rate == 0 || format.bits == 0) {
      return null;
    }
    return WavFile(
      file: file,
      audioFormat: format.audioFormat,
      sampleRate: format.rate,
      channels: format.channels,
      bitsPerSample: format.bits,
      dataOffset: body,
      dataSize: size,
    );
  }

  static Future<Uint8List> _readAt(
    RandomAccessFile handle,
    int position,
    int count,
  ) async {
    await handle.setPosition(position);
    return handle.read(count);
  }
}
