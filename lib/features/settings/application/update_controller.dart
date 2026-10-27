import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/config/app_version.dart';
import 'package:tune/data/services/update/update_release.dart';
import 'package:tune/data/services/update/update_service.dart';
import 'package:tune/utils/logger.dart';

/// Where the update stands.
enum UpdateStatus {
  idle,
  checking,
  upToDate,
  available,
  downloading,
  installing,
  ready,
  failed,
}

class UpdateState {
  final UpdateStatus status;
  final UpdateRelease? release;
  final String? error;

  /// How much of the archive is downloaded, from 0 to 1.
  final double progress;

  const UpdateState({
    this.status = UpdateStatus.idle,
    this.release,
    this.error,
    this.progress = 0,
  });

  UpdateState copyWith({
    UpdateStatus? status,
    UpdateRelease? release,
    String? error,
    double? progress,
  }) {
    return UpdateState(
      status: status ?? this.status,
      release: release ?? this.release,
      error: error,
      progress: progress ?? this.progress,
    );
  }
}

final updateControllerProvider =
    NotifierProvider<UpdateController, UpdateState>(UpdateController.new);

final updateServiceProvider = Provider<UpdateService>((ref) => UpdateService());

/// The version of the running build.
final updateCurrentVersionProvider = Provider<String>(
  (ref) => AppVersion.version,
);

/// Checks the project page and installs a newer release on Linux.
///
/// The download and the install happen here, away from the widget tree, so a
/// slow network or an unpacked archive never freezes the interface.
class UpdateController extends Notifier<UpdateState> {
  UpdateService get _service => ref.read(updateServiceProvider);

  @override
  UpdateState build() => const UpdateState();

  /// Asks the project page for the newest release.
  Future<void> check({String? currentVersion}) async {
    state = state.copyWith(status: UpdateStatus.checking);
    try {
      final release = await _service.latest();
      if (release == null) {
        state = const UpdateState(status: UpdateStatus.upToDate);
        return;
      }
      final current = currentVersion ?? _currentVersion();
      if (!UpdateService.isNewer(current, release.version)) {
        state = UpdateState(status: UpdateStatus.upToDate, release: release);
        return;
      }
      state = UpdateState(status: UpdateStatus.available, release: release);
    } catch (error) {
      Log.error('检查更新失败: $error');
      state = UpdateState(status: UpdateStatus.failed, error: '$error');
    }
  }

  /// Downloads the archive of the release and unpacks it into the bundle.
  Future<void> install() async {
    final release = state.release;
    final asset = release?.asset;
    if (release == null || asset == null) return;
    if (!Platform.isLinux) {
      state = state.copyWith(status: UpdateStatus.available);
      return;
    }

    state = state.copyWith(status: UpdateStatus.downloading, progress: 0);
    final archive = '${Directory.systemTemp.path}/${asset.name}';
    try {
      await _service.download(
        asset,
        archive,
        onProgress: (progress) {
          state = state.copyWith(
            status: UpdateStatus.downloading,
            progress: progress,
          );
        },
      );
      state = state.copyWith(status: UpdateStatus.installing);
      await _service.installLinux(archive, _bundleDirectory());
      state = state.copyWith(status: UpdateStatus.ready);
    } catch (error) {
      Log.error('安装更新失败: $error');
      state = UpdateState(
        status: UpdateStatus.failed,
        release: release,
        error: '$error',
      );
    }
  }

  /// Starts the new build and ends the running one.
  Future<void> restart() => _service.restart();

  static String _bundleDirectory() =>
      File(Platform.resolvedExecutable).parent.path;

  String _currentVersion() {
    return ref.read(updateCurrentVersionProvider);
  }
}
