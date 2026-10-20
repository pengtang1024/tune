import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/data/services/impl/library_paths.dart';
import 'package:tune/data/services/library/library_paths.dart';
import 'package:tune/providers/persistence_providers.dart';

/// The one place that knows where the files of the app live.
///
/// The paths follow the platform: a build with a file system keeps them in
/// the music library of the machine, the web build keeps nothing on disk.
final libraryPathsProvider = Provider<LibraryPaths>((ref) {
  final persistence = ref.watch(persistenceServiceProvider);
  return createLibraryPaths(persistence);
});
