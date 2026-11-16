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
/// 4. 标题以艺术家名开头（形如 `艺术家 - 曲名`）→ 去掉这段前缀。
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

  if (trimmedArtist.isEmpty) {
    return TrackNaming(
      title: trimmedTitle,
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
    title: trimmedTitle,
    artist: trimmedArtist,
    album: trimmedAlbum,
  );
}

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
