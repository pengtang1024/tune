import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:tune/domain/models/equalizer_settings.dart';
import 'package:tune/features/player/application/equalizer_controller.dart';

import '../../app/fake_audio_equalizer_backend.dart';
import '../../services/fake_persistence.dart';

/// 记下每次 setString 的键。
///
/// [FakePersistenceService] 只存值不计数，而「防抖后只落盘一次」必须靠次数
/// 断言才算验证，所以在测试内包一层，不改动共享替身。
class _RecordingPersistence extends FakePersistenceService {
  final List<String> writtenKeys = <String>[];

  @override
  Future<bool> setString(String key, String value) {
    writtenKeys.add(key);
    return super.setString(key, value);
  }
}

/// 均衡器控制器的应用层契约：读一次偏好、把每次变更立刻推给后端、
/// 落盘走 400 ms 防抖、dispose 补写最后一笔。
void main() {
  const String key = equalizerPreferenceKey;
  const List<double> storedCurve = <double>[4, 3, 1, -1, -2, 0, 2, 4, 4, 3];

  group('构造与 restore', () {
    test('没有存量时保持默认：关闭、平直、10 段', () {
      final persistence = _RecordingPersistence();
      final backend = FakeAudioEqualizerBackend();
      final controller = EqualizerController(persistence, backend);
      addTearDown(controller.dispose);

      expect(controller.state.enabled, isFalse);
      expect(controller.state.isFlat, isTrue);
      expect(controller.state.gains.length, EqualizerSettings.bandCount);
      expect(controller.isAvailable, isTrue);
      expect(
        persistence.writtenKeys,
        isEmpty,
        reason: '只读一次偏好，不该顺手写一次',
      );
    });

    test('有存量时读回 enabled 与 gains，restore 把它推给后端', () async {
      final persistence = _RecordingPersistence();
      persistence.values[key] = jsonEncode(<String, Object?>{
        'version': EqualizerSettings.schemaVersion,
        'enabled': true,
        'gains': storedCurve,
      });
      final backend = FakeAudioEqualizerBackend();
      final controller = EqualizerController(persistence, backend);
      addTearDown(controller.dispose);

      expect(controller.state.enabled, isTrue);
      expect(controller.state.gains, storedCurve);

      await controller.restore();

      expect(backend.applied.length, 1, reason: '启动时只推一次存量曲线');
      expect(backend.last, controller.state);
      expect(backend.last!.enabled, isTrue);
      expect(backend.last!.gains, storedCurve);
      expect(backend.last!.preampDb, -4);
    });

    test('存量损坏时不崩，回落到默认并照常 restore', () async {
      final persistence = _RecordingPersistence();
      persistence.values[key] = '{"version":1,"enabled":true,"gains":[1,2';
      final backend = FakeAudioEqualizerBackend();
      final controller = EqualizerController(persistence, backend);
      addTearDown(controller.dispose);

      expect(controller.state.enabled, isFalse);
      expect(controller.state.isFlat, isTrue);

      await controller.restore();

      expect(backend.applied.length, 1);
      expect(backend.last!.enabled, isFalse);
      expect(backend.last!.isFlat, isTrue);
    });

    test('后端不可用时 restore 不调 apply', () async {
      final persistence = _RecordingPersistence();
      final backend = FakeAudioEqualizerBackend(isAvailable: false);
      final controller = EqualizerController(persistence, backend);
      addTearDown(controller.dispose);

      expect(controller.isAvailable, isFalse);

      await controller.restore();

      expect(backend.applied, isEmpty);
    });

    test('没有后端（移动端）时状态照常可改，不崩也不写盘', () {
      final persistence = _RecordingPersistence();
      final controller = EqualizerController(persistence, null);
      addTearDown(controller.dispose);

      expect(controller.isAvailable, isFalse);
      controller.setGain(0, 6);

      expect(controller.state.gainAt(0), 6);
      expect(persistence.writtenKeys, isEmpty, reason: '防抖窗口还没到点');
    });
  });

  group('setGain 立刻推给后端', () {
    test('可用后端收到新曲线，且只收到一份', () {
      final backend = FakeAudioEqualizerBackend();
      final controller = EqualizerController(_RecordingPersistence(), backend);
      addTearDown(controller.dispose);

      controller.setGain(5, 6);

      expect(controller.state.gainAt(5), 6);
      expect(controller.state.enabled, isFalse, reason: '调一个频段不等于打开开关');
      expect(backend.applied.length, 1);
      expect(backend.last, controller.state);
      expect(backend.last!.gainAt(5), 6);
    });

    test('后端不可用时不调 apply', () {
      final backend = FakeAudioEqualizerBackend(isAvailable: false);
      final controller = EqualizerController(_RecordingPersistence(), backend);
      addTearDown(controller.dispose);

      controller.setGain(0, 6);

      expect(controller.state.gainAt(0), 6);
      expect(backend.applied, isEmpty);
    });

    test('值没变时不调 apply', () {
      final backend = FakeAudioEqualizerBackend();
      final controller = EqualizerController(_RecordingPersistence(), backend);
      addTearDown(controller.dispose);

      controller.setGain(0, 0);

      expect(backend.applied, isEmpty);
    });

    test('开关变化也送出去，关闭时由后端清空滤镜图', () {
      final backend = FakeAudioEqualizerBackend();
      final controller = EqualizerController(_RecordingPersistence(), backend);
      addTearDown(controller.dispose);

      controller.setGain(5, 6);
      controller.setEnabled(true);
      controller.setEnabled(false);

      expect(backend.applied.length, 3);
      expect(backend.applied[1].enabled, isTrue);
      expect(backend.applied.last.enabled, isFalse);
      expect(backend.applied.last.gainAt(5), 6, reason: '关掉开关不清曲线，再打开时还是它');
    });
  });

  group('applyPreset 与 reset 走同一条通道', () {
    test('命中预设时换曲线并推后端，未知 id 原样忽略', () {
      final backend = FakeAudioEqualizerBackend();
      final controller = EqualizerController(_RecordingPersistence(), backend);
      addTearDown(controller.dispose);

      controller.applyPreset('bass');

      expect(controller.state.gains, EqualizerPresets.bass.gains);
      expect(controller.state.presetId, 'bass');
      expect(backend.applied.length, 1);

      controller.applyPreset('nonsense');

      expect(controller.state.gains, EqualizerPresets.bass.gains);
      expect(backend.applied.length, 1, reason: '未知预设不该产生一次无效下发');
    });

    test('重复点同一个预设不再下发滤镜图', () {
      // 判等读的是 presetId（由增益反推），不是 List：List 的 == 是引用相等，
      // 用它判等会让点亮的 chip 每点一次都重写一遍滤镜图。
      final backend = FakeAudioEqualizerBackend();
      final controller = EqualizerController(_RecordingPersistence(), backend);
      addTearDown(controller.dispose);

      controller.applyPreset('bass');
      controller.applyPreset('bass');

      expect(backend.applied.length, 1, reason: '第二次点击没有可改的东西');
    });

    test('reset 回平并推后端', () {
      final backend = FakeAudioEqualizerBackend();
      final controller = EqualizerController(_RecordingPersistence(), backend);
      addTearDown(controller.dispose);

      controller.setGain(0, 8);
      controller.reset();

      expect(controller.state.isFlat, isTrue);
      expect(controller.state.presetId, EqualizerPresets.flatId);
      expect(backend.applied.last.isFlat, isTrue);
    });
  });

  group('落盘防抖', () {
    test('连续 5 次 setGain 只写一次，值是最后一次', () async {
      final persistence = _RecordingPersistence();
      final backend = FakeAudioEqualizerBackend();
      final controller = EqualizerController(persistence, backend);
      addTearDown(controller.dispose);

      for (var band = 0; band < 5; band++) {
        controller.setGain(band, band + 1);
        expect(persistence.writtenKeys, isEmpty, reason: '防抖窗口内不该写盘');
      }
      // 控制器不合并后端调用：每一次移动都送给后端，由 media_kit 侧做
      // 100 ms 的合并（lib/data/services/impl/media_kit_player_service.dart:41）。
      expect(backend.applied.length, 5);

      await Future<void>.delayed(
        equalizerSaveDelay + const Duration(milliseconds: 150),
      );

      expect(persistence.writtenKeys, <String>[key]);
      final saved = EqualizerSettings.fromJson(persistence.getString(key));
      expect(saved.gains, <double>[1, 2, 3, 4, 5, 0, 0, 0, 0, 0]);
      expect(saved, controller.state);
    });

    test('防抖窗口内改回原值就不写盘', () async {
      final persistence = _RecordingPersistence();
      final controller = EqualizerController(
        persistence,
        FakeAudioEqualizerBackend(),
      );
      addTearDown(controller.dispose);

      controller.setGain(0, 6);
      controller.setGain(0, 0);

      await Future<void>.delayed(
        equalizerSaveDelay + const Duration(milliseconds: 150),
      );

      expect(persistence.writtenKeys, isEmpty);
      expect(persistence.values.containsKey(key), isFalse);
    });

    test('dispose 把还没到点的最后一笔写掉，且不会补写第二次', () async {
      final persistence = _RecordingPersistence();
      final controller = EqualizerController(
        persistence,
        FakeAudioEqualizerBackend(),
      );

      controller.setGain(2, 6);
      controller.dispose();

      expect(
        persistence.writtenKeys,
        <String>[key],
        reason: 'dispose 不等待 400 ms，立即补写最后一笔',
      );
      final saved = EqualizerSettings.fromJson(persistence.getString(key));
      expect(saved.gainAt(2), 6);
      expect(saved.enabled, isFalse);

      await Future<void>.delayed(
        equalizerSaveDelay + const Duration(milliseconds: 150),
      );
      expect(
        persistence.writtenKeys,
        <String>[key],
        reason: '定时器在 dispose 里取消，不会第二次写入',
      );
    });

    test('没有改动时 dispose 不写盘', () {
      final persistence = _RecordingPersistence();
      final controller = EqualizerController(
        persistence,
        FakeAudioEqualizerBackend(),
      );

      controller.dispose();

      expect(persistence.writtenKeys, isEmpty);
    });
  });

  group('存为预设与删除预设', () {
    test('存下的曲线立刻多一个用户预设，落了盘还能读回来', () async {
      final persistence = _RecordingPersistence();
      final backend = FakeAudioEqualizerBackend();
      final controller = EqualizerController(persistence, backend);
      addTearDown(controller.dispose);

      controller.setGain(0, 7);
      controller.setGain(1, 5);
      final appliedBefore = backend.applied.length;

      controller.savePreset('  我的低音  ');

      expect(controller.state.userPresets.length, 1);
      final kept = controller.state.userPresets.single;
      expect(kept.name, '我的低音', reason: '名字两头的空白不留');
      expect(kept.id, startsWith(EqualizerPresets.userPresetPrefix));
      expect(kept.gains, controller.state.gains);
      expect(
        controller.state.presetId,
        kept.id,
        reason: '刚存下的曲线就是当前曲线，界面该点亮这一条',
      );
      expect(
        backend.applied.length,
        appliedBefore + 1,
        reason: '存曲线不改声音，但状态换了，照常下发一次',
      );

      await Future<void>.delayed(
        equalizerSaveDelay + const Duration(milliseconds: 150),
      );

      final saved = EqualizerSettings.fromJson(persistence.getString(key));
      expect(saved.userPresets.single.name, '我的低音');
      expect(saved.userPresets.single.gains, controller.state.gains);
    });

    test('空名字不存，也不打扰后端', () {
      final backend = FakeAudioEqualizerBackend();
      final controller = EqualizerController(_RecordingPersistence(), backend);
      addTearDown(controller.dispose);

      controller.setGain(0, 4);
      final applied = backend.applied.length;

      controller.savePreset('   ');

      expect(controller.state.userPresets, isEmpty);
      expect(backend.applied.length, applied);
    });

    test('同名再存一次是覆盖曲线，id 与条数都不变', () {
      final controller = EqualizerController(
        _RecordingPersistence(),
        FakeAudioEqualizerBackend(),
      );
      addTearDown(controller.dispose);

      controller.setGain(0, 4);
      controller.savePreset('我的低音');
      final firstId = controller.state.userPresets.single.id;

      controller.setGain(0, 9);
      controller.savePreset('我的低音');

      expect(controller.state.userPresets.length, 1);
      expect(controller.state.userPresets.single.id, firstId);
      expect(controller.state.userPresets.single.gains[0], 9);
    });

    test('删掉正在用的预设回落到自定义，别的预设不受影响', () {
      final backend = FakeAudioEqualizerBackend();
      final controller = EqualizerController(_RecordingPersistence(), backend);
      addTearDown(controller.dispose);

      controller.setGain(0, 4);
      controller.savePreset('低音一');
      final first = controller.state.userPresets.single.id;

      controller.reset();
      controller.setGain(2, 6);
      controller.savePreset('低音二');
      final second = controller.state.userPresets
          .firstWhere((preset) => preset.name == '低音二')
          .id;

      controller.applyPreset(second);
      final applied = backend.applied.length;

      controller.deletePreset(second);

      expect(controller.state.userPresets.map((preset) => preset.id), <String>[
        first,
      ]);
      expect(
        controller.state.presetId,
        EqualizerPresets.customId,
        reason: '曲线还在，只是不再是任何一条预设',
      );
      expect(
        backend.applied.length,
        applied + 1,
        reason: '删预设不动声音，但状态换了要下发',
      );
    });

    test('删一个不存在的 id 不产生下发', () {
      final backend = FakeAudioEqualizerBackend();
      final controller = EqualizerController(_RecordingPersistence(), backend);
      addTearDown(controller.dispose);

      controller.deletePreset('user-nope');

      expect(backend.applied, isEmpty);
    });

    test('用户预设能被 applyPreset 选中', () {
      final controller = EqualizerController(
        _RecordingPersistence(),
        FakeAudioEqualizerBackend(),
      );
      addTearDown(controller.dispose);

      controller.setGain(3, 5);
      controller.savePreset('中音');
      final id = controller.state.userPresets.single.id;

      controller.reset();
      controller.applyPreset(id);

      expect(controller.state.gainAt(3), 5);
      expect(controller.state.presetId, id);
    });
  });
}
