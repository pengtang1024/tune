import 'dart:async';
import 'dart:io' show File, Platform;

import 'package:dbus/dbus.dart';
import 'package:tune/data/services/desktop/single_instance_service.dart';
import 'package:tune/data/services/desktop/startup_files.dart' as startup;
import 'package:tune/utils/logger.dart';

/// The bus name the player takes to be the one and only.
const singleInstanceBusName = 'cn.iouf.tune';

/// The object the other players talk to.
const singleInstanceObjectPath = '/cn/iouf/tune';

/// The interface the other players talk to.
const singleInstanceInterface = 'cn.iouf.tune';

/// The one player on the machine, kept on the session bus.
class SingleInstanceServiceImpl implements SingleInstanceService {
  SingleInstanceServiceImpl();

  final StreamController<List<String>> _requestedFiles =
      StreamController<List<String>>();

  final StreamController<void> _activationRequests = StreamController<void>();

  DBusClient? _client;

  @override
  Stream<List<String>> get requestedFiles => _requestedFiles.stream;

  @override
  List<String> get startupFiles =>
      startup.startupFiles(_commandLineArguments());

  @override
  Stream<void> get activationRequests => _activationRequests.stream;

  @override
  Future<bool> acquire() async {
    if (!Platform.isLinux) {
      // Other platforms have no session bus to keep a place on.
      return true;
    }

    try {
      final client = DBusClient.session();
      final reply = await client.requestName(
        singleInstanceBusName,
        flags: {DBusRequestNameFlag.doNotQueue},
      );
      final holdsPlace =
          reply == DBusRequestNameReply.primaryOwner ||
          reply == DBusRequestNameReply.alreadyOwner;

      if (!holdsPlace) {
        // Someone else is already playing; this process hands its files over
        // and leaves. The connection to the bus stays open until then.
        _client = client;
        return false;
      }

      await client.registerObject(_SingleInstanceObject(this));
      _client = client;
      Log.info('已取得播放器位置: $singleInstanceBusName');
      return true;
    } catch (error, stackTrace) {
      Log.error('取得播放器位置失败: $error\n$stackTrace');
      await _close();
      // Without a bus the player runs alone; a second start would run a
      // second player, which is worse than a player that never opens.
      return true;
    }
  }

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
  Future<void> forwardFiles(List<String> paths) async {
    if (paths.isEmpty) return;
    Log.info('把文件交给正在运行的播放器: $paths');
    await _callOwner('OpenFiles', [
      DBusArray(DBusSignature('s'), paths.map(DBusString.new)),
    ]);
  }

  @override
  Future<void> forwardActivation() async {
    await _callOwner('Activate');
  }

  @override
  Future<void> dispose() async {
    await _close();
    if (!_requestedFiles.isClosed) {
      await _requestedFiles.close();
    }
    if (!_activationRequests.isClosed) {
      await _activationRequests.close();
    }
  }

  /// Calls a method of the player that holds the place.
  Future<void> _callOwner(
    String method, [
    List<DBusValue> values = const [],
  ]) async {
    final client = _client;
    if (client == null) return;

    try {
      final owner = await client.getNameOwner(singleInstanceBusName);
      if (owner == null) return;
      await client.callMethod(
        destination: owner,
        path: DBusObjectPath(singleInstanceObjectPath),
        interface: singleInstanceInterface,
        name: method,
        values: values,
      );
    } catch (error, stackTrace) {
      Log.error('把请求交给正在运行的播放器失败: $error\n$stackTrace');
    }
  }

  /// The arguments the player was started with.
  ///
  /// The framework does not hand them over on Linux, so the command line of
  /// the process is read instead.
  static List<String> _commandLineArguments() {
    try {
      return startup.commandLineArguments(
        File('/proc/self/cmdline').readAsBytesSync(),
      );
    } catch (error, stackTrace) {
      Log.error('读不到命令行: $error\n$stackTrace');
      return const [];
    }
  }

  /// Closes the connection to the bus.
  Future<void> _close() async {
    final client = _client;
    _client = null;
    if (client == null) return;
    try {
      await client.close();
    } catch (error, stackTrace) {
      Log.error('断开与总线的连接失败: $error\n$stackTrace');
    }
  }
}

/// The object the other players talk to.
class _SingleInstanceObject extends DBusObject {
  _SingleInstanceObject(this._service)
    : super(DBusObjectPath(singleInstanceObjectPath));

  final SingleInstanceServiceImpl _service;

  @override
  Future<DBusMethodResponse> handleMethodCall(DBusMethodCall methodCall) async {
    if (methodCall.interface != singleInstanceInterface) {
      return DBusMethodErrorResponse.unknownInterface();
    }

    try {
      switch (methodCall.name) {
        case 'OpenFiles':
          final paths = methodCall.values[0]
              .asArray()
              .map((value) => value.asString())
              .toList();
          _service.requestFiles(paths);
          return DBusMethodSuccessResponse();
        case 'Activate':
          _service.requestActivation();
          return DBusMethodSuccessResponse();
        default:
          return DBusMethodErrorResponse.unknownMethod();
      }
    } catch (error, stackTrace) {
      Log.error('处理来自其它播放器的请求失败: $error\n$stackTrace');
      return DBusMethodErrorResponse.failed('$error');
    }
  }
}
