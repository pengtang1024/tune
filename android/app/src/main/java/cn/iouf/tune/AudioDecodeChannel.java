package cn.iouf.tune;

import android.content.Context;
import android.media.AudioFormat;
import android.media.MediaCodec;
import android.media.MediaExtractor;
import android.media.MediaFormat;
import android.net.Uri;
import android.os.Build;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.RandomAccessFile;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;

// The local speech engines read one shape only: 16 kHz mono 16-bit WAV. A
// phone cannot execute ffmpeg, so the platform decoder does the same job
// here (docs/android.md E5). MediaExtractor reads the container, MediaCodec
// decodes the track, the result is downmixed and linearly resampled, and a
// small WAV header is written in front. Nothing native is bundled.
final class AudioDecodeChannel implements MethodChannel.MethodCallHandler {
  static final String CHANNEL = "cn.iouf.tune/audio_decode";

  private static final int TARGET_RATE = 16000;
  private static final long TIMEOUT_US = 10000;
  private static final long WATCHDOG_US = 120000000L;

  private final Context context;

  AudioDecodeChannel(Context context) {
    this.context = context;
  }

  @Override
  public void onMethodCall(MethodCall call, MethodChannel.Result result) {
    if (!"decodeToWav".equals(call.method)) {
      result.notImplemented();
      return;
    }
    final String path = call.argument("path");
    final String output = call.argument("output");
    try {
      result.success(decodeToWav(path, output));
    } catch (Exception error) {
      result.error("decode_failed", String.valueOf(error.getMessage()), null);
    }
  }

  /** Decodes one track into [output]; false means "not this file". */
  private boolean decodeToWav(String path, String output) throws IOException {
    if (path == null || output == null) return false;
    final File raw = new File(output + ".pcm");
    final MediaExtractor extractor = new MediaExtractor();
    MediaCodec codec = null;
    try {
      open(extractor, path);
      int track = -1;
      MediaFormat format = null;
      for (int i = 0; i < extractor.getTrackCount(); i++) {
        final MediaFormat candidate = extractor.getTrackFormat(i);
        final String mime = candidate.getString(MediaFormat.KEY_MIME);
        if (mime != null && mime.startsWith("audio/")) {
          track = i;
          format = candidate;
          break;
        }
      }
      if (track < 0 || format == null) return false;
      extractor.selectTrack(track);

      codec = MediaCodec.createDecoderByType(format.getString(MediaFormat.KEY_MIME));
      codec.configure(format, null, null, 0);
      codec.start();

      final MediaCodec.BufferInfo info = new MediaCodec.BufferInfo();
      final PcmSink sink = new PcmSink(raw);
      boolean inputDone = false;
      boolean outputDone = false;
      int channels = format.containsKey(MediaFormat.KEY_CHANNEL_COUNT)
          ? format.getInteger(MediaFormat.KEY_CHANNEL_COUNT)
          : 2;
      int sampleRate = format.containsKey(MediaFormat.KEY_SAMPLE_RATE)
          ? format.getInteger(MediaFormat.KEY_SAMPLE_RATE)
          : 44100;
      boolean floatPcm = false;
      final long deadline = System.nanoTime() + WATCHDOG_US * 1000L;

      while (!outputDone) {
        if (System.nanoTime() > deadline) throw new IOException("decode timed out");
        if (!inputDone) {
          final int inputIndex = codec.dequeueInputBuffer(TIMEOUT_US);
          if (inputIndex >= 0) {
            final ByteBuffer buffer = codec.getInputBuffer(inputIndex);
            final int size = buffer == null ? -1 : extractor.readSampleData(buffer, 0);
            if (size < 0) {
              codec.queueInputBuffer(
                  inputIndex, 0, 0, 0, MediaCodec.BUFFER_FLAG_END_OF_STREAM);
              inputDone = true;
            } else {
              codec.queueInputBuffer(inputIndex, 0, size, extractor.getSampleTime(), 0);
              extractor.advance();
            }
          }
        }
        final int outputIndex = codec.dequeueOutputBuffer(info, TIMEOUT_US);
        if (outputIndex == MediaCodec.INFO_OUTPUT_FORMAT_CHANGED) {
          final MediaFormat changed = codec.getOutputFormat();
          channels = changed.getInteger(MediaFormat.KEY_CHANNEL_COUNT);
          sampleRate = changed.getInteger(MediaFormat.KEY_SAMPLE_RATE);
          floatPcm = isFloat(changed);
        } else if (outputIndex >= 0) {
          final ByteBuffer buffer = codec.getOutputBuffer(outputIndex);
          if (buffer != null && info.size > 0) {
            buffer.position(info.offset);
            buffer.limit(info.offset + info.size);
            sink.write(buffer, channels, floatPcm);
          }
          codec.releaseOutputBuffer(outputIndex, false);
          if ((info.flags & MediaCodec.BUFFER_FLAG_END_OF_STREAM) != 0) outputDone = true;
        }
      }
      sink.close();
      return writeWav(raw, sampleRate, new File(output));
    } finally {
      if (codec != null) {
        try {
          codec.stop();
        } catch (Exception ignored) {
          // A codec that never started has nothing to stop.
        }
        codec.release();
      }
      extractor.release();
      //noinspection ResultOfMethodCallIgnored
      raw.delete();
    }
  }

  private void open(MediaExtractor extractor, String path) throws IOException {
    if (path.startsWith("content://")) {
      extractor.setDataSource(context, Uri.parse(path), null);
    } else {
      extractor.setDataSource(path);
    }
  }

  private static boolean isFloat(MediaFormat format) {
    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.N) return false;
    if (!format.containsKey(MediaFormat.KEY_PCM_ENCODING)) return false;
    return format.getInteger(MediaFormat.KEY_PCM_ENCODING) == AudioFormat.ENCODING_PCM_FLOAT;
  }

  /** Downmixes every decoded buffer to one mono 16-bit track on disk. */
  private static final class PcmSink {
    private final FileOutputStream out;
    private final ByteBuffer shorts = ByteBuffer.allocate(2).order(ByteOrder.LITTLE_ENDIAN);

    PcmSink(File file) throws IOException {
      this.out = new FileOutputStream(file, false);
    }

    void write(ByteBuffer buffer, int channels, boolean floatPcm) throws IOException {
      final ByteBuffer source = buffer.order(ByteOrder.nativeOrder());
      final int bytesPerSample = floatPcm ? 4 : 2;
      final int frames = buffer.remaining() / (bytesPerSample * channels);
      final ByteBuffer mono = ByteBuffer.allocate(frames * 2).order(ByteOrder.LITTLE_ENDIAN);
      for (int frame = 0; frame < frames; frame++) {
        float sum = 0;
        for (int channel = 0; channel < channels; channel++) {
          sum += floatPcm ? source.getFloat() : source.getShort() / 32768.0f;
        }
        final int sample = Math.round((sum / channels) * 32767.0f);
        mono.putShort((short) Math.max(-32768, Math.min(32767, sample)));
      }
      out.write(mono.array(), 0, mono.position());
    }

    void close() throws IOException {
      out.close();
    }
  }

  /**
   * Resamples the mono PCM to 16 kHz and writes the header in front. The
   * header sizes are patched after the data, so nothing is buffered twice.
   */
  private static boolean writeWav(File raw, int inRate, File wav) throws IOException {
    if (inRate <= 0 || !raw.exists() || raw.length() == 0) return false;
    if (!wav.getParentFile().exists() && !wav.getParentFile().mkdirs()) return false;
    final double step = (double) inRate / TARGET_RATE;
    try (RandomAccessFile input = new RandomAccessFile(raw, "r");
        RandomAccessFile output = new RandomAccessFile(wav, "rw")) {
      output.setLength(0);
      output.write(new byte[44]);
      long samples = 0;
      final byte[] chunkBytes = new byte[64 * 1024];
      final short[] chunk = new short[chunkBytes.length / 2];
      final ByteBuffer outBuffer = ByteBuffer.allocate(64 * 1024).order(ByteOrder.LITTLE_ENDIAN);
      double next = 0;
      long base = 0;
      int read;
      while ((read = input.read(chunkBytes)) > 0) {
        final int count = read / 2;
        ByteBuffer.wrap(chunkBytes, 0, read).order(ByteOrder.LITTLE_ENDIAN).asShortBuffer().get(chunk, 0, count);
        while (next < base + count - 1) {
          final int index = (int) (next - base);
          final double fraction = next - index;
          final int first = chunk[index];
          final int second = index + 1 < count ? chunk[index + 1] : first;
          outBuffer.putShort((short) Math.round(first + (second - first) * fraction));
          samples++;
          next += step;
          if (outBuffer.remaining() < 2) flush(output, outBuffer);
        }
        base += count;
      }
      flush(output, outBuffer);
      final long dataBytes = samples * 2;
      output.seek(0);
      output.write(wavHeader((int) dataBytes));
      return dataBytes > 0;
    }
  }

  private static void flush(RandomAccessFile output, ByteBuffer buffer) throws IOException {
    if (buffer.position() == 0) return;
    output.write(buffer.array(), 0, buffer.position());
    buffer.clear();
  }

  private static byte[] wavHeader(int dataBytes) {
    final ByteBuffer header = ByteBuffer.allocate(44).order(ByteOrder.LITTLE_ENDIAN);
    header.put("RIFF".getBytes());
    header.putInt(36 + dataBytes);
    header.put("WAVE".getBytes());
    header.put("fmt ".getBytes());
    header.putInt(16);
    header.putShort((short) 1); // PCM
    header.putShort((short) 1); // mono
    header.putInt(TARGET_RATE);
    header.putInt(TARGET_RATE * 2); // byte rate
    header.putShort((short) 2); // block align
    header.putShort((short) 16); // bits per sample
    header.put("data".getBytes());
    header.putInt(dataBytes);
    return header.array();
  }
}
