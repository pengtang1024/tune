import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:tune/data/services/desktop/single_instance_service.dart';
import 'package:tune/data/services/desktop/startup_files.dart' as startup;
import 'package:tune/utils/logger.dart';

/// Keeps one player on a machine that has no session bus, which is Windows.
///
/// The first player holds a loopback port. A later start finds the port taken,
/// says hello, hands its files over and leaves. The port is loopback only and
/// the peer has to answer the handshake, so another program that happens to
/// hold the same port is not mistaken for the player.
class SocketSingleInstanceService implements SingleInstanceService {
  SocketSingleInstanceService({
    this.port = defaultPort,
    List<String> arguments = const [],
  }) : _arguments = arguments;

  /// The port the player holds on this machine.
  static const int defaultPort = 47321;

  /// The word a player answers the greeting with.
  static const String _helloAnswer = 'TUNE';

  /// The word a start says to find out whether the port is a player.
  static const String _helloRequest = 'hello';

  final int port;

  /// The arguments this start was given.
  ///
  /// On Windows the runner hands the command line to `main`, so the files a
  /// start named arrive here instead of being read from `/proc`.
  final List<String> _arguments;

  final StreamController<List<String>> _requestedFiles =
      StreamController<List<String>>();

  final StreamController<void> _activationRequests = StreamController<void>();

  ServerSocket? _server;

  final List<Socket> _clients = [];

  @override
  List<String> get startupFiles => startup.startupFiles(_arguments);

  @override
  Stream<List<String>> get requestedFiles => _requestedFiles.stream;

  @override
  Stream<void> get activationRequests => _activationRequests.stream;

  @override
  Future<bool> acquire() async {
    try {
      final server = await ServerSocket.bind(
        InternetAddress.loopbackIPv4,
        port,
      );
      _server = server;
      server.listen(_accept);
      Log.info('已取得播放器端口: $port');
      return true;
    } on SocketException {
      // Either the player is already running or another program holds the
      // port. Only a peer that answers the handshake is the player.
      final answer = await _ask(_helloRequest);
      if (answer == _helloAnswer) {
        Log.info('已有播放器在运行: $port');
        return false;
      }
      Log.info('端口 $port 被其它程序占用，本次独立运行');
      return true;
    }
  }

  void _accept(Socket socket) {
    _clients.add(socket);
    late final StreamSubscription<String> subscription;
    subscription = socket
        .cast<List<int>>()
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(
          (line) => _handle(socket, line),
          onDone: () => _drop(socket, subscription),
          onError: (Object error, StackTrace stackTrace) {
            Log.error('单实例连接出错: $error\n$stackTrace');
            _drop(socket, subscription);
          },
          cancelOnError: true,
        );
  }

  /// Answers one line of the protocol.
  ///
  /// The greeting gets its word back; the other lines are a command that is
  /// handed to the player. A line that is not of this protocol is ignored.
  void _handle(Socket socket, String line) {
    if (line == _helloRequest) {
      socket.writeln(_helloAnswer);
      unawaited(
        socket.flush().then((_) => socket.destroy()).catchError((Object _) {}),
      );
      return;
    }

    try {
      final message = jsonDecode(line);
      if (message is! Map<String, dynamic>) return;
      final files = message['files'];
      if (files is List) {
        requestFiles(
          files.whereType<String>().where((path) => path.isNotEmpty).toList(),
        );
        return;
      }
      if (message['activate'] == true) requestActivation();
    } catch (error, stackTrace) {
      Log.error('读不懂来自其它播放器的请求: $error\n$stackTrace');
    }
  }

  void _drop(Socket socket, StreamSubscription<String> subscription) {
    _clients.remove(socket);
    socket.destroy();
    subscription.cancel();
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
    await _send({'files': paths});
  }

  @override
  Future<void> forwardActivation() async {
    await _send(const {'activate': true});
  }

  /// Sends one line to the player that holds the port.
  Future<void> _send(Map<String, Object?> message) async {
    Socket? socket;
    try {
      socket = await Socket.connect(
        InternetAddress.loopbackIPv4,
        port,
        timeout: const Duration(milliseconds: 500),
      );
      socket.writeln(jsonEncode(message));
      await socket.flush();
    } catch (error, stackTrace) {
      Log.error('把请求交给正在运行的播放器失败: $error\n$stackTrace');
    } finally {
      socket?.destroy();
    }
  }

  /// Says one word to the port and returns the first line it hears.
  Future<String?> _ask(String message) async {
    Socket? socket;
    try {
      socket = await Socket.connect(
        InternetAddress.loopbackIPv4,
        port,
        timeout: const Duration(milliseconds: 500),
      );
      socket.writeln(message);
      await socket.flush();
      return await socket
          .cast<List<int>>()
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .first
          .timeout(const Duration(milliseconds: 500));
    } catch (_) {
      return null;
    } finally {
      socket?.destroy();
    }
  }

  @override
  Future<void> dispose() async {
    // Destroying a socket ends its subscription, which removes it from this
    // list, so the walk takes a copy.
    for (final client in List<Socket>.of(_clients)) {
      client.destroy();
    }
    _clients.clear();
    await _server?.close();
    _server = null;
    // A single-subscription controller only finishes its close when a reader
    // listens, and a start that ends has none. Closing it without waiting
    // keeps the disposal from hanging on its own streams.
    if (!_requestedFiles.isClosed) unawaited(_requestedFiles.close());
    if (!_activationRequests.isClosed) {
      unawaited(_activationRequests.close());
    }
  }
}
