/// Execution limits applied to one plugin runtime.
///
/// A plugin is third-party code that runs inside the app. The limits keep a
/// misbehaving plugin from freezing the user interface or from exhausting the
/// memory of the whole application.
class MusicPluginLimits {
  /// Maximum wall time of a single plugin call.
  ///
  /// A plugin that answers slower than this is treated as stuck.
  final Duration callTimeout;

  /// Maximum wall time a runtime instance may stay alive.
  ///
  /// Exceeding the budget retires the runtime; the next call builds a fresh
  /// one, which keeps long lived sessions from accumulating state.
  final Duration runtimeBudget;

  /// Extra heap the plugin may use before the sandbox stops it.
  ///
  /// The value is a delta over the memory the process used when the sandbox
  /// started, so the rest of the application is never counted against it.
  final int memoryLimitBytes;

  /// Maximum size of an imported script.
  final int maxScriptBytes;

  const MusicPluginLimits({
    this.callTimeout = const Duration(seconds: 45),
    this.runtimeBudget = const Duration(minutes: 15),
    this.memoryLimitBytes = 128 * 1024 * 1024,
    this.maxScriptBytes = 2 * 1024 * 1024,
  });

  /// Human readable memory budget, used in error messages.
  String get memoryLimitLabel => '${memoryLimitBytes ~/ (1024 * 1024)} MB';
}
