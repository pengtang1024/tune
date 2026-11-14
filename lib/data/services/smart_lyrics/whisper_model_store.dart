import 'dart:io';

import 'package:tune/data/services/components/local_component.dart';
import 'package:tune/data/services/components/local_component_registry.dart';
import 'package:tune/data/services/components/local_components.dart';

/// The model of the local channel could not be fetched or does not match.
class WhisperModelException implements Exception {
  final String message;

  const WhisperModelException(this.message);

  @override
  String toString() => 'WhisperModelException: $message';
}

/// The models of the local whisper channel (docs/smart-lyrics.md §6.2, M4).
///
/// The download itself belongs to the unified component installer: the store
/// only names the component of a model and hands the reader's progress
/// through. Sizes and checksums come from the registry, not from a manifest
/// fetched at download time.
class WhisperModelStore {
  final LocalComponents components;

  /// The old folder the models lived in, read for copies an earlier release
  /// left behind.
  final Directory? root;

  /// Lets a test swap the declaration of a model for a small fake file.
  final LocalComponentSpec Function(String name)? specOf;

  WhisperModelStore({
    required this.components,
    this.root,
    this.specOf,
  });

  LocalComponentSpec _specOf(String name) =>
      specOf?.call(name) ?? LocalComponentRegistry.whisperModel(name);

  /// The file of the model of [name], when it is downloaded.
  Future<File?> findModel(String name) async {
    final legacy = root;
    if (legacy != null) {
      final file = File('${legacy.path}/ggml-$name.bin');
      if (await file.exists()) return file;
    }
    final spec = _specOf(name);
    return components.file(
      spec,
      spec.requiredFiles.isEmpty ? 'ggml-$name.bin' : spec.requiredFiles.first,
    );
  }

  /// Downloads the model of [name] through the shared installer.
  Future<void> download(
    String name, {
    void Function(double progress)? onProgress,
  }) async {
    final spec = _specOf(name);
    try {
      await components.installer.install(
        spec,
        onProgress: (received, total) {
          if (total <= 0) return;
          onProgress?.call((received / total).clamp(0, 1));
        },
      );
    } catch (error) {
      throw WhisperModelException('the model of $name could not be fetched: '
          '$error');
    }
  }

  /// Bytes the downloaded model takes.
  Future<int> sizeOnDisk(String name) =>
      components.installedBytes(_specOf(name));

  /// Removes the downloaded model.
  Future<void> remove(String name) =>
      components.installer.remove(_specOf(name));
}
