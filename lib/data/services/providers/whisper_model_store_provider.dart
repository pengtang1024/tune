import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/data/services/providers/local_components_provider.dart';
import 'package:tune/data/services/smart_lyrics/whisper_assets.dart';
import 'package:tune/data/services/smart_lyrics/whisper_model_store.dart';

/// The store the local models are downloaded through, on this machine.
final whisperModelStoreProvider = FutureProvider<WhisperModelStore>((
  ref,
) async {
  ref.watch(localComponentsRevisionProvider);
  final components = await ref.watch(localComponentsProvider.future);
  final assets = await WhisperAssets.appDefault(components: components);
  return WhisperModelStore(
    root: Directory(assets.modelsFolder),
    components: components,
  );
});
