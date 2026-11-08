import 'package:tune/shared/utils/plain_text.dart';

/// The beginning of a description, as plain text.
///
/// Sources write a description as HTML or as markdown of whatever length the
/// uploader left; a track keeps the readable beginning of it so the details of
/// a song stay one screen long.
String? shortDescription(Object? raw, {int length = 600}) {
  final text = plainText(raw?.toString() ?? '');
  if (text.isEmpty) return null;
  if (text.length <= length) return text;
  return '${text.substring(0, length).trimRight()}…';
}
