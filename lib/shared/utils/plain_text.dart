/// Turns HTML fragments into the plain text a reader reads.
///
/// The metadata of remote sources is written for the web, so artists,
/// descriptions and summaries arrive as small fragments of HTML. A reader
/// wants the words behind them, not the tags that carried them.
String plainText(String value) {
  return value
      .replaceAll(RegExp(r'<[^>]*>'), ' ')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&amp;', '&')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}
