import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/data/services/mobile_permissions_service.dart';
import 'package:tune/data/services/providers/mobile_permissions_providers.dart';

/// What the system says about the permissions the app asks for.
class MobilePermissionsState {
  const MobilePermissionsState({
    required this.notifications,
    required this.mediaAudio,
  });

  final MobilePermissionStatus notifications;
  final MobilePermissionStatus mediaAudio;

  MobilePermissionStatus of(MobilePermission permission) {
    switch (permission) {
      case MobilePermission.notifications:
        return notifications;
      case MobilePermission.mediaAudio:
        return mediaAudio;
    }
  }

  MobilePermissionsState copyWith({
    MobilePermissionStatus? notifications,
    MobilePermissionStatus? mediaAudio,
  }) {
    return MobilePermissionsState(
      notifications: notifications ?? this.notifications,
      mediaAudio: mediaAudio ?? this.mediaAudio,
    );
  }
}

/// The permissions page of the settings, and the first scan.
///
/// The state is what the system answered last. A request updates it, so the
/// page shows the new answer without asking the system again. Nothing is
/// stored here: the system is the one source of truth.
class MobilePermissionsController
    extends AsyncNotifier<MobilePermissionsState> {
  @override
  Future<MobilePermissionsState> build() async {
    final service = ref.read(mobilePermissionsServiceProvider);
    return MobilePermissionsState(
      notifications: await service.status(MobilePermission.notifications),
      mediaAudio: await service.status(MobilePermission.mediaAudio),
    );
  }

  /// Asks the system for [permission] and keeps its answer.
  Future<MobilePermissionStatus> request(MobilePermission permission) async {
    final service = ref.read(mobilePermissionsServiceProvider);
    final status = await service.request(permission);
    final current = state.valueOrNull;
    if (current != null) {
      state = AsyncData(switch (permission) {
        MobilePermission.notifications => current.copyWith(
          notifications: status,
        ),
        MobilePermission.mediaAudio => current.copyWith(mediaAudio: status),
      });
    }
    return status;
  }

  /// Asks [permission] only while it is not granted yet.
  ///
  /// A first scan calls this: a reader who already allowed the permission is
  /// never asked a second time.
  Future<bool> ensure(MobilePermission permission) async {
    final current = await future;
    if (current.of(permission) == MobilePermissionStatus.granted) return true;
    if (current.of(permission) == MobilePermissionStatus.permanentlyDenied) {
      return false;
    }
    return await request(permission) == MobilePermissionStatus.granted;
  }

  /// Sends the reader to the system settings of the app.
  Future<void> openSettings() {
    return ref.read(mobilePermissionsServiceProvider).openSettings();
  }
}

final mobilePermissionsControllerProvider =
    AsyncNotifierProvider<MobilePermissionsController, MobilePermissionsState>(
      MobilePermissionsController.new,
    );
