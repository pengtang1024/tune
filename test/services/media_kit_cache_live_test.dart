import 'package:flutter_test/flutter_test.dart';
import 'package:media_kit/media_kit.dart';
import 'package:tune/data/services/mpv_policy.dart';

/// 联网用例：验证「按 MpvPolicy 关掉磁盘缓存后，mpv 不再报建不出缓存文件」。
///
/// 这条断言必须碰真实的 libmpv 与真实网络，所以文件名带 `live`，不在
/// `./tool/check.sh` 的确定性门禁里；`--live` 或直接跑这个文件时才执行。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('关掉磁盘缓存后不再出现 file cache 报错', () async {
    MediaKit.ensureInitialized();
    const policy = MpvPolicy();
    final player = Player(
      configuration: PlayerConfiguration(
        title: 'Tune test',
        bufferSize: policy.bufferBytes,
        logLevel: MPVLogLevel.error,
      ),
    );

    final errors = <String>[];
    final subscription = player.stream.error.listen(errors.add);

    final native = player.platform;
    expect(native, isA<NativePlayer>());
    for (final entry in policy.toProperties().entries) {
      await (native as NativePlayer).setProperty(entry.key, entry.value);
    }

    // 一个短小的公开测试音频；只为触发「开流 → 建缓存」这条路径。
    await player.open(
      Media('https://archive.org/download/testmp3testfile/mpthreetest.mp3'),
      play: false,
    );
    await Future<void>.delayed(const Duration(seconds: 6));

    await subscription.cancel();
    await player.dispose();

    expect(
      errors.where((error) => error.contains('file cache')),
      isEmpty,
      reason: '缓存策略应让 mpv 不再尝试建磁盘缓存文件：$errors',
    );
  }, timeout: const Timeout(Duration(minutes: 2)));
}
