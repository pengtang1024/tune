import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/core/config/platform_constants.dart';
import 'package:tune/data/services/impl/permission_handler_mobile_permissions_service.dart';
import 'package:tune/data/services/mobile_permissions_service.dart';

/// The runtime permissions of the platform this build runs on.
///
/// Only Android asks; the other builds answer [granted] so the pages that
/// read this provider keep one shape.
final mobilePermissionsServiceProvider = Provider<MobilePermissionsService>((
  ref,
) {
  if (PlatformConstants.isAndroid) {
    return const PermissionHandlerMobilePermissionsService();
  }
  return const UnsupportedMobilePermissionsService();
});
