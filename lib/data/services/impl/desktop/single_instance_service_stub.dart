import 'dart:async';

import 'package:tune/data/services/desktop/single_instance_service.dart';

/// The one player on a platform that has no session bus.
///
/// Every start is a player of its own, so the files of the command line are
/// simply opened.
class SingleInstanceServiceImpl implements SingleInstanceService {
  final StreamController<List<String>> _requestedFiles =
      StreamController<List<String>>();

  final StreamController<void> _activationRequests = StreamController<void>();

  @override
  Stream<List<String>> get requestedFiles => _requestedFiles.stream;

  @override
  Stream<void> get activationRequests => _activationRequests.stream;

  @override
  Future<bool> acquire() async => true;

  @override
  List<String> get startupFiles => const [];

  @override
  void requestFiles(List<String> paths) {
    if (paths.isEmpty) return;
    if (_requestedFiles.isClosed) return;
    _requestedFiles.add(paths);
  }

  @override
  void requestActivation() {
    if (_activationRequests.isClosed) return;
    _activationRequests.add(null);
  }

  @override
  Future<void> forwardFiles(List<String> paths) async {}

  @override
  Future<void> forwardActivation() async {}

  @override
  Future<void> dispose() async {
    if (!_requestedFiles.isClosed) {
      await _requestedFiles.close();
    }
    if (!_activationRequests.isClosed) {
      await _activationRequests.close();
    }
  }
}
