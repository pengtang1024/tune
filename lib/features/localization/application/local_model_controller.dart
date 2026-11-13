import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/data/services/translation/local_model_installer.dart';
import 'package:tune/data/services/translation/translation_assets.dart';
import 'package:tune/features/localization/application/localization_providers.dart';

enum LocalModelPhase {
  checking,
  notInstalled,
  downloading,
  verifying,
  ready,
  failed,
}

class LocalModelState {
  final LocalModelPhase phase;
  final TranslationAssetProblem? problem;
  final String? message;
  final int received;
  final int total;
  final int installedBytes;
  final bool canDelete;

  const LocalModelState(
    this.phase, {
    this.problem,
    this.message,
    this.received = 0,
    this.total = 0,
    this.installedBytes = 0,
    this.canDelete = false,
  });

  bool get ready => phase == LocalModelPhase.ready;

  bool get busy =>
      phase == LocalModelPhase.checking ||
      phase == LocalModelPhase.downloading ||
      phase == LocalModelPhase.verifying;

  double? get progress => total > 0 ? received / total : null;

  LocalModelState copyWith({
    LocalModelPhase? phase,
    TranslationAssetProblem? problem,
    String? message,
    int? received,
    int? total,
    int? installedBytes,
    bool? canDelete,
  }) {
    return LocalModelState(
      phase ?? this.phase,
      problem: problem ?? this.problem,
      message: message ?? this.message,
      received: received ?? this.received,
      total: total ?? this.total,
      installedBytes: installedBytes ?? this.installedBytes,
      canDelete: canDelete ?? this.canDelete,
    );
  }
}

/// Reports, downloads and removes the optional local translation component.
///
/// The check is on demand: nothing here runs at startup unless the reader
/// chose the local backend or opened its block in the settings page.
class LocalModelController extends StateNotifier<LocalModelState> {
  LocalModelController({
    required Future<TranslationAssets> Function() resolveAssets,
    LocalModelInstaller? installer,
    VoidCallback? onAssetsChanged,
  }) : _resolveAssets = resolveAssets,
       _installer = installer,
       _onAssetsChanged = onAssetsChanged,
       super(const LocalModelState(LocalModelPhase.checking)) {
    unawaited(refresh());
  }

  final Future<TranslationAssets> Function() _resolveAssets;
  final LocalModelInstaller? _installer;
  final VoidCallback? _onAssetsChanged;

  CancelToken? _cancelToken;

  Future<void> refresh({bool verifyDigest = false}) async {
    try {
      final assets = await _resolveAssets();
      final status = await assets.inspect(verifyDigest: verifyDigest);
      if (!mounted) return;
      switch (status.problem) {
        case TranslationAssetProblem.none:
          state = LocalModelState(
            LocalModelPhase.ready,
            installedBytes: await assets.installedSize(),
            canDelete: assets.userInstalled,
          );
          return;
        case TranslationAssetProblem.modelMissing:
          state = const LocalModelState(LocalModelPhase.notInstalled);
          return;
        case TranslationAssetProblem.modelCorrupt:
        case TranslationAssetProblem.binaryMissing:
          state = LocalModelState(
            LocalModelPhase.failed,
            problem: status.problem,
          );
          return;
      }
    } catch (error) {
      if (!mounted) return;
      state = LocalModelState(
        LocalModelPhase.failed,
        message: '$error',
      );
    }
  }

  Future<void> download() async {
    if (state.busy) return;
    final previous = state;
    state = LocalModelState(
      LocalModelPhase.downloading,
      installedBytes: previous.installedBytes,
      canDelete: previous.canDelete,
    );
    _cancelToken = CancelToken();
    try {
      final assets = await _resolveAssets();
      final installer =
          _installer ??
          LocalModelInstaller(
            supportDirectory: Directory(assets.supportPath),
          );
      await installer.install(
        cancelToken: _cancelToken,
        onProgress: (received, total) {
          if (!mounted) return;
          state = state.copyWith(received: received, total: total);
        },
      );
      if (!mounted) return;
      state = state.copyWith(phase: LocalModelPhase.verifying);
      _onAssetsChanged?.call();
      await refresh(verifyDigest: true);
    } on DioException catch (error) {
      if (!mounted) return;
      if (CancelToken.isCancel(error)) {
        state = const LocalModelState(LocalModelPhase.notInstalled);
        return;
      }
      state = LocalModelState(
        LocalModelPhase.failed,
        message: error.message ?? error.type.name,
      );
    } catch (error) {
      if (!mounted) return;
      state = LocalModelState(
        LocalModelPhase.failed,
        message: '$error',
      );
    } finally {
      _cancelToken = null;
    }
  }

  void cancelDownload() {
    _cancelToken?.cancel('the reader cancelled the download');
    _cancelToken = null;
  }

  Future<void> remove() async {
    if (state.busy || !state.canDelete) return;
    try {
      final assets = await _resolveAssets();
      final installer =
          _installer ??
          LocalModelInstaller(
            supportDirectory: Directory(assets.supportPath),
          );
      await installer.remove();
      _onAssetsChanged?.call();
      await refresh();
    } catch (error) {
      if (!mounted) return;
      state = LocalModelState(
        LocalModelPhase.failed,
        message: '$error',
      );
    }
  }
}

final localModelControllerProvider = StateNotifierProvider.autoDispose<
  LocalModelController,
  LocalModelState
>((ref) {
  return LocalModelController(
    resolveAssets: TranslationAssets.forApp,
    onAssetsChanged: () => ref.invalidate(translationAssetsProvider),
  );
});
