import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/core/l10n/app_strings.dart';
import 'package:tune/data/services/providers/library_paths_provider.dart';
import 'package:tune/data/services/smart_lyrics/openai_compatible_engine.dart';
import 'package:tune/data/services/smart_lyrics/smart_lyrics_text.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/features/player/domain/lyrics_document.dart';
import 'package:tune/features/settings/application/settings_controller.dart';
import 'package:tune/features/smart_lyrics/domain/smart_lyrics_contrast.dart';
import 'package:tune/utils/logger.dart';

/// The text side alone: the assist the contrasts run on, on the endpoint
/// and key the pipeline already uses. `null` when the reader configured
/// no text model — the buttons of the panel grey out with it.
final smartLyricsAssistProvider = Provider<SmartTextAssist?>((ref) {
  // Watch the three fields the client actually reads: watching the whole
  // config would rebuild the client on every keystroke and close the Dio
  // an in-flight translation is still using.
  final (baseUrl, apiKey, chatModel) = ref.watch(
    settingsControllerProvider.select(
      (state) => (
        state.smartLyrics.baseUrl,
        state.smartLyrics.apiKey,
        state.smartLyrics.chatModel,
      ),
    ),
  );
  final model = chatModel.split(',').first.trim();
  if (model.isEmpty || baseUrl.trim().isEmpty) return null;
  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(minutes: 2),
      sendTimeout: const Duration(minutes: 2),
    ),
  );
  ref.onDispose(dio.close);
  return SmartTextAssist(
    client: OpenAiCompatibleClient(dio: dio, baseUrl: baseUrl, apiKey: apiKey),
    model: model,
  );
});

/// The contrasts of [song] that hold for the sheet the reader sees now:
/// the record on the disk, matched against the sheet's own date — a
/// regenerated sheet lets the old contrasts go quiet (docs/smart-lyrics.md
/// §7.5).
final songContrastProvider = FutureProvider.family<SmartSongContrast, Song>((
  ref,
  song,
) async {
  final paths = ref.watch(libraryPathsProvider);
  final record = contrastFromJson(await paths.readSmartContrast(song));
  if (record == null || record.isEmpty) return SmartSongContrast.empty;

  final sheet =
      await paths.readLyrics(song) ?? await paths.readSmartLyrics(song);
  if (sheet == null || sheet.trim().isEmpty) return SmartSongContrast.empty;

  final key = contrastSheetKey(sheet) ?? record.sheetDate;
  if (record.sheetDate != key) return SmartSongContrast.empty;
  return record;
});

/// The presses that make a contrast (docs/smart-lyrics.md §7.5, M7): each
/// kind is made once per sheet, line for line, and lands in the small
/// json beside the sheet.
final smartLyricsContrastControllerProvider =
    Provider<SmartLyricsContrastController>(
      (ref) => SmartLyricsContrastController(ref),
    );

class SmartLyricsContrastController {
  final Ref _ref;

  var _busy = false;

  SmartLyricsContrastController(this._ref);

  /// Whether a contrast is being made right now — the panel greys its
  /// buttons with it, so each kind is asked for once.
  bool get busy => _busy;

  /// Makes the translation of the sheet [song] carries.
  Future<bool> translate(Song song) => _run(song, transliterate: false);

  /// Makes the transliteration of the sheet [song] carries.
  Future<bool> transliterate(Song song) => _run(song, transliterate: true);

  Future<bool> _run(Song song, {required bool transliterate}) async {
    if (_busy) return false;
    final assist = _ref.read(smartLyricsAssistProvider);
    if (assist == null) return false;
    final paths = _ref.read(libraryPathsProvider);

    final sheet =
        await paths.readLyrics(song) ?? await paths.readSmartLyrics(song);
    if (sheet == null || sheet.trim().isEmpty) return false;
    final lines = [
      for (final line in LyricsDocument.parse(sheet).lines) line.text,
    ];
    if (lines.isEmpty) return false;

    final target = _targetLanguage();
    _busy = true;
    try {
      final done = transliterate
          ? await assist.transliterateLines(lines: lines)
          : await assist.translateLines(lines: lines, targetLanguage: target);

      // The record is keyed by the sheet it speaks about: a previous
      // record of another sheet is void, one of this sheet stays half
      // whole — doing the translation does not cost the transliteration.
      final key = contrastSheetKey(sheet) ?? _today();
      final previous = contrastFromJson(await paths.readSmartContrast(song));
      final current =
          previous != null && previous.sheetDate == key
              ? previous
              : SmartSongContrast(sheetDate: key);
      final merged = SmartSongContrast(
        sheetDate: key,
        translationLanguage: transliterate
            ? current.translationLanguage
            : target,
        translation: transliterate ? current.translation : done,
        transliteration: transliterate ? done : current.transliteration,
      );
      await paths.saveSmartContrast(song, contrastToJson(merged));
      _ref.invalidate(songContrastProvider(song));
      return true;
    } catch (error, stackTrace) {
      Log.error('对照生成失败: $error', stackTrace);
      return false;
    } finally {
      _busy = false;
    }
  }

  /// The language the reader does not read in: the contrasts are the way
  /// through a song of another tongue, so the target is the other side of
  /// wherever the interface stands.
  String _targetLanguage() => AppStrings.instance.smartContrastTargetLanguage;

  static String _today() =>
      DateTime.now().toIso8601String().substring(0, 10);
}
