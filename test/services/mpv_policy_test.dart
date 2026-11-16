import 'package:flutter_test/flutter_test.dart';
import 'package:tune/data/services/mpv_policy.dart';

void main() {
  group('MpvPolicy', () {
    test('默认只留内存缓存，不声明缓存目录', () {
      const policy = MpvPolicy();

      expect(policy.usesDiskCache, isFalse);
      final properties = policy.toProperties();
      expect(properties['cache'], 'yes');
      expect(properties['cache-on-disk'], 'no');
      // 关键：磁盘缓存关着时不要给 mpv 一个空目录，否则它会把空串解析成
      // `-` 然后每个流打印一条 "Failed to create file cache"。
      expect(properties.containsKey('demuxer-cache-dir'), isFalse);
    });

    test('指定目录即启用磁盘缓存', () {
      const policy = MpvPolicy(diskCacheDirectory: '/tmp/tune-stream');

      expect(policy.usesDiskCache, isTrue);
      final properties = policy.toProperties();
      expect(properties['cache-on-disk'], 'yes');
      expect(properties['demuxer-cache-dir'], '/tmp/tune-stream');
    });

    test('内存额度同时作为两个方向的解复用缓存', () {
      const policy = MpvPolicy(bufferBytes: 1234);

      final properties = policy.toProperties();
      expect(properties['demuxer-max-bytes'], '1234');
      expect(properties['demuxer-max-back-bytes'], '1234');
    });

    test('默认额度是 8 MiB', () {
      expect(MpvPolicy.defaultBufferBytes, 8 * 1024 * 1024);
      const policy = MpvPolicy();
      expect(policy.bufferBytes, MpvPolicy.defaultBufferBytes);
    });
  });
}
