import 'dart:io';

import 'package:flutter/services.dart';
import 'package:tune/data/services/smart_lyrics/audio_decoder.dart';

/// The Android decoder: MediaExtractor + MediaCodec on the native side.
///
/// No FFmpeg is bundled — the platform decoder is the only extra code, and
/// it resamples to exactly the 16 kHz mono WAV the engines read, so the
/// service's audio path stays one shape on every platform.
class MediaCodecAudioDecoder implements AudioDecoder {
  const MediaCodecAudioDecoder();

  static const MethodChannel channel = MethodChannel('cn.iouf.tune/audio_decode');

  @override
  Future<File?> decodeToWav(File source, {required Directory folder}) async {
    final output = File('${folder.path}/decoded.wav');
    final ok = await channel.invokeMethod<bool>('decodeToWav', {
      'path': source.path,
      'output': output.path,
    });
    if (ok != true || !await output.exists()) return null;
    return output;
  }
}
