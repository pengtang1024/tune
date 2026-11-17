/// 生成合成内容的隐式标识。
///
/// 《人工智能生成合成内容标识办法》（2025-09-01 施行）要求隐式标识携带
/// 生成合成属性、服务提供者名称或编码、内容编号。这里只存事实，不负责写入
/// 文件；写入在分享发布那一步做，读回来再核对。
class ShareAiDisclosure {
  const ShareAiDisclosure({
    this.isSynthetic = false,
    this.providerName,
    this.providerCode,
    this.contentNumber,
  });

  /// 未声明为生成物时的空标识。
  static const ShareAiDisclosure none = ShareAiDisclosure();

  /// 是否属于生成合成内容。
  final bool isSynthetic;

  /// 服务提供者名称，例如 `Tune 本地生成`。
  final String? providerName;

  /// 服务提供者编码，和名字二选一即可。
  final String? providerCode;

  /// 内容编号，同一提供者内唯一即可。
  final String? contentNumber;

  /// 名字与编码至少要有一个，编号不能空——这是办法里的三件套。
  bool get isComplete {
    if (!isSynthetic) {
      return false;
    }
    final hasProvider =
        (providerName != null && providerName!.trim().isNotEmpty) ||
        (providerCode != null && providerCode!.trim().isNotEmpty);
    final hasNumber =
        contentNumber != null && contentNumber!.trim().isNotEmpty;
    return hasProvider && hasNumber;
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'synthetic': isSynthetic,
    if (providerName != null) 'providerName': providerName,
    if (providerCode != null) 'providerCode': providerCode,
    if (contentNumber != null) 'contentNumber': contentNumber,
  };

  static ShareAiDisclosure fromJson(Map<String, Object?> json) {
    return ShareAiDisclosure(
      isSynthetic: json['synthetic'] == true,
      providerName: json['providerName'] as String?,
      providerCode: json['providerCode'] as String?,
      contentNumber: json['contentNumber'] as String?,
    );
  }
}
