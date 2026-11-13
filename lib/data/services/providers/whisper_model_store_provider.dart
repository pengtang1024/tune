import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/data/services/smart_lyrics/whisper_assets.dart';
import 'package:tune/data/services/smart_lyrics/whisper_model_store.dart';

/// The store the local models are downloaded through, on this machine.
final whisperModelStoreProvider = FutureProvider<WhisperModelStore>((
  ref,
) async {
  final assets = await WhisperAssets.appDefault();
  return WhisperModelStore(root: Directory(assets.modelsFolder));
});
