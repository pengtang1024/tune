/// What the system knows about Tune as a handler of audio files.
///
/// The desktop decides which program opens an audio file by looking at the
/// desktop entries of the installed programs. These are the questions that
/// decision needs answered.
abstract class DefaultPlayerService {
  /// Whether the desktop can name Tune as the default handler.
  bool get isSupported;

  /// Whether the desktop entry of Tune is installed.
  ///
  /// The desktop only accepts a program it knows, so the entry has to be in
  /// place before Tune can become the default.
  Future<bool> isDesktopEntryInstalled();

  /// Whether Tune handles [mimeType] by default right now.
  Future<bool> isDefaultHandler(String mimeType);

  /// Makes Tune the default handler of [mimeType].
  Future<bool> makeDefaultHandler(String mimeType);
}
