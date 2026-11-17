/// 一条内容凭什么被允许进入分享房间。
///
/// 这是用户的主张，不是已经被证实的事实：能不能进房间由
/// `share_admission.dart` 用可校验的证据重新判定，声明本身不放行任何东西。
enum ShareProvenance {
  /// 本机生成器产出过同字节内容，命中生成台账。
  generated('generated'),

  /// 用户自己录的音（演奏、演唱、现场、demo）。
  ownRecording('own_recording'),

  /// 用户自己写的词曲，由本人或他人演绎。
  ownComposition('own_composition'),

  /// 用户从权利人处拿到了可分享的授权，凭证哈希随条目走。
  licensed('licensed');

  const ShareProvenance(this.wireName);

  /// 落库与走协议时的稳定名字，改了就是破坏兼容。
  final String wireName;

  /// 认不出的一律返回 null，由调用方按「不支持」处理，不猜。
  static ShareProvenance? parse(String value) {
    for (final provenance in values) {
      if (provenance.wireName == value) {
        return provenance;
      }
    }
    return null;
  }

  /// 生成物要额外背一条标识义务，其余三种不用。
  bool get isGenerated => this == ShareProvenance.generated;
}
