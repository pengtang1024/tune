/// 把「同一件事写了两遍」的命名归一化。
///
/// Internet Archive 上的条目由上传者自己写元数据，同一份信息常同时出现在
/// 标题、专辑与艺术家里：
///
/// - 专辑写成 `Edward ELGAR - Enigma Variations`，艺术家却是空的；
/// - 标题写成 `Handel, Messiah - 103 And the glory of the Lord - Coro`，
///   艺术家列已经写着 `Handel, G F`。
///
/// 列表里艺术家、专辑、标题各占一列，重复的那一份只会把标题挤成省略号。
/// 所以规则在**取数边界**做一次，而不是在界面里叠例外：
///
/// 1. 艺术家为空且条目声明了 `creator` → 用 `creator`；
/// 2. 艺术家仍为空、专辑形如 `艺术家 - 作品` → 拆开，前半当艺术家；
/// 3. 专辑以艺术家名开头 → 去掉这段前缀；
/// 4. 标题以艺术家名开头（形如 `艺术家 - 曲名`）→ 去掉这段前缀；
/// 5. 标题开头的曲目序号（`01 Theme`、`13 XIII. Romanza`、`102 Sinfonia`）→
///    去掉序号，序号在列表里由行本身表达；
/// 6. 标题尾部的占位符（`Romanza; +++`、`Vote on Tuesday**`）与角色后缀
///    （`God's glory - Coro`）→ 去掉。
///
/// 四条都只在「能确认是同一个事实」时才动手：前缀必须与艺术家名对得上，
/// 剩下的一半必须有内容，专辑与标题相同（整条就是一个曲名）时不拆。
class TrackNaming {
  const TrackNaming({
    required this.title,
    required this.artist,
    required this.album,
  });

  final String title;
  final String artist;
  final String album;
}

const String _separator = ' - ';

/// 归一化一条曲目的命名。纯函数，不碰网络与数据库。
TrackNaming normalizeTrackNaming({
  required String title,
  required String artist,
  required String album,
  String creator = '',
}) {
  var trimmedTitle = title.trim();
  var trimmedArtist = artist.trim();
  var trimmedAlbum = album.trim();

  // 1. 条目自己声明的作者优先于任何推断。
  if (trimmedArtist.isEmpty) {
    trimmedArtist = creator.trim();
  }

  // 2. 专辑写作「艺术家 - 作品」。整条就是一个曲名时（专辑与标题相同）
  //    不拆，否则会把曲名拆成艺术家加残句。
  if (trimmedArtist.isEmpty &&
      trimmedAlbum != trimmedTitle &&
      trimmedAlbum.contains(_separator)) {
    final head = trimmedAlbum.split(_separator).first.trim();
    final rest = trimmedAlbum.substring(head.length + _separator.length).trim();
    if (_looksLikeArtist(head) && rest.isNotEmpty) {
      trimmedArtist = head;
      trimmedAlbum = rest;
    }
  }

  // 没有艺术家时 3、4 两条无从比对，但标题里的序号与占位符与艺术家无关。
  if (trimmedArtist.isEmpty) {
    return TrackNaming(
      title: _cleanTrackTitle(trimmedTitle, trimmedAlbum),
      artist: trimmedArtist,
      album: trimmedAlbum,
    );
  }

  // 3. 专辑名重复艺术家：`Edward ELGAR - Enigma Variations`。
  final albumPrefix = _artistPrefixLength(trimmedAlbum, trimmedArtist);
  if (albumPrefix > 0) {
    final rest = trimmedAlbum.substring(albumPrefix).trim();
    if (rest.isNotEmpty) trimmedAlbum = rest;
  }

  // 4. 标题名重复艺术家：`Handel, Messiah - 103 And the glory of the Lord`。
  final titlePrefix = _artistPrefixLength(trimmedTitle, trimmedArtist);
  if (titlePrefix > 0) {
    final rest = trimmedTitle.substring(titlePrefix).trim();
    if (rest.isNotEmpty) trimmedTitle = rest;
  }

  return TrackNaming(
    title: _cleanTrackTitle(trimmedTitle, trimmedAlbum),
    artist: trimmedArtist,
    album: trimmedAlbum,
  );
}

/// 角色名：唱诗班、独唱声部这类分轨标记写在曲名后面，不是曲名的一部分。
const Set<String> _roleSuffixes = {
  'Coro',
  'Chorus',
  'Aria',
  'Duet',
  'Trio',
  'Ensemble',
  'Soprano',
  'Alto',
  'Tenor',
  'Bass',
  'Orchestra',
};

/// 去掉标题里的曲目序号、占位符与角色后缀。
///
/// 只在能确认那是序号时才动手：数字后面必须跟分隔符、罗马数字，或者以 `0`
/// 开头的两位数（`01 Theme`），再或者三位数且等于专辑声明的碟号加轨号
/// （`(Disc 1 of 3)` 下的 `102`）。`7 Rings`、`99 Luftballons`、`24K Magic`
/// 这类把数字当词用的标题一个字符都不动。
String _cleanTrackTitle(String title, String album) {
  var cleaned = _stripTrackNumber(title, album);

  // 占位符：整段只有 `+` 或 `*` 的尾部记号（`Romanza; +++`、`Tuesday**`）。
  final placeholder = RegExp(r'[\s]*[;,]?[\s]*[+*]{2,}\s*$');
  if (placeholder.hasMatch(cleaned)) {
    final rest = cleaned.replaceFirst(placeholder, '');
    if (_hasWord(rest)) cleaned = rest;
  }

  // 角色后缀：`103 And the glory of the Lord - Coro`。
  final separatorIndex = cleaned.lastIndexOf(_separator);
  if (separatorIndex > 0) {
    final tail = cleaned.substring(separatorIndex + _separator.length).trim();
    if (_roleSuffixes.contains(tail)) {
      final rest = cleaned.substring(0, separatorIndex).trim();
      if (_hasWord(rest)) cleaned = rest;
    }
  }

  return cleaned.replaceAll(RegExp(r'\s{2,}'), ' ').trim();
}

/// 去掉标题开头的曲目序号，返回剩余部分；认不出序号时原样返回。
String _stripTrackNumber(String title, String album) {
  // 章节编号：`1-1 Life of Saint Mael` —— 两段数字一起算序号。
  final chapter = RegExp(r'^\s*\d{1,3}\s*[-\u2013]\s*\d{1,3}\s+');
  final chapterMatch = chapter.firstMatch(title);
  if (chapterMatch != null) {
    final rest = title.substring(chapterMatch.end).trim();
    if (_hasWord(rest)) return rest;
  }

  // 数字 + 分隔符：`01 - The Shade`、`12. Air`、`3) Allegro`、`427: Original Recipe`。
  final separated = RegExp(r'^\s*\d{1,3}\s*[.\-:–_)]\s*');
  final separatedMatch = separated.firstMatch(title);
  if (separatedMatch != null) {
    final rest = title.substring(separatedMatch.end).trim();
    // 去掉一段数字后，剩下若仍以数字开头（`2014-02-12 Bigwords`），那说明
    // 这不像序号；交回原样，宁可留着序号也不切掉真正的名字。
    if (RegExp(r'^\d').hasMatch(rest)) return title;
    // `1999 - something` 这类年份不在序号的口径里：年份后面通常没有分隔符，
    // 而 `2020.` 这种确实是序号，靠剩余部分是否有词来兜底。
    if (_hasWord(rest) && !_looksLikeYear(separatedMatch.group(0)!, rest)) {
      return rest;
    }
  }

  // 数字 + 罗马数字：`13 XIII. Romanza` —— 只去阿拉伯数字，罗马数字是乐章号。
  final roman = RegExp(r'^\s*\d{1,3}\s+(?=[IVXLC]+\.)');
  final romanMatch = roman.firstMatch(title);
  if (romanMatch != null) {
    final rest = title.substring(romanMatch.end).trim();
    if (_hasWord(rest)) return rest;
  }

  // 前导零的序号：`01 Theme`、`02 II. H.D.S.`。
  final padded = RegExp(r'^\s*0\d{1,2}\s+');
  final paddedMatch = padded.firstMatch(title);
  if (paddedMatch != null) {
    final rest = title.substring(paddedMatch.end).trim();
    if (_hasWord(rest)) return rest;
  }

  // 碟号 + 轨号：专辑写着 `(Disc 1 of 3)`，标题写着 `102 Sinfonia`。
  final disc = RegExp(r'\(Disc\s+(\d)\s+of\s+\d\)').firstMatch(album);
  final track = RegExp(r'^\s*(\d{3})\s+').firstMatch(title);
  if (disc != null && track != null) {
    final number = int.parse(track.group(1)!);
    final discNumber = int.parse(disc.group(1)!);
    if (number ~/ 100 == discNumber && number % 100 > 0) {
      final rest = title.substring(track.end).trim();
      if (_hasWord(rest)) return rest;
    }
  }

  return title;
}

bool _looksLikeYear(String prefix, String rest) {
  final digits = RegExp(r'\d+').firstMatch(prefix)?.group(0);
  if (digits == null || digits.length != 4) return false;
  final year = int.parse(digits);
  return year >= 1900 && year <= 2100 && rest.length > 20;
}

bool _hasWord(String text) =>
    RegExp(r'[A-Za-z\u00C0-\u024F\u4e00-\u9fff]').hasMatch(text);

/// 一段候选艺术家名的合理性检查：不是编号、不是整条文本、长度合理。
bool _looksLikeArtist(String candidate) {
  if (candidate.length < 2 || candidate.length > 60) return false;
  if (!candidate.contains(RegExp(r'[A-Za-z\u00C0-\u024F\u4e00-\u9fff]'))) {
    return false;
  }
  // 纯编号（`01`、`12`）是曲目序号，不是人。
  if (RegExp(r'^\d+$').hasMatch(candidate)) return false;
  return true;
}

/// 若 [text] 以「艺术家 - 」开头，返回该前缀的长度；否则返回 0。
///
/// 「对得上」的口径：前缀整段等于艺术家名，或者前缀的第一段以艺术家名的
/// 第一个词开头（`Handel, Messiah` 对 `Handel, G F`）。只认第一个词，是为了
/// 避开艺术家名写成 `姓, 名` 而标题写成 `姓, 作品` 的差异。
int _artistPrefixLength(String text, String artist) {
  final separatorIndex = text.indexOf(_separator);
  if (separatorIndex <= 0) return 0;
  final head = text.substring(0, separatorIndex).trim();
  final rest = text.substring(separatorIndex + _separator.length).trim();
  if (head.isEmpty || rest.isEmpty) return 0;

  final lowerHead = head.toLowerCase();
  final lowerArtist = artist.toLowerCase();
  if (lowerHead == lowerArtist) return separatorIndex + _separator.length;

  final firstWord = _firstWord(artist);
  if (firstWord.length < 3) return 0;
  final lowerWord = firstWord.toLowerCase();
  if (lowerHead.startsWith(lowerWord) &&
      (lowerHead.length == lowerWord.length ||
          _isBoundary(lowerHead[lowerWord.length]))) {
    return separatorIndex + _separator.length;
  }
  return 0;
}

String _firstWord(String artist) {
  final match = RegExp(r'[A-Za-z\u00C0-\u024F\u4e00-\u9fff]+').firstMatch(artist);
  return match?.group(0) ?? '';
}

/// 前缀结尾处的字符是否算词边界：艺术家名常被写成 `Handel, G F`、`Handel & Co`。
bool _isBoundary(String character) {
  const boundaries = {',', ';', '&', '/', '.', '(', ' '};
  return boundaries.contains(character);
}
