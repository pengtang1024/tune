import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/data/services/impl/library_paths.dart';
import 'package:tune/data/services/library/library_paths.dart';
import 'package:tune/providers/persistence_providers.dart';

/// The one place that knows where the files of the app live: in the music
/// library of the machine.
final libraryPathsProvider = Provider<LibraryPaths>((ref) {
  final persistence = ref.watch(persistenceServiceProvider);
  return createLibraryPaths(persistence);
});
