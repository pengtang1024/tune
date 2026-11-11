import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/features/localization/application/localization_providers.dart';
import 'package:tune/features/localization/domain/text_language.dart';
import 'package:tune/features/settings/application/settings_controller.dart';
import 'package:tune/shared/ui/bilingual_text.dart';

/// One line of text, translated into the language of the interface.
///
/// The translation is the main line and the original follows in small type.
/// The widget reads the setting and the cache itself, so a row does not have
/// to know where a translation comes from: it only gives the text and the
/// style it would have used, and the line stays the original when there is
/// no translation to show.
class TranslatedText extends ConsumerWidget {
  final String text;
  final TextStyle? style;
  final int? maxLines;
  final int? secondaryMaxLines;
  final TextAlign? textAlign;

  /// Whether the line sits in a tight list and needs no gap of its own.
  final bool dense;

  /// Whether the lines may be selected and copied.
  final bool selectable;

  /// A fixed part of the main line that must not be translated.
  ///
  /// A byline says the artist and then the album: only the album goes to the
  /// translator, and the artist keeps its words. The prefix carries
  /// `artist · ` without handing the name to the model.
  final String? prefix;

  const TranslatedText({
    super.key,
    required this.text,
    this.style,
    this.maxLines = 1,
    this.secondaryMaxLines = 1,
    this.textAlign,
    this.dense = false,
    this.selectable = false,
    this.prefix,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final target = targetLanguageOf(Localizations.localeOf(context));
    final config = ref.watch(
      settingsControllerProvider.select((settings) => settings.localization),
    );
    final translation = ref
        .watch(translatedTextProvider((text: text, targetLanguage: target)))
        .value;
    final head = prefix ?? '';
    if (translation == null || translation == text) {
      return Text(
        '$head$text',
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
        textAlign: textAlign,
        style: style,
      );
    }
    return BilingualText(
      primary: '$head$translation',
      secondary: config.showOriginal ? text : null,
      maxLines: maxLines,
      secondaryMaxLines: secondaryMaxLines,
      primaryStyle: style,
      textAlign: textAlign,
      dense: dense,
      selectable: selectable,
    );
  }
}
