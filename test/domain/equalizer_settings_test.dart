import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:tune/domain/models/equalizer_settings.dart';

/// 均衡器设置的纯数据契约。
///
/// 这些规则直接决定两件事：坏偏好会不会拦住启动、滤镜链会不会拿到越界值。
/// 所以每条断言都落在具体数值上，不用 isNotNull 这类空断言凑数。
void main() {
  // 文档里的示例曲线（docs/equalizer.md §数据模型），不是任何内置预设：
  // 用它验证「原样存取」，预设识别另开一组。
  const List<double> storedCurve = <double>[4, 3, 1, -1, -2, 0, 2, 4, 4, 3];

  group('toJson / fromJson 往返', () {
    test('写出的 JSON 带版本号与 10 段增益，读回后完全相等', () {
      const settings = EqualizerSettings(
        enabled: true,
        gains: storedCurve,
      );

      final raw = settings.toJson();
      final decoded = jsonDecode(raw) as Map<String, dynamic>;

      expect(decoded['version'], EqualizerSettings.schemaVersion);
      expect(decoded['enabled'], isTrue);
      expect(decoded['gains'], storedCurve);
      expect(
        (decoded['gains'] as List<dynamic>).length,
        EqualizerSettings.bandCount,
        reason: '存下来的曲线必须正好 10 段，读的人不用再猜长度',
      );

      final restored = EqualizerSettings.fromJson(raw);

      expect(restored, settings);
      expect(restored.gains, storedCurve);
      expect(restored.toJson(), raw);
    });

    test('null / 空串 / 空对象都回落到关闭的平直曲线', () {
      for (final raw in const <String?>[null, '', '{}']) {
        final settings = EqualizerSettings.fromJson(raw);

        expect(settings.enabled, isFalse, reason: 'raw=$raw');
        expect(settings.gains.length, EqualizerSettings.bandCount);
        expect(settings.gains, everyElement(0), reason: 'raw=$raw');
        expect(settings.isFlat, isTrue, reason: 'raw=$raw');
        expect(settings.presetId, EqualizerPresets.flatId, reason: 'raw=$raw');
      }
    });

    test('损坏 JSON、非对象 JSON、未知版本都不抛异常，回落到默认', () {
      const List<String> unreadable = <String>[
        '{"version":1,"enabled":true,"gains":[1,2', // 截断
        'not json at all',
        'null',
        '[]',
        '{"version":1,"enabled":true,"gains":"flat"}',
        '{"version":2,"enabled":true,"gains":[1,2,3,4,5,6,7,8,9,10]}',
        '{"enabled":true,"gains":[1,2,3,4,5,6,7,8,9,10]}',
      ];

      for (final raw in unreadable) {
        final settings = EqualizerSettings.fromJson(raw);

        expect(settings.enabled, isFalse, reason: raw);
        expect(settings.isFlat, isTrue, reason: raw);
        expect(settings.gains.length, EqualizerSettings.bandCount, reason: raw);
      }
    });

    test('gains 长度不足 10 段：缺的段补 0 dB，enabled 照旧', () {
      // 可读的曲线按长度/范围归一，不整体丢弃（docs/equalizer.md §数据模型
      // 「读取时按长度、范围、NaN 归一」）；只有读不出信封时才回落 flat。
      final settings = EqualizerSettings.fromJson(
        '{"version":1,"enabled":true,"gains":[5,-3,1]}',
      );

      expect(settings.enabled, isTrue);
      expect(settings.gains, <double>[5, -3, 1, 0, 0, 0, 0, 0, 0, 0]);
      expect(settings.gains.length, EqualizerSettings.bandCount);
    });

    test('gains 长度超过 10 段：截断到前 10 段', () {
      final settings = EqualizerSettings.fromJson(
        '{"version":1,"enabled":true,"gains":[1,2,3,4,5,6,7,8,9,10,11,12]}',
      );

      expect(settings.gains, <double>[1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);
    });

    test('gains 越界（99 / -99）先按 step 取整再 clamp 到 ±12 dB', () {
      final settings = EqualizerSettings.fromJson(
        '{"version":1,"enabled":true,"gains":[99,-99,0.4,0.6,3,4,5,6,7,8]}',
      );

      expect(settings.gains, <double>[12, -12, 0, 1, 3, 4, 5, 6, 7, 8]);
    });

    test('gains 里的非数字项按 0 dB 处理', () {
      final settings = EqualizerSettings.fromJson(
        '{"version":1,"enabled":true,"gains":[true,"loud",5]}',
      );

      expect(settings.gains, <double>[0, 0, 5, 0, 0, 0, 0, 0, 0, 0]);
    });

  });

  group('clampGain 的步进与上下限', () {
    test('落在 1 dB 的整数步进上（四舍五入）', () {
      expect(EqualizerSettings.clampGain(3), 3);
      expect(EqualizerSettings.clampGain(3.4), 3);
      expect(EqualizerSettings.clampGain(3.5), 4);
      expect(EqualizerSettings.clampGain(3.6), 4);
      expect(EqualizerSettings.clampGain(-3.4), -3);
      expect(EqualizerSettings.clampGain(-3.5), -4);
    });

    test('夹在 -12 / +12 dB', () {
      expect(EqualizerSettings.clampGain(99), EqualizerSettings.maxGain);
      expect(EqualizerSettings.clampGain(-99), EqualizerSettings.minGain);
      expect(EqualizerSettings.clampGain(12), 12);
      expect(EqualizerSettings.clampGain(-12), -12);
      expect(EqualizerSettings.clampGain(12.4), 12);
    });

    test('NaN / Infinity 归零，不会把脏值送进滤镜链', () {
      expect(EqualizerSettings.clampGain(double.nan), 0);
      expect(EqualizerSettings.clampGain(double.infinity), 0);
      expect(EqualizerSettings.clampGain(double.negativeInfinity), 0);
    });
  });

  group('normalizeGains 固定 10 段', () {
    test('不足补 0、超长截断、越界夹紧', () {
      expect(
        EqualizerSettings.normalizeGains(<double>[5, -3]),
        <double>[5, -3, 0, 0, 0, 0, 0, 0, 0, 0],
      );
      expect(
        EqualizerSettings.normalizeGains(List<double>.filled(12, 13)),
        <double>[12, 12, 12, 12, 12, 12, 12, 12, 12, 12],
      );
    });

    test('空输入就是 10 段平直曲线', () {
      expect(
        EqualizerSettings.normalizeGains(<double>[]),
        EqualizerPresets.flatGains,
      );
    });

    test('NaN 归零', () {
      expect(
        EqualizerSettings.normalizeGains(<double>[double.nan, 3]),
        <double>[0, 3, 0, 0, 0, 0, 0, 0, 0, 0],
      );
    });

    test('返回不可变列表，调用方改不动已经存下的曲线', () {
      final gains = EqualizerSettings.normalizeGains(<double>[1, 2]);

      expect(() => gains[0] = 3, throwsUnsupportedError);
    });
  });

  group('withGain 只动一个频段', () {
    const EqualizerSettings flat = EqualizerSettings.flat(enabled: true);

    test('改第 6 段（1 kHz）不碰其它段，也不动开关', () {
      final moved = flat.withGain(5, 6);

      expect(moved.gains, <double>[0, 0, 0, 0, 0, 6, 0, 0, 0, 0]);
      expect(moved.gainAt(5), 6);
      expect(moved.enabled, isTrue, reason: '调增益不等于打开开关');
      expect(flat.gains, everyElement(0), reason: '原对象不被就地修改');
      expect(moved.presetId, EqualizerPresets.customId);
    });

    test('越界增益先夹紧再写入', () {
      expect(flat.withGain(0, 99).gainAt(0), 12);
      expect(flat.withGain(0, -99).gainAt(0), -12);
      expect(flat.withGain(0, 3.6).gainAt(0), 4);
      expect(flat.withGain(0, 3.4).gainAt(0), 3);
    });

    test('值没变时返回同一个对象，不制造无意义的重建', () {
      expect(identical(flat.withGain(0, 0), flat), isTrue);
      expect(identical(flat.withGain(0, -0.4), flat), isTrue);
    });

    test('频段下标越界时原样返回', () {
      expect(identical(flat.withGain(-1, 6), flat), isTrue);
      expect(
        identical(flat.withGain(EqualizerSettings.bandCount, 6), flat),
        isTrue,
      );
    });

    test('gainAt 对越界下标读作 0 dB', () {
      expect(flat.gainAt(-1), 0);
      expect(flat.gainAt(EqualizerSettings.bandCount), 0);
    });
  });

  group('平直判定、预设识别与重置', () {
    test('resetGains 回平但保留开关', () {
      const settings = EqualizerSettings(
        enabled: true,
        gains: <double>[4, 3, 2, 1, 0, -1, 1, 2, 3, 4],
      );

      final reset = settings.resetGains();

      expect(reset.gains, EqualizerPresets.flatGains);
      expect(reset.isFlat, isTrue);
      expect(reset.enabled, isTrue);
      expect(reset.presetId, EqualizerPresets.flatId);
    });

    test('isFlat 只看增益，不看开关', () {
      expect(const EqualizerSettings.flat().isFlat, isTrue);
      expect(const EqualizerSettings.flat(enabled: true).isFlat, isTrue);
      expect(
        EqualizerSettings(enabled: false, gains: EqualizerPresets.bass.gains)
            .isFlat,
        isFalse,
      );
    });

    test('命中曲线时 presetId 就是预设 id，手动改一段后变自定义', () {
      for (final preset in EqualizerPresets.all) {
        final settings = EqualizerSettings(
          enabled: true,
          gains: preset.gains,
        );

        expect(settings.presetId, preset.id, reason: preset.id);
      }

      final tweaked = EqualizerSettings(
        enabled: true,
        gains: EqualizerPresets.pop.gains,
      ).withGain(4, 9);

      expect(tweaked.presetId, EqualizerPresets.customId);
    });

    test('matching 对不上任何曲线返回 null，byId 对未知 id 返回 null', () {
      expect(
        EqualizerPresets.matching(<double>[0.5, 0, 0, 0, 0, 0, 0, 0, 0, 0]),
        isNull,
      );
      expect(
        EqualizerPresets.matching(EqualizerPresets.flatGains)?.id,
        EqualizerPresets.flatId,
      );
      expect(EqualizerPresets.byId('nonsense'), isNull);
      expect(EqualizerPresets.byId('bass')?.id, 'bass');
      expect(EqualizerPresets.all.length, 12);
      expect(EqualizerPresets.customId, 'custom');
    });

    test('快捷面板给的四个曲线都在全部预设里', () {
      expect(
        EqualizerPresets.quick.map((preset) => preset.id),
        <String>[
          EqualizerPresets.flatId,
          EqualizerPresets.popId,
          EqualizerPresets.rockId,
          EqualizerPresets.bassId,
        ],
      );
      for (final preset in EqualizerPresets.quick) {
        expect(EqualizerPresets.byId(preset.id), preset);
        expect(EqualizerPresets.all.contains(preset), isTrue);
      }
    });

    test('每个预设都是 10 段、id 唯一、增益在 ±12 dB 内', () {
      final ids = <String>{};

      for (final preset in EqualizerPresets.all) {
        expect(ids.add(preset.id), isTrue, reason: '重复 id: ${preset.id}');
        expect(preset.gains.length, EqualizerSettings.bandCount);
        for (final gain in preset.gains) {
          expect(
            gain,
            inInclusiveRange(EqualizerSettings.minGain, EqualizerSettings.maxGain),
            reason: preset.id,
          );
        }
      }
    });
  });

  group('preampDb 抵消最大提升', () {
    test('平直与纯衰减不额外压音量', () {
      expect(const EqualizerSettings.flat().preampDb, 0);
      expect(
        const EqualizerSettings(
          enabled: true,
          gains: <double>[-6, -3, 0, 0, 0, 0, 0, 0, 0, 0],
        ).preampDb,
        0,
        reason: '没有正增益就没有削波风险，预放保持 0 dB',
      );
    });

    test('等于最大增益的负值', () {
      expect(
        EqualizerSettings(enabled: true, gains: EqualizerPresets.bass.gains)
            .preampDb,
        -6,
      );
      expect(
        const EqualizerSettings(
          enabled: true,
          gains: <double>[0, 2, 5, -3, 0, 0, 0, 0, 0, 0],
        ).preampDb,
        -5,
      );
      expect(
        EqualizerSettings(
          enabled: true,
          gains: EqualizerSettings.normalizeGains(<double>[12]),
        ).preampDb,
        -12,
      );
    });
  });

  group('相等性与 hashCode', () {
    test('内容相同的两份设置相等，hashCode 一致', () {
      final a = EqualizerSettings(
        enabled: true,
        gains: EqualizerPresets.vocal.gains,
      );
      final b = EqualizerSettings.fromJson(a.toJson());
      final c = a.copyWith(gains: a.gains);

      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(c, a, reason: 'copyWith 归一后内容不变，仍应相等');
      expect(c.hashCode, a.hashCode);
    });

    test('开关或任一段增益不同就不相等', () {
      final base = EqualizerSettings(
        enabled: true,
        gains: EqualizerPresets.pop.gains,
      );

      expect(
        base ==
            EqualizerSettings(enabled: false, gains: EqualizerPresets.pop.gains),
        isFalse,
      );
      expect(base == base.withGain(0, base.gainAt(0) + 1), isFalse);
      expect(base == Object(), isFalse);
      expect(base == base, isTrue);
    });

    test('copyWith 会归一化外部传入的曲线', () {
      final settings = const EqualizerSettings.flat(
        enabled: true,
      ).copyWith(gains: <double>[1, 2, 99]);

      expect(settings.gains, <double>[1, 2, 12, 0, 0, 0, 0, 0, 0, 0]);
      expect(settings.enabled, isTrue);
    });
  });

  group('自己存下的预设', () {
    const kept = EqualizerPreset(
      id: 'user-1',
      name: '我的低音',
      gains: <double>[1, 0, 2, 0, 3, 0, 4, 0, 5, 0],
    );

    test('存下的曲线在 JSON 里往返，名字与增益都不丢', () {
      final settings = const EqualizerSettings.flat(
        enabled: true,
      ).saveCurrentAsPreset('我的低音', id: 'user-1');

      final json = settings.toJson();
      final restored = EqualizerSettings.fromJson(json);

      expect(json, contains('userPresets'));
      expect(restored.userPresets.length, 1);
      expect(restored.userPresets.single.id, 'user-1');
      expect(restored.userPresets.single.name, '我的低音');
      expect(restored.userPresets.single.gains, <double>[
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
      ]);
      expect(restored, settings);
    });

    test('没存过曲线时 JSON 里不出现 userPresets', () {
      expect(
        const EqualizerSettings.flat(enabled: true).toJson(),
        isNot(contains('userPresets')),
        reason: '旧版本读到的文件形状保持原样',
      );
    });

    test('坏条目被跳过，好条目照常读回', () {
      final restored = EqualizerSettings.fromJson(
        '{"version":1,"enabled":true,'
        '"gains":[0,0,0,0,0,0,0,0,0,0],'
        '"userPresets":['
        '{"id":"","name":"没 id","gains":[1]},'
        '{"id":"user-1","name":"  ","gains":[1]},'
        '{"id":"user-2","name":"好的","gains":[1,2,99]},'
        '{"id":"user-2","name":"重复 id","gains":[0]},'
        '42'
        ']}',
      );

      expect(restored.userPresets.length, 1);
      expect(restored.userPresets.single.id, 'user-2');
      expect(restored.userPresets.single.name, '好的');
      expect(restored.userPresets.single.gains, <double>[
        1,
        2,
        12,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
      ]);
    });

    test('userPresets 不是列表时当作没存过', () {
      final restored = EqualizerSettings.fromJson(
        '{"version":1,"enabled":false,"gains":[0,0,0,0,0,0,0,0,0,0],'
        '"userPresets":{"id":"user-1"}}',
      );

      expect(restored.userPresets, isEmpty);
    });

    test('当前曲线命中自己存的预设时，presetId 指向它', () {
      final settings = EqualizerSettings(
        enabled: true,
        gains: kept.gains,
        userPresets: const <EqualizerPreset>[kept],
      );

      expect(settings.presetId, 'user-1');
      expect(settings.findPreset('user-1')?.name, '我的低音');
      expect(settings.allPresets.length, EqualizerPresets.all.length + 1);
    });

    test('内置曲线优先于自己存的同形状曲线', () {
      final settings = EqualizerSettings(
        enabled: true,
        gains: EqualizerPresets.bass.gains,
        userPresets: const <EqualizerPreset>[
          EqualizerPreset(
            id: 'user-bass',
            name: '我的重低音',
            gains: <double>[1, 0, 2, 0, 3, 0, 4, 0, 5, 0],
          ),
        ],
      );

      expect(
        settings.presetId,
        EqualizerPresets.bassId,
        reason: '同一根曲线先报内置名，用户预设不该抢走既有说法',
      );
    });

    test('同名再存是覆盖，不新增条目', () {
      final first = const EqualizerSettings.flat(
        enabled: true,
      ).saveCurrentAsPreset('我的低音', id: 'user-1');
      final second = first
          .withGain(0, 9)
          .saveCurrentAsPreset('我的低音', id: 'user-2');

      expect(second.userPresets.length, 1);
      expect(second.userPresets.single.id, 'user-1');
      expect(second.userPresets.single.gains[0], 9);
    });

    test('空名字不留下条目', () {
      final settings = const EqualizerSettings.flat(
        enabled: true,
      ).saveCurrentAsPreset('   ', id: 'user-1');

      expect(settings.userPresets, isEmpty);
    });

    test('删除只动预设表，曲线原样保留', () {
      final settings = EqualizerSettings(
        enabled: true,
        gains: kept.gains,
        userPresets: const <EqualizerPreset>[kept],
      ).removePreset('user-1');

      expect(settings.userPresets, isEmpty);
      expect(settings.gains, kept.gains);
      expect(settings.presetId, EqualizerPresets.customId);
    });

    test('删除不存在的 id 原样返回', () {
      final settings = EqualizerSettings(
        enabled: true,
        gains: kept.gains,
        userPresets: const <EqualizerPreset>[kept],
      );

      expect(settings.removePreset('user-nope'), same(settings));
    });

    test('预设表不同即不相等', () {
      final base = EqualizerSettings(
        enabled: true,
        gains: kept.gains,
        userPresets: const <EqualizerPreset>[kept],
      );

      expect(
        base ==
            EqualizerSettings(
              enabled: true,
              gains: kept.gains,
              userPresets: const <EqualizerPreset>[
                EqualizerPreset(
                  id: 'user-1',
                  name: '换了名字',
                  gains: <double>[1, 0, 2, 0, 3, 0, 4, 0, 5, 0],
                ),
              ],
            ),
        isFalse,
      );
      expect(base == base.copyWith(), isTrue);
    });
  });

  group('频段表', () {
    test('10 段中心频率与面板顺序一致', () {
      expect(
        EqualizerSettings.frequencies,
        <double>[31, 62, 125, 250, 500, 1000, 2000, 4000, 8000, 16000],
      );

      final bands = EqualizerSettings.bands;

      expect(bands.length, EqualizerSettings.bandCount);
      for (var i = 0; i < bands.length; i++) {
        expect(bands[i].index, i);
        expect(bands[i].frequency, EqualizerSettings.frequencies[i]);
      }
    });
  });
}
