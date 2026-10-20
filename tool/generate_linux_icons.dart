// 生成 Linux 桌面图标。
//
// Linux 的图标按 GNOME 的 16 格网格排版：图形要缩到画布的 13/16，四周留出透明边。
// 原图是铺满画布的圆角方块，直接拿去当主题图标，dock 里的图标会比别的应用大一圈。
//
//   dart run tool/generate_linux_icons.dart
import 'dart:io';

import 'package:image/image.dart' as img;

/// 原图，所有平台图标的唯一来源。
const _sourcePath = 'branding/app_icon.png';

/// 图形在画布里占的比例，13/16 是 GNOME 的 16 格网格。
const _artRatio = 13 / 16;

/// 各尺寸对应的文件名；256 那份没有后缀，它同时是程序自带的窗口图标。
const _targets = <int, String>{
  16: 'app_icon_16.png',
  32: 'app_icon_32.png',
  48: 'app_icon_48.png',
  64: 'app_icon_64.png',
  128: 'app_icon_128.png',
  256: 'app_icon.png',
};

/// 输出目录，CMake 会把它装进 hicolor 主题。
const _outputDir = 'linux/runner/resources';

/// 素材里的那份 256 图标，程序没有自带的图标时用它兜底。
const _assetPath = 'assets/icons/app_icon_linux.png';

void main() {
  final source = img.decodePng(File(_sourcePath).readAsBytesSync());
  if (source == null) {
    stderr.writeln('读不出原图：$_sourcePath');
    exit(1);
  }

  for (final target in _targets.entries) {
    final size = target.key;
    final side = (size * _artRatio).round();
    final art = img.copyResize(
      source,
      width: side,
      height: side,
      interpolation: img.Interpolation.average,
    );

    final canvas = img.Image(width: size, height: size, numChannels: 4);
    img.fill(canvas, color: img.ColorRgba8(0, 0, 0, 0));
    img.compositeImage(
      canvas,
      art,
      dstX: (size - side) ~/ 2,
      dstY: (size - side) ~/ 2,
    );

    final bytes = img.encodePng(canvas);
    final file = File('$_outputDir/${target.value}');
    file.writeAsBytesSync(bytes);
    stdout.writeln('写出 ${file.path}：$size×$size，图形 $side×$side');

    if (size == 256) {
      File(_assetPath).writeAsBytesSync(bytes);
      stdout.writeln('写出 $_assetPath');
    }
  }
}
