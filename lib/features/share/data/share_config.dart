import 'dart:convert';
import 'dart:io';

/// 分享功能的本地配置：目前只有 AcoustID 的 client key。
///
/// 放 `<support>/share/config.json`，跟身份、台账同级；坏文件当空，不让一份坏 JSON
/// 把整个分享页卡住。
class ShareConfig {
  ShareConfig(this.file);

  final File file;

  Future<Map<String, Object?>> _read() async {
    if (!await file.exists()) {
      return <String, Object?>{};
    }
    final Object? decoded;
    try {
      decoded = jsonDecode(await file.readAsString());
    } on FormatException {
      return <String, Object?>{};
    } on FileSystemException {
      return <String, Object?>{};
    }
    return decoded is Map
        ? decoded.cast<String, Object?>()
        : <String, Object?>{};
  }

  Future<String> acoustIdKey() async {
    final value = (await _read())['acoustIdKey'];
    return value is String ? value.trim() : '';
  }

  /// 空字符串表示「清掉」。
  Future<void> setAcoustIdKey(String key) async {
    final data = await _read();
    await file.parent.create(recursive: true);
    await file.writeAsString(
      jsonEncode(<String, Object?>{...data, 'v': 1, 'acoustIdKey': key.trim()}),
    );
  }
}
