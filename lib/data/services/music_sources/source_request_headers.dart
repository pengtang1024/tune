/// The headers a source sends with every request.
///
/// The desktop build identifies itself, because some sources (Wikimedia,
/// Openverse) ask a client to name itself.
Map<String, String> sourceRequestHeaders({
  Map<String, String> extra = const {},
}) {
  return {
    'User-Agent': 'Tune/1.1 (Flutter open-source music player)',
    ...extra,
  };
}
