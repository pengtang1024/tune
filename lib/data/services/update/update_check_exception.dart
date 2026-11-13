/// How a check of the project page failed.
///
/// The check used to fold every failure into "no release", which the
/// controller showed as "already the newest". The kinds below keep the
/// difference, so the interface can tell the reader the page was not read.
enum UpdateCheckFailure {
  /// The page refused the request, usually because the address asked too
  /// often in an hour.
  rateLimited,

  /// The token the request carried is not accepted.
  unauthorized,

  /// The request timed out or the network is unreachable.
  network,

  /// The page answered, but not with a release.
  server,
}

/// The check failed; the caller reports it instead of "already the newest".
///
/// The exception carries no message and no request details: a token may
/// travel with the request, and it must never reach a log.
class UpdateCheckException implements Exception {
  const UpdateCheckException(this.failure, {this.statusCode});

  final UpdateCheckFailure failure;
  final int? statusCode;

  @override
  String toString() =>
      'UpdateCheckException(${failure.name}, status: $statusCode)';
}
