import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:tune/data/services/translation/translation_assets.dart';
import 'package:tune/data/services/translation/translation_prompt.dart';
import 'package:tune/domain/models/localization_config.dart';
import 'package:tune/domain/models/translation_engine.dart';

/// The offline engine: llama.cpp running a small Qwen model on the CPU.
///
/// One process per batch. Part of the model load is paid on every batch, so
/// the caller batches the rows that appear together instead of asking for
/// one title at a time.
class LlamaLocalTranslationEngine implements TranslationEngine {
  final TranslationAssets assets;
  final int threads;
  final Duration timeout;

  LlamaLocalTranslationEngine({
    required this.assets,
    int? threads,
    this.timeout = const Duration(minutes: 3),
  }) : threads = threads ?? max(1, min(4, Platform.numberOfProcessors));

  @override
  String get id => 'local:${LocalizationConfig.localModelId}';

  @override
  Future<TranslationBatch> translate(
    List<String> texts, {
    required String targetLanguage,
  }) async {
    if (texts.isEmpty) return const TranslationBatch(translations: {});
    final status = await assets.inspect(verifyDigest: true);
    if (!status.ready) {
      throw TranslationException(switch (status.problem) {
        TranslationAssetProblem.modelMissing =>
          'the bundled offline model is missing',
        TranslationAssetProblem.modelCorrupt =>
          'the bundled offline model failed verification',
        TranslationAssetProblem.binaryMissing =>
          'the bundled llama.cpp runtime is missing',
        TranslationAssetProblem.none => 'the offline model is unavailable',
      }, unavailable: true);
    }
    final binary = await assets.findBinary();
    if (binary == null) {
      throw const TranslationException(
        'the bundled llama.cpp runtime is missing',
        unavailable: true,
      );
    }

    final prompt = _chatPrompt(texts, targetLanguage);
    final process = await Process.start(
      binary,
      [
        '-m',
        assets.modelFile.path,
        '-p',
        prompt,
        '-n',
        '${_maxTokens(texts.length)}',
        '-t',
        '$threads',
        '--temp',
        '0',
        '--top-k',
        '1',
        '--repeat-penalty',
        '1.0',
        '--no-display-prompt',
        '--no-warmup',
        '--simple-io',
        '-r',
        '<|im_end|>',
      ],
      environment: {
        'LD_LIBRARY_PATH': [
          File(binary).parent.path,
          assets.binDirectory.path,
        ].join(':'),
      },
      includeParentEnvironment: true,
    );

    final stdoutFuture = process.stdout.transform(utf8.decoder).join();
    final stderrFuture = process.stderr.transform(utf8.decoder).join();
    await process.stdin.close();

    final int exitCode;
    try {
      exitCode = await process.exitCode.timeout(timeout);
    } on TimeoutException {
      process.kill();
      throw const TranslationException('the offline run timed out');
    }
    final output = await stdoutFuture;
    final errors = await stderrFuture;
    if (exitCode != 0) {
      throw TranslationException(
        'the offline run exited with $exitCode: ${_tail(errors)}',
      );
    }
    final translations = parseTranslationPayload(output, texts);
    if (translations.isEmpty) {
      throw TranslationException(
        'the offline run gave no usable answer: ${_tail(output)}',
      );
    }
    return TranslationBatch(translations: translations);
  }

  static int _maxTokens(int count) => min(512, max(96, count * 48));

  static String _tail(String value) {
    final trimmed = value.trim();
    if (trimmed.length <= 300) return trimmed;
    return trimmed.substring(trimmed.length - 300);
  }
}

/// Wraps the instruction and the items in Qwen's ChatML template.
///
/// The template is written out instead of relying on conversation mode: a
/// one-shot completion is what a batch runner needs, and it does not leave a
/// process waiting on a terminal that will never type.
String _chatPrompt(List<String> texts, String targetLanguage) {
  final buffer = StringBuffer()
    ..writeln('<|im_start|>system')
    ..writeln(translationInstruction(targetLanguage))
    ..writeln('<|im_end|>')
    ..writeln('<|im_start|>user')
    ..writeln(translationPayload(texts))
    ..writeln('<|im_end|>')
    ..writeln('<|im_start|>assistant');
  return buffer.toString();
}
