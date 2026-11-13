import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/core/config/platform_constants.dart';
import 'package:tune/data/services/desktop/default_player_service.dart';
import 'package:tune/data/services/desktop/single_instance_service.dart';
import 'package:tune/data/services/impl/desktop/default_player_service_io.dart';
import 'package:tune/data/services/impl/desktop/single_instance_service_io.dart';
import 'package:tune/data/services/impl/desktop/socket_single_instance_service.dart';

/// The arguments the runner handed to `main`.
///
/// Linux reads its command line from `/proc`; Windows gets the words here, so
/// a file that a start names reaches the single instance service as well.
final startupArgumentsProvider = Provider<List<String>>((ref) => const []);

/// The one player on the machine.
///
/// Linux keeps its place on the session bus. Windows has no such bus, so the
/// player holds a loopback port instead.
final singleInstanceServiceProvider = Provider<SingleInstanceService>((ref) {
  final service = PlatformConstants.isWindows
      ? SocketSingleInstanceService(
          arguments: ref.read(startupArgumentsProvider),
        )
      : SingleInstanceServiceImpl();
  ref.onDispose(() => service.dispose());
  return service;
});

/// The default handler of audio files, as the desktop sees it.
final defaultPlayerServiceProvider = Provider<DefaultPlayerService>((ref) {
  return DefaultPlayerServiceImpl();
});
