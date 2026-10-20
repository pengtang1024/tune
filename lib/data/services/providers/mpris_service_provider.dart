import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/data/services/impl/mpris/mpris_service_stub.dart'
    if (dart.library.io) 'package:tune/data/services/impl/mpris/mpris_service_io.dart';
import 'package:tune/data/services/mpris/mpris_service.dart';

/// The media controls of the desktop.
///
/// The web build has no session bus, so it uses the stub that does nothing.
final mprisServiceProvider = Provider<MprisService>((ref) {
  final service = MprisServiceImpl();
  ref.onDispose(() => service.dispose());
  return service;
});
