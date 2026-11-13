import 'dart:convert';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:tune/core/config/platform_constants.dart';
import 'package:tune/data/services/window_layout_store.dart';

import 'fake_persistence.dart';

void main() {
  late FakePersistenceService persistence;
  late WindowLayoutStore store;

  setUp(() {
    persistence = FakePersistenceService();
    store = WindowLayoutStore(persistence);
  });

  test('a store that never wrote a window has no geometry', () {
    expect(store.readGeometry(), isNull);
    expect(store.readForm(), WindowForm.normal);
  });

  test('geometry keeps its size and place', () async {
    await store.saveGeometry(
      const WindowGeometry(width: 1200, height: 800, left: 40, top: 24),
    );

    final geometry = store.readGeometry()!;
    expect(geometry.size, const Size(1200, 800));
    expect(geometry.position, const Offset(40, 24));
    expect(geometry.maximized, isFalse);
  });

  test('a window below the minimum of the desktop is restored at it', () async {
    await store.saveGeometry(const WindowGeometry(width: 320, height: 200));

    final geometry = store.readGeometry()!;
    expect(geometry.width, PlatformConstants.desktopWindowMinWidth);
    expect(geometry.height, PlatformConstants.desktopWindowMinHeight);
    expect(geometry.position, isNull);
  });

  test('a document that is not ours is ignored', () {
    persistence.values[WindowLayoutStore.geometryKey] = '[]';
    expect(store.readGeometry(), isNull);

    persistence.values[WindowLayoutStore.geometryKey] = jsonEncode({
      'width': 'wide',
      'height': 800,
    });
    expect(store.readGeometry(), isNull);

    // A number that does not fit a double comes back as infinity, which no
    // window can be sized with.
    persistence.values[WindowLayoutStore.geometryKey] =
        '{"width": 1e999, "height": 800}';
    expect(store.readGeometry(), isNull);
  });

  test('a maximized window keeps the size of the normal form', () async {
    await store.saveGeometry(
      const WindowGeometry(
        width: 1200,
        height: 800,
        left: 40,
        top: 24,
        maximized: true,
      ),
    );

    final geometry = store.readGeometry()!;
    expect(geometry.size, const Size(1200, 800));
    expect(geometry.position, const Offset(40, 24));
    expect(geometry.maximized, isTrue);
  });

  test('the form survives a restart', () async {
    await store.saveForm(WindowForm.mini);
    expect(WindowLayoutStore(persistence).readForm(), WindowForm.mini);

    await store.saveForm(WindowForm.immersive);
    expect(WindowLayoutStore(persistence).readForm(), WindowForm.immersive);

    await store.saveForm(WindowForm.normal);
    expect(WindowLayoutStore(persistence).readForm(), WindowForm.normal);
  });

  test('an unknown form falls back to the normal one', () {
    persistence.values[WindowLayoutStore.formKey] = 'floating';

    expect(store.readForm(), WindowForm.normal);
  });
}
