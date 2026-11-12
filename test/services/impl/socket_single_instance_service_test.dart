import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tune/data/services/impl/desktop/socket_single_instance_service.dart';

/// A port that was free a moment ago.
Future<int> freePort() async {
  final socket = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
  final port = socket.port;
  await socket.close();
  return port;
}

void main() {
  test('the second start hands its files and its wish to show the window', () async {
    final port = await freePort();
    final first = SocketSingleInstanceService(port: port);
    final second = SocketSingleInstanceService(port: port);
    addTearDown(first.dispose);
    addTearDown(second.dispose);

    expect(await first.acquire(), isTrue);
    expect(await second.acquire(), isFalse);

    final files = first.requestedFiles.first;
    final activation = first.activationRequests.first;

    await second.forwardFiles(['/music/one.mp3', '/music/two.flac']);
    await second.forwardActivation();

    expect(await files, ['/music/one.mp3', '/music/two.flac']);
    await activation;
  });

  test('the words of a start become the files it plays', () {
    final service = SocketSingleInstanceService(
      arguments: const ['/music/one.mp3', '--flag', '', '/music/two.flac'],
    );
    addTearDown(service.dispose);

    expect(service.startupFiles, ['/music/one.mp3', '/music/two.flac']);
  });

  test('a port held by another program is not the player', () async {
    final foreign = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final subscriptions = <StreamSubscription<Object?>>[];
    subscriptions.add(
      foreign.listen((socket) {
        subscriptions.add(
          socket
              .cast<List<int>>()
              .transform(utf8.decoder)
              .transform(const LineSplitter())
              .listen((line) {
                socket.writeln('HTTP/1.1 400 Bad Request');
                unawaited(socket.flush().then((_) => socket.destroy()));
              }),
        );
      }),
    );
    addTearDown(() async {
      for (final subscription in subscriptions) {
        await subscription.cancel();
      }
      await foreign.close();
    });

    final service = SocketSingleInstanceService(port: foreign.port);
    addTearDown(service.dispose);

    // The port answers, but not as a player, so this start runs on its own.
    expect(await service.acquire(), isTrue);
    expect(service.startupFiles, isEmpty);
  });
}
