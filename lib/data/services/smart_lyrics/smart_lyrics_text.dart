import 'dart:convert';

import 'package:tune/core/l10n/app_strings.dart';
import 'package:tune/data/services/smart_lyrics/openai_compatible_engine.dart';

/// The correction failed: the draft does not survive as a sheet.
class SmartLyricsTextException implements Exception {
  final String message;

  const SmartLyricsTextException(this.message);

  @override
  String toString() => 'SmartLyricsTextException: $message';
}

/// The text side of the smart lyrics pipeline (docs/smart-lyrics.md §6.4):
/// the correction of a machine draft, and the rebuild a text model offers
/// from its own knowledge of a song.
///
/// Only text travels here — the audio never leaves through this door.
class SmartTextAssist {
  final OpenAiCompatibleClient client;
  final String model;

  SmartTextAssist({required this.client, required this.model});

  /// Corrects a machine draft, line for line.
  ///
  /// The answer must hold exactly as many lines as the draft: a corrected
  /// sheet that grew or shrank would not fit the timeline the transcript
  /// read off the audio. Such an answer is a failure, not a guess.
  Future<List<String>> correctLines({
    required String title,
    required String artist,
    required List<String> lines,
  }) async {
    final strings = AppStrings.instance;
    final content = await client.complete(
      model: model,
      prompt: strings.smartPromptCorrect(title, artist, jsonEncode(lines)),
    );
    return _linesOf(content, expected: lines.length);
  }

  /// Rebuilds the words of a song from what the model knows of it.
  ///
  /// The lines come back without a timeline of their own; the vote only
  /// counts when they align with a machine sheet (`alignKnowledgeVote`).
  Future<List<String>> rebuildLyrics({
    required String title,
    required String artist,
  }) async {
    final content = await client.complete(
      model: model,
      prompt: AppStrings.instance.smartPromptRebuild(title, artist),
    );
    return _linesOf(content);
  }

  /// The lines a model answer holds, once the fence is off and the JSON is
  /// read; a model that answered with prose drops out here.
  List<String> _linesOf(String content, {int? expected}) {
    final unfenced = content.replaceAll(RegExp(r'^```[a-z]*\n|\n```$'), '');
    Object? decoded;
    try {
      decoded = jsonDecode(unfenced);
    } on FormatException {
      throw SmartLyricsTextException('the answer is not JSON: $content');
    }
    if (decoded is! List || decoded.any((line) => line is! String)) {
      throw SmartLyricsTextException('the answer is not lines: $content');
    }
    final lines = List<String>.from(decoded);
    if (expected != null && lines.length != expected) {
      throw SmartLyricsTextException(
        'the answer holds ${lines.length} lines, the draft had $expected',
      );
    }
    return lines;
  }
}
