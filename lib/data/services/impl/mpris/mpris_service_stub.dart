import 'package:tune/data/services/mpris/mpris_service.dart';
import 'package:tune/data/services/mpris/mpris_snapshot.dart';

/// The media controls of a platform that has none.
///
/// The player keeps working, it just does not show up in the system media
/// controls of the desktop.
class MprisServiceImpl implements MprisService {
  @override
  Future<bool> start(MprisBackend backend) async => false;

  @override
  Future<void> update(MprisSnapshot snapshot) async {}

  @override
  void setPosition(Duration position) {}

  @override
  Future<void> dispose() async {}
}
