import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/features/library/application/library_controller.dart';
import 'package:tune/features/smart_lyrics/data/smart_lyrics_ledger_store.dart';
import 'package:tune/features/smart_lyrics/domain/smart_lyrics_ledger.dart';

/// The store the ledger reads through.
final smartLyricsLedgerStoreProvider = Provider<SmartLyricsLedgerStore>(
  (ref) => SmartLyricsLedgerStore(),
);

/// The lyrics ledger of the library.
///
/// The count follows the identity of the library window: a scan or a window
/// load changes it and the ledger recomputes, a query typed into the search
/// box does not. The library itself never enters memory for this — the
/// count is one query over the rows.
final smartLyricsLedgerProvider = FutureProvider<SmartLyricsLedger>((ref) async {
  ref.watch(
    libraryControllerProvider.select((state) => state.valueOrNull?.songs),
  );
  return ref.watch(smartLyricsLedgerStoreProvider).read();
});
