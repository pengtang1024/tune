
enum FontFamily {
  defaultFont('JetBrainsMono'),
  roboto('Roboto'),
  openSans('OpenSans'),
  montserrat('Montserrat'),
  robotoMono('RobotoMono'),
  sourceSansPro('SourceSansPro'),
  poppins('Poppins'),
  lato('Lato'),
  nunito('Nunito'),
  raleway('Raleway'),
  inter('Inter'),
  ubuntu('Ubuntu'),
  notoSans('NotoSans'),
  notoSerif('NotoSerif'),
  oxygen('Oxygen'),
  oxygenMono('OxygenMono'),
  quicksand('Quicksand'),
  robotoCondensed('RobotoCondensed'),
  robotoSlab('RobotoSlab'),
  ubuntuMono('UbuntuMono'),
  workSans('WorkSans'),
  jetBrainsMono('JetBrainsMono');

  final String fontFamily;

  const FontFamily(this.fontFamily);

  static FontFamily fromValue(String? storedFont) {
    return values.firstWhere((element) => element.fontFamily == storedFont, orElse: () => defaultFont);
  }

  String get value => fontFamily;

  @override
  String toString() => fontFamily;
}

/// 文本样式常量
class TextStyles {
  /// bodySmall 文本样式
  static const double bodySmallFontSize = 12.0;

  /// bodyMedium 文本样式
  static const double bodyMediumFontSize = 14.0;

  /// bodyLarge 文本样式
  static const double bodyLargeFontSize = 16.0;

  /// titleSmall 文本样式
  static const double titleSmallFontSize = 16.0;

  /// titleMedium 文本样式
  static const double titleMediumFontSize = 18.0;

  /// titleLarge 文本样式
  static const double titleLargeFontSize = 20.0;

  /// AppBar 标题文本样式
  static const double appBarTitleFontSize = 18.0;

  /// 底部播放器歌曲标题文本样式
  static const double playerSongTitleFontSize = 14.0;

  /// 底部播放器艺术家信息文本样式
  static const double playerArtistFontSize = 12.0;
}
