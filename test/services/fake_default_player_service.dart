import 'package:tune/data/services/desktop/default_player_service.dart';

/// A stand-in for the desktop that answers without asking the system.
///
/// The service of the desktop shells out to `xdg-mime`, which changes the
/// associations of the machine the tests run on. The fake keeps the calls
/// instead, so a test can see what the settings asked the desktop to do.
class FakeDefaultPlayerService implements DefaultPlayerService {
  /// Whether the desktop entry of Tune is in place.
  bool entryInstalled;

  /// Whether Tune is already the default handler.
  bool isDefault;

  /// The audio types the settings made Tune the default handler of.
  final List<String> madeDefault = <String>[];

  FakeDefaultPlayerService({
    this.entryInstalled = true,
    this.isDefault = false,
  });

  @override
  bool get isSupported => true;

  @override
  Future<bool> isDesktopEntryInstalled() async => entryInstalled;

  @override
  Future<bool> isDefaultHandler(String mimeType) async => isDefault;

  @override
  Future<bool> makeDefaultHandler(String mimeType) async {
    madeDefault.add(mimeType);
    isDefault = true;
    return true;
  }
}
