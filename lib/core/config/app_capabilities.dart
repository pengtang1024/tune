import 'package:tune/core/config/platform_constants.dart';

/// The platform a build runs on, as far as the shell cares.
enum AppPlatform { linux, windows, android, ios, other }

/// How this build runs a local speech engine.
///
/// `process` starts the downloaded binary for every piece of audio and keeps
/// a crash on the other side of a process boundary; `ffi` loads the runtime
/// into the app because a phone may not execute an external binary; `none`
/// leaves the local votes to the other channels.
enum LocalAsrBackend { none, process, ffi }

/// What this build actually wires up on the platform it runs on.
///
/// A capability is not a promise of the platform: it says whether the code in
/// this build does the work. Windows keeps the entry point of the desktop
/// build, but the tray, the media controls and the default player are Linux
/// only, so they stay off here until that port lands. The settings page and
/// the shell read these flags instead of asking `Platform.isLinux`
/// themselves, so a port flips one table instead of a scatter of branches.
class AppCapabilities {
  const AppCapabilities({
    required this.platform,
    required this.windowManagement,
    required this.tray,
    required this.systemMediaControls,
    required this.singleInstance,
    required this.openExternal,
    required this.defaultPlayer,
    required this.autoUpdate,
    required this.externalToolPipeline,
    required this.localAsrBackend,
    required this.nativeAudioDecoder,
    required this.lyricsSheetBesideAudio,
    required this.touchShell,
    required this.backgroundPlayback,
  });

  /// The capabilities of [platform] as this build stands today.
  factory AppCapabilities.forPlatform(AppPlatform platform) {
    switch (platform) {
      case AppPlatform.linux:
        return const AppCapabilities(
          platform: AppPlatform.linux,
          windowManagement: true,
          tray: true,
          systemMediaControls: true,
          singleInstance: true,
          openExternal: true,
          defaultPlayer: true,
          autoUpdate: true,
          externalToolPipeline: true,
          localAsrBackend: LocalAsrBackend.process,
          nativeAudioDecoder: false,
          lyricsSheetBesideAudio: true,
          touchShell: false,
          backgroundPlayback: false,
        );
      case AppPlatform.windows:
        return const AppCapabilities(
          platform: AppPlatform.windows,
          windowManagement: true,
          tray: false,
          systemMediaControls: false,
          // The loopback port keeps one player on Windows.
          singleInstance: true,
          openExternal: false,
          defaultPlayer: false,
          autoUpdate: false,
          externalToolPipeline: false,
          localAsrBackend: LocalAsrBackend.none,
          nativeAudioDecoder: false,
          lyricsSheetBesideAudio: true,
          touchShell: false,
          backgroundPlayback: false,
        );
      case AppPlatform.android:
        return const AppCapabilities(
          platform: AppPlatform.android,
          windowManagement: false,
          tray: false,
          systemMediaControls: false,
          singleInstance: false,
          openExternal: false,
          defaultPlayer: false,
          autoUpdate: false,
          externalToolPipeline: false,
          localAsrBackend: LocalAsrBackend.ffi,
          nativeAudioDecoder: true,
          lyricsSheetBesideAudio: false,
          touchShell: true,
          // audio_service keeps the sound and its notification alive after
          // the interface is gone. The device check is still pending.
          backgroundPlayback: true,
        );
      case AppPlatform.ios:
        return const AppCapabilities(
          platform: AppPlatform.ios,
          windowManagement: false,
          tray: false,
          systemMediaControls: false,
          singleInstance: false,
          openExternal: false,
          defaultPlayer: false,
          autoUpdate: false,
          externalToolPipeline: false,
          localAsrBackend: LocalAsrBackend.none,
          nativeAudioDecoder: false,
          lyricsSheetBesideAudio: false,
          touchShell: true,
          // iOS is not scheduled; nothing of the mobile milestone targets it.
          backgroundPlayback: false,
        );
      case AppPlatform.other:
        return const AppCapabilities(
          platform: AppPlatform.other,
          windowManagement: false,
          tray: false,
          systemMediaControls: false,
          singleInstance: false,
          openExternal: false,
          defaultPlayer: false,
          autoUpdate: false,
          externalToolPipeline: false,
          localAsrBackend: LocalAsrBackend.none,
          nativeAudioDecoder: false,
          lyricsSheetBesideAudio: false,
          touchShell: false,
          backgroundPlayback: false,
        );
    }
  }

  /// The capabilities of the machine the app is running on.
  static final AppCapabilities current = AppCapabilities.forPlatform(
    hostPlatform,
  );

  /// The platform this process was built for.
  static AppPlatform get hostPlatform {
    if (PlatformConstants.isLinux) return AppPlatform.linux;
    if (PlatformConstants.isWindows) return AppPlatform.windows;
    if (PlatformConstants.isAndroid) return AppPlatform.android;
    if (PlatformConstants.isIOS) return AppPlatform.ios;
    return AppPlatform.other;
  }

  final AppPlatform platform;

  /// Whether the window can be resized, moved, made full screen or small.
  final bool windowManagement;

  /// Whether the build keeps an icon in the panel of the system.
  final bool tray;

  /// Whether the player publishes to the media controls of the system
  /// (MPRIS today).
  final bool systemMediaControls;

  /// Whether a second start hands its files to the player already running.
  final bool singleInstance;

  /// Whether the build can hand a file to the file manager or the browser.
  final bool openExternal;

  /// Whether the build can offer to be the default player of the machine.
  final bool defaultPlayer;

  /// Whether the build can fetch and install its own updates.
  final bool autoUpdate;

  /// Whether the smart lyrics pipeline can call the tools of the machine:
  /// the ffmpeg transcoder and the speech engines it feeds.
  ///
  /// A phone has neither: an app may not run an external binary, and none
  /// ships with the system. The pipeline therefore reads the audio as it is
  /// there and asks only the network channels (docs/android.md).
  final bool externalToolPipeline;

  /// How the local speech engines run on this platform: the downloaded
  /// binary in a child process on the desktop, the runtime loaded into the
  /// app on Android, nowhere else (docs/android.md E5).
  final LocalAsrBackend localAsrBackend;

  /// Whether the system decoder (Android MediaCodec) can turn a compressed
  /// track into the 16 kHz mono WAV the engines read. The desktop keeps its
  /// system ffmpeg, so this is false there and `externalToolPipeline` still
  /// decides.
  final bool nativeAudioDecoder;

  /// Whether a lyrics sheet can be written next to the audio file it
  /// belongs to.
  ///
  /// Android hands an app a read-only view of shared storage: a sheet
  /// beside a track of the system library needs SAF, which this build does
  /// not wire yet. The pipeline stays off there instead of failing once per
  /// track (docs/android.md).
  final bool lyricsSheetBesideAudio;

  /// Whether the shell is drawn for a touch screen (bottom navigation).
  final bool touchShell;

  /// Whether playback survives the interface going away, with the system
  /// controls still showing it.
  final bool backgroundPlayback;

  bool get isDesktop => windowManagement;
}
