/// Keeps one player on the machine and hands the files to it.
///
/// The player takes a place on the session bus when it starts. A second
/// start finds the place taken, hands its files over to the running player
/// and leaves, so the machine never has two players fighting over the sound
/// card.
abstract class SingleInstanceService {
  /// Takes the place of the player on the bus.
  ///
  /// Returns whether this process is the one that holds the place.
  Future<bool> acquire();

  /// The files the command line of this start named.
  List<String> get startupFiles;

  /// The files the player should open.
  ///
  /// The files come from the command line of the first start and from the
  /// starts that came later. The stream keeps them until the player listens,
  /// so a file that arrives before the player is ready is not lost.
  Stream<List<String>> get requestedFiles;

  /// The moments when the player should show its window.
  ///
  /// A start that only wants to wake the running player up says so here.
  Stream<void> get activationRequests;

  /// Opens the files in this process.
  void requestFiles(List<String> paths);

  /// Asks this process to show its window.
  void requestActivation();

  /// Hands the files over to the player that holds the place.
  Future<void> forwardFiles(List<String> paths);

  /// Asks the player that holds the place to show its window.
  Future<void> forwardActivation();

  /// Releases the place.
  Future<void> dispose();
}
