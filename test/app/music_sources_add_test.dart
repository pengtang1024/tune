import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/app/theme/compact_theme.dart';
import 'package:tune/domain/models/music_source.dart';
import 'package:tune/features/library/application/library_controller.dart';
import 'package:tune/features/library/domain/library_state.dart';
import 'package:tune/features/sources/presentation/sources_pane.dart';
import 'package:tune/l10n/app_localizations.dart';
import 'package:tune/providers/persistence_providers.dart';
import '../services/fake_persistence.dart';

/// The reader adds the sources of their own.
///
/// A type says how the tracks are fetched; an instance says which one. The
/// reader picks a type, fills the form the type declares, and the source
/// joins the list of the ones they added.
void main() {
  late FakePersistenceService persistence;
  late FakeLibraryController library;

  setUp(() {
    persistence = FakePersistenceService()..values['language_code'] = 'zh';
    library = FakeLibraryController(const LibraryState());
  });

  Widget app() {
    return ProviderScope(
      overrides: [
        persistenceServiceProvider.overrideWithValue(persistence),
        libraryControllerProvider.overrideWith(() => library),
      ],
      child: MaterialApp(
        theme: CompactTheme.light,
        locale: const Locale('zh', 'CN'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: SourcesPane()),
      ),
    );
  }

  testWidgets('the reader picks a type to add', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('sources-add')));
    await tester.pumpAndSettle();

    // The types the app serves are offered. The local folder is a setting of
    // the app, not an instance the reader adds.
    expect(
      find.byKey(const ValueKey('source-type-openverse')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('source-type-local')), findsNothing);
  });

  testWidgets('the reader adds an instance of the type they picked', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('sources-add')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('source-type-openverse')));
    await tester.pumpAndSettle();

    // The form asks for the name of the instance and for what the type needs.
    expect(find.byKey(const ValueKey('source-field-name')), findsOneWidget);
    expect(find.byKey(const ValueKey('source-field-query')), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('source-field-name')),
      '深夜爵士',
    );
    await tester.tap(find.byKey(const ValueKey('source-form-save')));
    await tester.pumpAndSettle();

    // The source joins the group of the ones the reader added.
    expect(find.text('我添加的'), findsOneWidget);
    expect(find.text('深夜爵士'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('source-switch-openverse-1')),
      findsOneWidget,
    );
  });

  testWidgets('the reader removes an instance and its tracks', (tester) async {
    persistence.values['music_sources_v1'] = jsonEncode([
      {
        'id': 'openverse-1',
        'type': 'openverse',
        'name': '深夜爵士',
        'kind': 'custom',
        'enabled': true,
        'settings': const {'query': 'jazz'},
      },
    ]);

    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    expect(find.text('深夜爵士'), findsOneWidget);

    final menu = find.byKey(const ValueKey('source-menu-openverse-1'));
    await tester.ensureVisible(menu);
    await tester.pumpAndSettle();
    await tester.tap(menu);
    await tester.pumpAndSettle();
    await tester.tap(find.text('删除'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('source-delete-confirm')));
    await tester.pumpAndSettle();

    // The source is gone, and the tracks it brought in went with it.
    expect(find.text('深夜爵士'), findsNothing);
    expect(library.dropped, ['openverse-1']);
  });

  group('the id of a new instance', () {
    test('the first instance of a type is type:1', () {
      final instance = newSourceInstance(
        type: 'subsonic',
        typeName: 'Subsonic',
        name: '',
        sources: const [],
      );

      expect(instance.id, 'subsonic-1');
      expect(instance.name, 'Subsonic 1');
    });

    test('the next instance of a type takes the next number', () {
      const first = MusicSourceConfig(
        id: 'subsonic-1',
        type: 'subsonic',
        name: '家',
        kind: MusicSourceKind.custom,
      );

      final instance = newSourceInstance(
        type: 'subsonic',
        typeName: 'Subsonic',
        name: '',
        sources: const [first],
      );

      expect(instance.id, 'subsonic-2');
    });

    test('another type does not take a number', () {
      const other = MusicSourceConfig(
        id: 'podcast_rss-1',
        type: 'podcast_rss',
        name: '播客',
        kind: MusicSourceKind.custom,
      );

      final instance = newSourceInstance(
        type: 'subsonic',
        typeName: 'Subsonic',
        name: '',
        sources: const [other],
      );

      expect(instance.id, 'subsonic-1');
    });

    test('the name the reader gives is kept', () {
      final instance = newSourceInstance(
        type: 'subsonic',
        typeName: 'Subsonic',
        name: '  公司  ',
        sources: const [],
      );

      expect(instance.name, '公司');
    });
  });
}

/// The library without the tracks of a source.
class FakeLibraryController extends LibraryController {
  FakeLibraryController(this.seed);

  final LibraryState seed;

  /// The sources whose tracks were dropped.
  final List<String> dropped = [];

  @override
  Future<LibraryState> build() async => seed;

  @override
  Future<void> scan(List<String> paths, {bool auto = false}) async {}

  @override
  Future<void> dropSource(String sourceId) async {
    dropped.add(sourceId);
  }
}
