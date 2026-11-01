/// The local sherpa-onnx channel failed (docs/smart-lyrics.md §6.2, M12).
class SherpaLocalException implements Exception {
  final String message;

  const SherpaLocalException(this.message);

  @override
  String toString() => 'SherpaLocalException: $message';
}
