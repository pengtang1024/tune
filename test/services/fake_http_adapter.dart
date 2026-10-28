import 'dart:async';
import 'dart:typed_data';
import 'dart:convert' show utf8;

import 'package:dio/dio.dart';

/// Answers every request with the same bytes and remembers what was asked.
class FakeHttpAdapter implements HttpClientAdapter {
  /// Holds the answer until the test releases it.
  Completer<void>? gate;

  /// When set the request fails with this error.
  Object? failure;

  /// The body every answer carries.
  ///
  /// When it is null the answer is a filler of the same size.
  String? body;

  /// The addresses that were requested.
  final List<String> requestedUrls = [];

  /// The requests that were made, with their headers and their data.
  final List<RequestOptions> requests = [];

  final List<void Function()> _arrivals = [];

  /// Completes as soon as a request reaches the adapter.
  Future<void> waitForRequest() {
    if (requestedUrls.isNotEmpty) return Future<void>.value();
    final completer = Completer<void>();
    _arrivals.add(completer.complete);
    return completer.future;
  }

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requestedUrls.add(options.uri.toString());
    requests.add(options);
    for (final arrival in List.of(_arrivals)) {
      arrival();
    }
    _arrivals.clear();

    final gate = this.gate;
    if (gate != null) {
      await gate.future;
    }
    final failure = this.failure;
    if (failure != null) {
      throw failure;
    }
    final body = this.body;
    final bytes = body == null
        ? Uint8List.fromList(List<int>.filled(1024, 7))
        : Uint8List.fromList(utf8.encode(body));
    return ResponseBody(
      Stream<Uint8List>.value(bytes),
      200,
      headers: {
        Headers.contentLengthHeader: [bytes.length.toString()],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
