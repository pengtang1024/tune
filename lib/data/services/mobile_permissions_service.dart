/// A permission the app asks the system for while it runs.
enum MobilePermission {
  /// Shows the playback controls outside the app on Android 13 and newer.
  notifications,

  /// Reads the audio files of the phone when the library is scanned.
  mediaAudio,
}

/// What the system says about a permission.
enum MobilePermissionStatus { granted, denied, permanentlyDenied }

/// The runtime permissions of the platform the app runs on.
///
/// A desktop asks for nothing, so its implementation answers [granted] and
/// never opens a dialog. Only Android has a real one.
abstract class MobilePermissionsService {
  Future<MobilePermissionStatus> status(MobilePermission permission);

  /// Asks the system, which may show a dialog.
  ///
  /// A permission that was refused twice comes back as
  /// [MobilePermissionStatus.permanentlyDenied]: the app can no longer show a
  /// dialog and has to send the reader to the system settings.
  Future<MobilePermissionStatus> request(MobilePermission permission);

  /// Opens the settings page of the app, where a refused permission is
  /// allowed again.
  Future<void> openSettings();
}

/// The service of a platform that asks for nothing.
class UnsupportedMobilePermissionsService implements MobilePermissionsService {
  const UnsupportedMobilePermissionsService();

  @override
  Future<MobilePermissionStatus> status(MobilePermission permission) async {
    return MobilePermissionStatus.granted;
  }

  @override
  Future<MobilePermissionStatus> request(MobilePermission permission) async {
    return MobilePermissionStatus.granted;
  }

  @override
  Future<void> openSettings() async {}
}
