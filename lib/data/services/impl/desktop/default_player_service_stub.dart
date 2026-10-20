import 'package:tune/data/services/desktop/default_player_service.dart';

/// The default handler of audio files on a platform that has no desktop
/// associations.
///
/// Nothing can be registered, so the button in the settings stays out of the
/// way.
class DefaultPlayerServiceImpl implements DefaultPlayerService {
  @override
  bool get isSupported => false;

  @override
  Future<bool> isDesktopEntryInstalled() async => false;

  @override
  Future<bool> isDefaultHandler(String mimeType) async => false;

  @override
  Future<bool> makeDefaultHandler(String mimeType) async => false;
}
