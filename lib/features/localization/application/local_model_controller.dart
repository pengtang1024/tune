import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/data/services/translation/translation_assets.dart';
import 'package:tune/features/localization/application/localization_providers.dart';

enum LocalModelPhase { checking, ready, missing, corrupt, failed }

class LocalModelState {
  final LocalModelPhase phase;
  final String? message;

  const LocalModelState(this.phase, {this.message});

  bool get ready => phase == LocalModelPhase.ready;
  bool get busy => phase == LocalModelPhase.checking;
}

/// Reports whether the model bundled with the installer is usable.
///
/// The files arrive with the release archive, so there is nothing to download
/// or delete here; the check exists to tell the user to reinstall when the
/// model is missing or damaged.
class LocalModelController extends StateNotifier<LocalModelState> {
  LocalModelController(this._assets)
    : super(const LocalModelState(LocalModelPhase.checking)) {
    unawaited(refresh());
  }

  final Future<TranslationAssets> _assets;

  Future<void> refresh() async {
    try {
      final assets = await _assets;
      final status = await assets.inspect(verifyDigest: true);
      if (!mounted) return;
      state = LocalModelState(switch (status.problem) {
        TranslationAssetProblem.none => LocalModelPhase.ready,
        TranslationAssetProblem.modelMissing => LocalModelPhase.missing,
        TranslationAssetProblem.modelCorrupt => LocalModelPhase.corrupt,
        TranslationAssetProblem.binaryMissing => LocalModelPhase.missing,
      });
    } catch (error) {
      if (!mounted) return;
      state = LocalModelState(LocalModelPhase.failed, message: '$error');
    }
  }
}

final localModelControllerProvider =
    StateNotifierProvider<LocalModelController, LocalModelState>((ref) {
      return LocalModelController(ref.watch(translationAssetsProvider.future));
    });
