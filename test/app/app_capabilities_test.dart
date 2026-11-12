import 'package:flutter_test/flutter_test.dart';
import 'package:tune/core/config/app_capabilities.dart';

void main() {
  test('the Linux build wires up every desktop integration', () {
    final capabilities = AppCapabilities.forPlatform(AppPlatform.linux);

    expect(capabilities.platform, AppPlatform.linux);
    expect(capabilities.isDesktop, isTrue);
    expect([
      capabilities.windowManagement,
      capabilities.tray,
      capabilities.systemMediaControls,
      capabilities.singleInstance,
      capabilities.openExternal,
      capabilities.defaultPlayer,
      capabilities.autoUpdate,
      capabilities.externalToolPipeline,
      capabilities.lyricsSheetBesideAudio,
    ], everyElement(isTrue));
    expect(capabilities.touchShell, isFalse);
    expect(capabilities.backgroundPlayback, isFalse);
  });

  test('Windows keeps the window and the one player on the machine', () {
    final capabilities = AppCapabilities.forPlatform(AppPlatform.windows);

    expect(capabilities.platform, AppPlatform.windows);
    expect(capabilities.windowManagement, isTrue);
    expect(capabilities.singleInstance, isTrue);
    expect(capabilities.isDesktop, isTrue);
    // The tray, the media controls and the default player still need a
    // Windows port of their own.
    expect([
      capabilities.tray,
      capabilities.systemMediaControls,
      capabilities.openExternal,
      capabilities.defaultPlayer,
      capabilities.autoUpdate,
      capabilities.externalToolPipeline,
    ], everyElement(isFalse));
    // A sheet is still a file on a disk the build may write.
    expect(capabilities.lyricsSheetBesideAudio, isTrue);
  });

  test('a mobile build draws the touch shell and no desktop integration', () {
    for (final platform in [AppPlatform.android, AppPlatform.ios]) {
      final capabilities = AppCapabilities.forPlatform(platform);

      expect(capabilities.platform, platform);
      expect(capabilities.touchShell, isTrue);
      expect(capabilities.isDesktop, isFalse);
      expect([
        capabilities.windowManagement,
        capabilities.tray,
        capabilities.systemMediaControls,
        capabilities.singleInstance,
        capabilities.defaultPlayer,
        capabilities.autoUpdate,
        capabilities.externalToolPipeline,
        capabilities.lyricsSheetBesideAudio,
      ], everyElement(isFalse));
      // The notification that keeps the sound alive is part of the Android
      // milestone; iOS is not scheduled.
      expect(capabilities.backgroundPlayback, platform == AppPlatform.android);
    }
  });

  test('an unknown platform offers nothing', () {
    final capabilities = AppCapabilities.forPlatform(AppPlatform.other);

    expect(capabilities.platform, AppPlatform.other);
    expect(capabilities.isDesktop, isFalse);
    expect(capabilities.touchShell, isFalse);
  });

  test('the running build reports the platform it was built for', () {
    expect(AppCapabilities.current.platform, AppCapabilities.hostPlatform);
  });
}
