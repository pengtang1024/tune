import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/config/app_version.dart';
import 'package:tune/data/services/update/update_check_exception.dart';
import 'package:tune/data/services/update/update_release.dart';
import 'package:tune/features/player/application/playback_session_store_provider.dart';
import 'package:tune/data/services/update/update_service.dart';
import 'package:tune/features/player/application/playback_controller.dart';
import 'package:tune/features/settings/application/settings_controller.dart';
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

  /// Why the last check failed, when the page could not be read.
  final UpdateCheckFailure? failure;

  /// How much of the archive is downloaded, from 0 to 1.
  final double progress;

  const UpdateState({
    this.status = UpdateStatus.idle,
    this.release,
    this.error,
    this.failure,
    this.progress = 0,
  });

  UpdateState copyWith({
    UpdateStatus? status,
    UpdateRelease? release,
    String? error,
    UpdateCheckFailure? failure,
    double? progress,
  }) {
    return UpdateState(
      status: status ?? this.status,
      release: release ?? this.release,
      error: error,
      failure: failure,
      progress: progress ?? this.progress,
    );
  }
}

final updateControllerProvider =
    NotifierProvider<UpdateController, UpdateState>(UpdateController.new);

final updateServiceProvider = Provider<UpdateService>((ref) => UpdateService());

/// The version of the running build, with the build number.
///
/// The build number is part of the comparison: a rebuilt archive of the same
/// version still reaches the machines that run the older build.
final updateCurrentVersionProvider = Provider<String>(
  (ref) => '${AppVersion.version}+${AppVersion.buildNumber}',
);

/// Checks the project list and installs a newer release on Linux.
///
/// The download and the install happen here, away from the widget tree, so a
/// slow network or an unpacked archive never freezes the interface.
class UpdateController extends Notifier<UpdateState> {
  UpdateService get _service => ref.read(updateServiceProvider);

  @override
  UpdateState build() => const UpdateState();

  /// Asks the static list for the newest release.
  ///
  /// [automatic] is the scheduled check: it reuses a recent answer and logs a
  /// failure quietly, because a machine that is offline for an hour is not
  /// something the reader has to read about. A check asked for in the
  /// settings always reaches the sources and always shows the result.
  Future<void> check({String? currentVersion, bool automatic = false}) async {
    if (automatic) {
      // A download or an install in progress owns the state; a scheduled
      // check must not reset it to `checking` and lose the progress.
      final status = state.status;
      if (status == UpdateStatus.checking ||
          status == UpdateStatus.downloading ||
          status == UpdateStatus.installing ||
          status == UpdateStatus.ready) {
        return;
      }
    }
    state = state.copyWith(status: UpdateStatus.checking);
    try {
      final token = ref.read(settingsControllerProvider).githubToken;
      final release = await _service.latest(
        manualToken: token,
        forceRefresh: !automatic,
      );
      if (release == null) {
        state = const UpdateState(status: UpdateStatus.upToDate);
        return;
      }
      final current = currentVersion ?? _currentVersion();
      final latest = '${release.version}+${release.build}';
      if (!UpdateService.isNewer(current, latest)) {
        state = UpdateState(status: UpdateStatus.upToDate, release: release);
        return;
      }
      state = UpdateState(status: UpdateStatus.available, release: release);
    } on UpdateCheckException catch (error) {
      _logFailure(error, automatic: automatic);
      state = UpdateState(status: UpdateStatus.failed, failure: error.failure);
    } catch (error) {
      Log.error('检查更新失败: $error');
      state = UpdateState(status: UpdateStatus.failed, error: '$error');
    }
  }

  void _logFailure(UpdateCheckException error, {required bool automatic}) {
    final line = '检查更新失败: $error';
    if (automatic) {
      Log.debug(line);
    } else {
      Log.error(line);
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
    } on UpdateCheckException catch (error) {
      Log.error('安装更新失败: $error');
      state = UpdateState(
        status: UpdateStatus.failed,
        release: release,
        failure: error.failure,
      );
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
  ///
  /// The position of the last track is written first: the process ends right
  /// after the new one starts, and the five-second save may not have run.
  Future<void> restart() async {
    final playback = ref.read(playbackControllerProvider);
    final song = playback.currentSong;
    if (song != null) {
      await ref
          .read(playbackSessionStoreProvider)
          .savePosition(song.uri, playback.position);
    }
    await _service.restart();
  }

  static String _bundleDirectory() =>
      File(Platform.resolvedExecutable).parent.path;

  String _currentVersion() {
    return ref.read(updateCurrentVersionProvider);
  }
}
