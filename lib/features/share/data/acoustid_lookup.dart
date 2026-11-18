import 'dart:convert';
import 'dart:io';

/// 一段音频的指纹：AcoustID 查重要 duration + fingerprint 两个字段。
class Fingerprint {
  const Fingerprint({required this.durationSeconds, required this.value});

  final int durationSeconds;
  final String value;
}

/// 算指纹的方式（默认跑 `fpcalc -json`）。测试里换成假的，不依赖二进制。
typedef FingerprintRunner = Future<Fingerprint?> Function(File file);

/// 发一次 GET 并拿到正文（默认走 `HttpClient`）。测试里换成假的，不碰网络。
typedef HttpTextFetcher = Future<String> Function(Uri uri);

/// AcoustID 查重：有没有「已经是某张商业录音」。
///
/// 只在两件事都具备时才算「能查」：`fpcalc`（chromaprint）与 AcoustID 的 client key。
/// 缺任何一样就返回 null —— 那是**没查**，不是**查过没问题**，调用方不要把它当清白证明。
class AcoustIdLookup {
  AcoustIdLookup({
    required this.clientKey,
    this.fpcalc,
    FingerprintRunner? fingerprint,
    HttpTextFetcher? fetch,
  }) : _fingerprint = fingerprint,
       _fetch = fetch ?? _httpGet;

  final String clientKey;

  /// `fpcalc` 的路径；为 null 表示这台机器上没有。
  final File? fpcalc;

  final FingerprintRunner? _fingerprint;
  final HttpTextFetcher _fetch;

  static const String endpoint = 'https://api.acoustid.org/v2/lookup';

  bool get isConfigured => clientKey.trim().isNotEmpty && fpcalc != null;

  /// 命中就返回「曲名 — 艺人」（没有名字就返回录音 id），没命中或查不了返回 null。
  Future<String?> match(File file) async {
    if (!isConfigured) {
      return null;
    }
    final runner = _fingerprint ?? (File target) => runFpcalc(fpcalc!, target);
    final Fingerprint? print;
    try {
      print = await runner(file);
    } on ProcessException {
      return null;
    }
    if (print == null || print.value.isEmpty) {
      return null;
    }
    final uri = Uri.parse(endpoint).replace(
      queryParameters: <String, String>{
        'client': clientKey.trim(),
        'meta': 'recordings',
        'duration': '${print.durationSeconds}',
        'fingerprint': print.value,
      },
    );
    final String body;
    try {
      body = await _fetch(uri);
    } on Exception {
      return null;
    }
    return parseMatch(body);
  }

  /// 解析 AcoustID 的响应；结构不对、状态不是 ok、没有录音都返回 null。
  static String? parseMatch(String body) {
    final Object? decoded;
    try {
      decoded = jsonDecode(body);
    } on FormatException {
      return null;
    }
    if (decoded is! Map || decoded['status'] != 'ok') {
      return null;
    }
    final results = decoded['results'];
    if (results is! List) {
      return null;
    }
    for (final result in results) {
      if (result is! Map) {
        continue;
      }
      final recordings = result['recordings'];
      if (recordings is! List || recordings.isEmpty) {
        continue;
      }
      final first = recordings.first;
      if (first is! Map) {
        continue;
      }
      final title = first['title'];
      final artists = first['artists'];
      final id = first['id'];
      final artist =
          artists is List && artists.isNotEmpty && artists.first is Map
          ? (artists.first as Map)['name']
          : null;
      if (title is String && title.isNotEmpty) {
        return artist is String && artist.isNotEmpty
            ? '$title — $artist'
            : title;
      }
      if (id is String && id.isNotEmpty) {
        return id;
      }
    }
    return null;
  }

  /// 在 PATH 与 `~/.local/bin`、`~/bin` 里找 `fpcalc`。
  static File? findFpcalc({Map<String, String>? environment}) {
    final env = environment ?? Platform.environment;
    final home = env['HOME'];
    final dirs = <String>[
      if (env['PATH'] != null) ...env['PATH']!.split(':'),
      if (home != null) ...['$home/.local/bin', '$home/bin'],
    ];
    for (final dir in dirs) {
      if (dir.trim().isEmpty) {
        continue;
      }
      final file = File('$dir/fpcalc');
      try {
        if (file.existsSync()) {
          return file;
        }
      } on FileSystemException {
        continue;
      }
    }
    return null;
  }

  /// 跑 `fpcalc -json <file>`，解析出 duration 与 fingerprint。
  ///
  /// 退出码非 0、输出不是 JSON、缺字段都当算不出（返回 null），不要拿半个指纹去查。
  static Future<Fingerprint?> runFpcalc(File fpcalc, File file) async {
    final ProcessResult result;
    try {
      result = await Process.run(fpcalc.path, <String>['-json', file.path]);
    } on ProcessException {
      return null;
    }
    if (result.exitCode != 0) {
      return null;
    }
    final Object? decoded;
    try {
      decoded = jsonDecode(result.stdout.toString());
    } on FormatException {
      return null;
    }
    if (decoded is! Map) {
      return null;
    }
    final duration = decoded['duration'];
    final fingerprint = decoded['fingerprint'];
    if (fingerprint is! String || fingerprint.isEmpty) {
      return null;
    }
    final seconds = switch (duration) {
      final num value => value.round(),
      final String value => int.tryParse(value.split('.').first) ?? 0,
      _ => 0,
    };
    if (seconds <= 0) {
      return null;
    }
    return Fingerprint(durationSeconds: seconds, value: fingerprint);
  }

  static Future<String> _httpGet(Uri uri) async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(uri);
      final response = await request.close();
      return await response.transform(utf8.decoder).join();
    } finally {
      client.close(force: true);
    }
  }
}
