import 'package:permission_handler/permission_handler.dart';
import 'package:tune/data/services/mobile_permissions_service.dart';

/// The permissions of Android, asked through `permission_handler`.
///
/// The plugin keeps the differences between the versions of Android: the
/// media library is `READ_MEDIA_AUDIO` from Android 13 and
/// `READ_EXTERNAL_STORAGE` before it. Both are asked in one call and the
/// version the phone understands answers, so this class never reads the SDK
/// number itself.
class PermissionHandlerMobilePermissionsService
    implements MobilePermissionsService {
  const PermissionHandlerMobilePermissionsService();

  static const _media = [Permission.audio, Permission.storage];

  @override
  Future<MobilePermissionStatus> status(MobilePermission permission) {
    switch (permission) {
      case MobilePermission.notifications:
        return _read([Permission.notification]);
      case MobilePermission.mediaAudio:
        return _read(_media);
    }
  }

  @override
  Future<MobilePermissionStatus> request(MobilePermission permission) async {
    switch (permission) {
      case MobilePermission.notifications:
        final status = await Permission.notification.request();
        return _of([status]);
      case MobilePermission.mediaAudio:
        final statuses = await _media.request();
        return _of(statuses.values);
    }
  }

  @override
  Future<void> openSettings() => openAppSettings();

  /// Reads the status of the permissions without asking.
  static Future<MobilePermissionStatus> _read(
    List<Permission> permissions,
  ) async {
    final statuses = await Future.wait(permissions.map((it) => it.status));
    return _of(statuses);
  }

  static MobilePermissionStatus _of(Iterable<PermissionStatus> statuses) {
    if (statuses.any(
      (status) => status.isGranted || status.isLimited || status.isProvisional,
    )) {
      return MobilePermissionStatus.granted;
    }
    if (statuses.any((status) => status.isPermanentlyDenied)) {
      return MobilePermissionStatus.permanentlyDenied;
    }
    return MobilePermissionStatus.denied;
  }
}
