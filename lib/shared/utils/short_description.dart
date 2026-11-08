import 'package:tune/shared/utils/plain_text.dart';

/// The beginning of a description that is already plain text.
///
/// Sources hand over descriptions of whatever length the uploader left; a
/// track keeps the readable beginning of one, so the details of a song stay one
/// screen long.
String? shorten(String? text, {int length = 600}) {
  // A tag taken out leaves a space behind: "a <b>case</b>." becomes
  // "a case .", so a space before a mark of punctuation is closed up.
  final collapsed = (text ?? '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .replaceAllMapped(
        RegExp(r'\s+([,.;:!?])'),
        (match) => match.group(1)!,
      )
      .trim();
  if (collapsed.isEmpty) return null;
  if (collapsed.length <= length) return collapsed;
  return '${collapsed.substring(0, length).trimRight()}…';
}

/// The beginning of a description written as HTML.
String? shortDescription(Object? raw, {int length = 600}) =>
    shorten(plainText(raw?.toString() ?? ''), length: length);
