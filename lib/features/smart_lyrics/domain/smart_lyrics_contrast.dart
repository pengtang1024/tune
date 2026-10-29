import 'dart:convert';

/// The contrasts of one song (docs/smart-lyrics.md §7.5, M7): the
/// translation and the transliteration of the sheet, kept beside the
/// sheet in one small json.
///
/// The record is keyed by the sheet it was made from. A machine sheet
/// carries its date in the header; when the pipeline writes the sheet
/// again, the date moves on and the old contrasts go quiet by themselves
/// — no cleanup, no dangling words under lines that shifted.
class SmartSongContrast {
  /// The date the sheet the contrasts were made from carries; for a sheet
  /// without a header, the day the contrasts were made.
  final String sheetDate;

  /// The language the translation is in, when there is one.
  final String? translationLanguage;

  /// The translation, line for line with the sheet.
  final List<String>? translation;

  /// The transliteration, line for line with the sheet.
  final List<String>? transliteration;

  const SmartSongContrast({
    required this.sheetDate,
    this.translationLanguage,
    this.translation,
    this.transliteration,
  });

  static const SmartSongContrast empty = SmartSongContrast(sheetDate: '');

  bool get isEmpty => translation == null && transliteration == null;

  Map<String, dynamic> toJson() => {
    'sheetDate': sheetDate,
    if (translationLanguage != null) 'translationLanguage': translationLanguage,
    if (translation != null) 'translation': translation,
    if (transliteration != null) 'transliteration': transliteration,
  };

  /// Reads the record back; a broken field falls to nothing — a contrast
  /// the app cannot read is no contrast, never a crash.
  factory SmartSongContrast.fromJson(Map<String, dynamic> json) {
    List<String>? linesOf(Object? value) => value is List &&
            value.every((line) => line is String)
        ? List<String>.from(value)
        : null;

    return SmartSongContrast(
      sheetDate: json['sheetDate'] is String ? json['sheetDate'] as String : '',
      translationLanguage: json['translationLanguage'] is String
          ? json['translationLanguage'] as String
          : null,
      translation: linesOf(json['translation']),
      transliteration: linesOf(json['transliteration']),
    );
  }
}

/// The date the machine header of [sheet] carries, `null` when the sheet
/// has no header of its own.
String? contrastSheetKey(String sheet) {
  final match = RegExp(r'\[date:([^\]]+)\]').firstMatch(sheet);
  return match?.group(1);
}

/// The record the file on the disk holds, `null` when it holds nothing
/// readable.
SmartSongContrast? contrastFromJson(String? raw) {
  if (raw == null || raw.trim().isEmpty) return null;
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) return null;
    return SmartSongContrast.fromJson(decoded);
  } on FormatException {
    return null;
  }
}

/// The json the record travels in.
String contrastToJson(SmartSongContrast contrast) =>
    jsonEncode(contrast.toJson());
