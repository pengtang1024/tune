import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/data/services/desktop/default_player_service.dart';
import 'package:tune/data/services/desktop/single_instance_service.dart';
import 'package:tune/data/services/impl/desktop/default_player_service_io.dart';
import 'package:tune/data/services/impl/desktop/single_instance_service_io.dart';

/// The one player on the machine.
final singleInstanceServiceProvider = Provider<SingleInstanceService>((ref) {
  final service = SingleInstanceServiceImpl();
  ref.onDispose(() => service.dispose());
  return service;
});

/// The default handler of audio files, as the desktop sees it.
final defaultPlayerServiceProvider = Provider<DefaultPlayerService>((ref) {
  return DefaultPlayerServiceImpl();
});
