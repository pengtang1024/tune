/// The ledger of the lyrics the library carries.
///
/// The smart lyrics pipeline (docs/smart-lyrics.md) is judged against this
/// account: [resolved] is the share of tracks that already carry lyrics
/// locally, [missing] the gap the pipeline fills. It counts facts the last
/// scan wrote, so a lyric sheet matched after the scan joins the ledger on
/// the next scan — the baseline is a floor, never an overcount.
class SmartLyricsLedger {
  /// How many tracks the library holds (the ones the reader sees).
  final int total;

  /// How many of them are known to carry lyrics locally.
  final int resolved;

  const SmartLyricsLedger({required this.total, required this.resolved});

  /// The share the smart pipeline is asked for.
  int get missing => total - resolved;

  /// The account before any scan ran.
  static const SmartLyricsLedger empty = SmartLyricsLedger(
    total: 0,
    resolved: 0,
  );
}
