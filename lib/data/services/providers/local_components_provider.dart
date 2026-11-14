import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:tune/data/services/components/local_components.dart';

/// Where the downloaded components live on this machine.
///
/// One instance for the whole app: the features resolve through it, the
/// controller installs through it, and both see the same folders.
final localComponentsProvider = FutureProvider<LocalComponents>((ref) async {
  final support = await getApplicationSupportDirectory();
  return LocalComponents(
    supportDirectory: support,
    executableDirectory: Directory(path.dirname(Platform.resolvedExecutable)),
  );
});

/// Bumped when a component is installed or removed, so every resolver that
/// cached a path looks again. Features watch this instead of importing the
/// components controller.
final localComponentsRevisionProvider = StateProvider<int>((ref) => 0);
