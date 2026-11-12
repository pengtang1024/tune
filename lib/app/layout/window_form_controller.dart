import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/data/services/window_layout_store.dart';
import 'package:tune/providers/persistence_providers.dart';

/// The form the window takes, shared by the shell and the pages that ask for
/// another form.
///
/// The form is the one piece of the window the reader changes on purpose, so
/// it is state with a provider. The size and the place belong to the window
/// itself and are written by the window service; nothing in the interface
/// needs to watch them.
final windowFormProvider =
    StateNotifierProvider<WindowFormController, WindowForm>((ref) {
      final persistence = ref.watch(persistenceServiceProvider);
      return WindowFormController(WindowLayoutStore(persistence));
    });

class WindowFormController extends StateNotifier<WindowForm> {
  WindowFormController(this._store) : super(_store.readForm());

  final WindowLayoutStore _store;

  Future<void> setForm(WindowForm form) async {
    if (state == form) return;
    state = form;
    await _store.saveForm(form);
  }
}
