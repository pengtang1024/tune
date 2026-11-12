import 'package:tune/data/services/mobile_permissions_service.dart';

/// A permission service that records what the page asked for.
class FakeMobilePermissionsService implements MobilePermissionsService {
  FakeMobilePermissionsService({
    this.notifications = MobilePermissionStatus.granted,
    this.mediaAudio = MobilePermissionStatus.granted,
    this.answers,
  });

  MobilePermissionStatus notifications;
  MobilePermissionStatus mediaAudio;

  /// What [request] answers. A null entry keeps the current status.
  final Map<MobilePermission, MobilePermissionStatus>? answers;

  int requests = 0;
  int openedSettings = 0;

  @override
  Future<MobilePermissionStatus> status(MobilePermission permission) async {
    return switch (permission) {
      MobilePermission.notifications => notifications,
      MobilePermission.mediaAudio => mediaAudio,
    };
  }

  @override
  Future<MobilePermissionStatus> request(MobilePermission permission) async {
    requests++;
    final answer =
        answers?[permission] ??
        switch (permission) {
          MobilePermission.notifications => notifications,
          MobilePermission.mediaAudio => mediaAudio,
        };
    switch (permission) {
      case MobilePermission.notifications:
        notifications = answer;
      case MobilePermission.mediaAudio:
        mediaAudio = answer;
    }
    return answer;
  }

  @override
  Future<void> openSettings() async {
    openedSettings++;
  }
}
