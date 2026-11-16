import 'package:flutter_test/flutter_test.dart';
import 'package:tune/data/services/impl/mpv_equalizer_filter.dart';
import 'package:tune/domain/models/equalizer_settings.dart';

/// [MpvEqualizerFilter] 是唯一一处把设置翻译成 mpv `af` 的纯函数。
///
/// 图串写错不会抛异常，只会安静地不生效，所以这里按整串断言：预放、频率、
/// 滤波类型、增益全部要对得上，不能用 isNotNull 放过。
void main() {
  EqualizerSettings curve({
    bool enabled = true,
    required List<double> gains,
    double bandWidth = EqualizerSettings.defaultBandWidth,
    double? preampOverrideDb,
  }) => EqualizerSettings(
    enabled: enabled,
    gains: EqualizerSettings.normalizeGains(gains),
    bandWidth: bandWidth,
    preampOverrideDb: preampOverrideDb,
  );

  group('清空的条件', () {
    test('关闭时返回 null，哪怕曲线不是平的', () {
      final af = MpvEqualizerFilter.build(
        curve(
          enabled: false,
          gains: <double>[6, 5, 4, 3, 2, 1, 0, 0, 0, 0],
        ),
      );

      expect(af, isNull);
    });

    test('10 段全 0 时返回 null，不留一条空转的链', () {
      expect(MpvEqualizerFilter.build(curve(gains: <double>[])), isNull);
      expect(
        MpvEqualizerFilter.build(
          const EqualizerSettings(enabled: true, gains: EqualizerPresets.flatGains),
        ),
        isNull,
      );
    });
  });

  group('单频段与预放', () {
    test('1 kHz +6 dB：预放 -6 dB，一个 equalizer 节点', () {
      final af = MpvEqualizerFilter.build(
        curve(gains: <double>[0, 0, 0, 0, 0, 6, 0, 0, 0, 0]),
      );

      expect(
        af,
        'lavfi=[volume=-6dB,equalizer=f=1000:width_type=o:width=1:g=6]',
      );
    });

    test('+12 dB 时预放正好 -12 dB', () {
      final af = MpvEqualizerFilter.build(
        curve(gains: <double>[12, 0, 0, 0, 0, 0, 0, 0, 0, 0]),
      );

      expect(
        af,
        'lavfi=[volume=-12dB,equalizer=f=31:width_type=o:width=1:g=12]',
      );
    });

    test('0 dB 的频段被跳过，只留下真正动过的段', () {
      final af = MpvEqualizerFilter.build(
        curve(gains: <double>[0, 0, 0, 0, 0, 0, 0, 0, 0, -3]),
      );

      expect(af, 'lavfi=[equalizer=f=16000:width_type=o:width=1:g=-3]');
      expect(af, isNot(contains('volume=')));
    });

    test('只有负增益时预放是 0 dB，不额外压音量', () {
      final af = MpvEqualizerFilter.build(
        curve(gains: <double>[-3, 0, 0, 0, 0, -6, 0, 0, 0, 0]),
      );

      expect(
        af,
        'lavfi=[equalizer=f=31:width_type=o:width=1:g=-3,'
        'equalizer=f=1000:width_type=o:width=1:g=-6]',
      );
      expect(af, isNot(contains('volume')));
    });
  });

  group('多频段', () {
    test('顺序与 frequencies 一致，预放取最大提升', () {
      final af = MpvEqualizerFilter.build(
        curve(gains: <double>[4, 0, -5, 0, 0, 6, 0, 0, 0, -2]),
      );

      expect(
        af,
        'lavfi=[volume=-6dB,'
        'equalizer=f=31:width_type=o:width=1:g=4,'
        'equalizer=f=125:width_type=o:width=1:g=-5,'
        'equalizer=f=1000:width_type=o:width=1:g=6,'
        'equalizer=f=16000:width_type=o:width=1:g=-2]',
      );

      final frequencies = RegExp(r'equalizer=f=(\d+):')
          .allMatches(af!)
          .map((match) => int.parse(match.group(1)!))
          .toList();
      expect(frequencies, <int>[31, 125, 1000, 16000]);
      expect(af, startsWith('lavfi=['));
      expect(af, endsWith(']'));
    });

    test('10 段全部非零：10 个节点，每段频率按低到高各出现一次', () {
      final af = MpvEqualizerFilter.build(
        curve(gains: <double>[1, 2, 3, 4, 5, 6, 7, 8, 9, 10]),
      );

      expect('equalizer=f='.allMatches(af!).length, EqualizerSettings.bandCount);
      expect(af, startsWith('lavfi=[volume=-10dB,'));
      expect(af, endsWith('g=10]'));

      final frequencies = RegExp(r'equalizer=f=(\d+):')
          .allMatches(af)
          .map((match) => int.parse(match.group(1)!))
          .toList();
      expect(
        frequencies,
        EqualizerSettings.frequencies.map((hz) => hz.toInt()).toList(),
      );
      expect(frequencies.first, 31);
      expect(frequencies.last, 16000);
    });
  });

  group('宽度与预放', () {
    test('宽半倍频程时每段都写 width=0.5', () {
      final af = MpvEqualizerFilter.build(
        curve(gains: <double>[3, 0, 0, 0, 0, 0, 0, 0, 0, 0], bandWidth: 0.5),
      );

      expect(af, contains('width_type=o:width=0.5:g=3'));
      expect(af, isNot(contains('width=1:')));
    });

    test('三分之二倍频程写成 0.667，而不是循环小数', () {
      final af = MpvEqualizerFilter.build(
        curve(gains: <double>[0, 0, 0, 0, 0, 0, 0, 0, 0, 2], bandWidth: 2 / 3),
      );

      expect(af, contains('width=0.667:g=2'));
    });

    test('三分之一倍频程写成 0.333', () {
      final af = MpvEqualizerFilter.build(
        curve(gains: <double>[1, 0, 0, 0, 0, 0, 0, 0, 0, 0], bandWidth: 1 / 3),
      );

      expect(af, contains('width=0.333:g=1'));
    });

    test('半格增益按小数写进图串，预放也带小数', () {
      final af = MpvEqualizerFilter.build(
        curve(gains: <double>[0, 0, 0, 1.5, 0, 0, 0, 0, 0, 0]),
      );

      expect(
        af,
        'lavfi=[volume=-1.5dB,equalizer=f=250:width_type=o:width=1:g=1.5]',
      );
    });

    test('手动预放覆盖自动值，曲线本身不变', () {
      final af = MpvEqualizerFilter.build(
        curve(
          gains: <double>[6, 0, 0, 0, 0, 0, 0, 0, 0, 0],
          preampOverrideDb: -9,
        ),
      );

      expect(af, startsWith('lavfi=[volume=-9dB,'));
      expect(af, contains('g=6]'));
      expect(af, isNot(contains('volume=-6dB')));
    });

    test('手动预放 -24 dB 也照写，不会被夹回自动值', () {
      final af = MpvEqualizerFilter.build(
        curve(
          gains: <double>[0, 0, 0, 0, 0, 0, 0, 0, 0, -2],
          preampOverrideDb: -24,
        ),
      );

      expect(af, 'lavfi=[volume=-24dB,equalizer=f=16000:width_type=o:width=1:g=-2]');
    });
  });
}

