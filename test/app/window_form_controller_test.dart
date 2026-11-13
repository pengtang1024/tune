import 'package:flutter_test/flutter_test.dart';
import 'package:tune/app/layout/window_form_controller.dart';
import 'package:tune/data/services/window_layout_store.dart';

import '../services/fake_persistence.dart';

void main() {
  test('the controller starts from the form on disk', () {
    final persistence = FakePersistenceService()
      ..values[WindowLayoutStore.formKey] = WindowForm.mini.name;

    final controller = WindowFormController(WindowLayoutStore(persistence));
    addTearDown(controller.dispose);

    expect(controller.state, WindowForm.mini);
  });

  test('the controller writes the form it is given', () async {
    final persistence = FakePersistenceService();
    final store = WindowLayoutStore(persistence);
    final controller = WindowFormController(store);
    addTearDown(controller.dispose);

    await controller.setForm(WindowForm.immersive);

    expect(controller.state, WindowForm.immersive);
    expect(store.readForm(), WindowForm.immersive);
  });

  test('setting the same form writes nothing', () async {
    final persistence = FakePersistenceService();
    final store = WindowLayoutStore(persistence);
    final controller = WindowFormController(store);
    addTearDown(controller.dispose);

    await controller.setForm(WindowForm.normal);

    expect(persistence.values.containsKey(WindowLayoutStore.formKey), isFalse);
  });
}
