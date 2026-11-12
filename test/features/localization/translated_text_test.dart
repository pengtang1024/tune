import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/features/localization/application/localization_providers.dart';
import 'package:tune/l10n/app_localizations.dart';
import 'package:tune/shared/ui/translated_text.dart';

void main() {
  testWidgets('the translation sits above the original line', (tester) async {
    await tester.pumpWidget(
      _app(
        overrides: [
          translatedTextProvider.overrideWith((ref, request) async => '绿中蓝'),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('绿中蓝'), findsOneWidget);
    expect(find.text('Blue in Green'), findsOneWidget);
  });

  testWidgets('without a translation the original keeps the line', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        overrides: [
          translatedTextProvider.overrideWith((ref, request) async => null),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Blue in Green'), findsOneWidget);
    expect(find.text('绿中蓝'), findsNothing);
  });

  testWidgets('a prefix keeps the words that are not translated', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        overrides: [
          translatedTextProvider.overrideWith((ref, request) async {
            return request.text == 'Blue in Green' ? '绿中蓝' : null;
          }),
        ],
        child: const TranslatedText(text: 'Blue in Green', prefix: 'Miles · '),
      ),
    );
    await tester.pumpAndSettle();

    // The artist keeps its words, the album is translated, and the original
    // of the album waits under the line.
    expect(find.text('Miles · 绿中蓝'), findsOneWidget);
    expect(find.text('Blue in Green'), findsOneWidget);
    expect(find.text('Miles · Blue in Green'), findsNothing);
  });

  testWidgets('a paragraph keeps both halves whole', (tester) async {
    const description =
        'A long description of a track that would not fit in one line, '
        'so the sheet writes it out as a paragraph.';
    await tester.pumpWidget(
      _app(
        overrides: [
          translatedTextProvider.overrideWith((ref, request) async {
            return request.text == description ? '一段很长很长的简介。' : null;
          }),
        ],
        child: const TranslatedText(
          text: description,
          maxLines: null,
          secondaryMaxLines: null,
          selectable: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('一段很长很长的简介。'), findsOneWidget);
    expect(find.text(description), findsOneWidget);
    for (final text in tester.widgetList<SelectableText>(
      find.byType(SelectableText),
    )) {
      expect(text.maxLines, isNull);
    }
  });
}

Widget _app({required List<Override> overrides, Widget? child}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      locale: const Locale('zh'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: child ?? const TranslatedText(text: 'Blue in Green'),
      ),
    ),
  );
}
