import 'dart:io';
import 'dart:typed_data';

/// A WAV file built byte by byte, so the tests can say exactly what the
/// header claims — including claims no real encoder would make.
Uint8List wavBytes({
  int sampleRate = 16000,
  int channels = 1,
  int bitsPerSample = 16,
  int frames = 16000,
  int? claimedDataSize,
}) {
  final bytesPerFrame = channels * (bitsPerSample ~/ 8);
  final dataSize = frames * bytesPerFrame;
  final header = ByteData(44);
  void ascii(int at, String text) {
    for (var i = 0; i < text.length; i++) {
      header.setUint8(at + i, text.codeUnitAt(i));
    }
  }

  ascii(0, 'RIFF');
  header.setUint32(4, 36 + dataSize, Endian.little);
  ascii(8, 'WAVE');
  ascii(12, 'fmt ');
  header.setUint32(16, 16, Endian.little);
  header.setUint16(20, 1, Endian.little);
  header.setUint16(22, channels, Endian.little);
  header.setUint32(24, sampleRate, Endian.little);
  header.setUint32(28, sampleRate * bytesPerFrame, Endian.little);
  header.setUint16(32, bytesPerFrame, Endian.little);
  header.setUint16(34, bitsPerSample, Endian.little);
  ascii(36, 'data');
  header.setUint32(40, claimedDataSize ?? dataSize, Endian.little);

  final builder = BytesBuilder(copy: false)
    ..add(header.buffer.asUint8List())
    ..add(Uint8List(dataSize));
  return builder.takeBytes();
}

File writeWavFile(
  Directory folder,
  String name, {
  int sampleRate = 16000,
  int channels = 1,
  int bitsPerSample = 16,
  int frames = 16000,
  int? claimedDataSize,
}) {
  final file = File('${folder.path}/$name');
  file.writeAsBytesSync(
    wavBytes(
      sampleRate: sampleRate,
      channels: channels,
      bitsPerSample: bitsPerSample,
      frames: frames,
      claimedDataSize: claimedDataSize,
    ),
  );
  return file;
}
