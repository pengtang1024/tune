import 'package:flutter/foundation.dart' show kIsWeb;

/// The headers a source sends with every request.
///
/// The browser refuses to let a script set `User-Agent` and `Referer`: they
/// are forbidden header names, and the browser sends its own instead. The web
/// build therefore leaves them out, so the console stays free of
/// "Refused to set unsafe header" errors.
///
/// The desktop build identifies itself, because some sources (Wikimedia,
/// Openverse) ask a client to name itself.
Map<String, String> sourceRequestHeaders({
  Map<String, String> extra = const {},
}) {
  if (kIsWeb) return Map.of(extra);

  return {
    'User-Agent': 'Tune/1.1 (Flutter open-source music player)',
    ...extra,
  };
}
