import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/features/library/application/library_controller.dart';
import 'package:tune/features/smart_lyrics/data/smart_lyrics_sample_store.dart';
import 'package:tune/features/smart_lyrics/domain/smart_lyrics_sample.dart';

/// The store the accuracy sample reads through and draws with.
final smartLyricsSampleStoreProvider = Provider<SmartLyricsSampleStore>(
  (ref) => SmartLyricsSampleStore(),
);

/// The account of the accuracy sample: what was drawn per layer, what a
/// human checked, what passed.
///
/// The count follows the identity of the library window like the ledger
/// does — a scan may recompute it, a query typed into the search box does
/// not. One query over the sample tables; the library never enters memory.
final smartLyricsSampleProvider = FutureProvider<SmartLyricsSampleAccount>((
  ref,
) async {
  ref.watch(
    libraryControllerProvider.select((state) => state.valueOrNull?.songs),
  );
  return ref.watch(smartLyricsSampleStoreProvider).read();
});
