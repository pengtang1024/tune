/// One local capability, downloaded and removed on its own.
///
/// The registry owns the list ([LocalComponentSpec]); the installer owns how
/// a file comes home; the controller owns what the reader sees. A feature
/// only reads the result (docs/local-components.md).
enum LocalComponentKind { runtime, model }

/// What a component is to the reader. The settings page maps this to a
/// localized title; no Chinese lives in the data layer.
enum LocalComponentLabel {
  translationRuntime,
  translationModel,
  translationModelLow,
  translationModelQuality,
  whisperRuntime,
  whisperModelTiny,
  whisperModelBase,
  whisperModelSmall,
  whisperModelLargeTurbo,
  sherpaRuntime,
  sensevoiceModel,
  ffmpeg,
}

/// How an archive is packed, so the installer picks the right decoder.
enum LocalComponentArchive { none, zip, tarGz, tarBz2, tarXz }

/// Where a component stands. `checking` is the only transient state the
/// settings page shows without a button.
enum LocalComponentPhase {
  checking,
  notInstalled,
  downloading,
  verifying,
  ready,
  failed,
}

/// One file of a component: where it comes from and what it must hash to.
class LocalComponentFile {
  /// The name the file carries on disk and in the URL.
  final String fileName;
  final String url;
  final int bytes;
  final String sha256;

  const LocalComponentFile({
    required this.fileName,
    required this.url,
    required this.bytes,
    required this.sha256,
  });
}

/// The declaration of a component.
class LocalComponentSpec {
  final String id;
  final LocalComponentKind kind;
  final LocalComponentLabel label;
  final List<LocalComponentFile> files;
  final LocalComponentArchive archive;

  /// The program a runtime installs, searched by name after extraction.
  final String? executable;

  /// Files that must exist before the component counts as installed.
  final List<String> requiredFiles;

  /// Program names looked for on PATH (plus `~/.local/bin` and `~/bin`).
  final List<String> systemNames;

  /// Absolute probes, with `~` expanded; a file for a runtime, a folder for
  /// a model.
  final List<String> systemPaths;

  /// Files an older release wrote under the support folder — read, never
  /// deleted by this component.
  final List<String> legacyFiles;

  /// Folders an older release wrote under the support folder (or beside the
  /// executable), searched for [executable].
  final List<String> legacyDirectories;

  const LocalComponentSpec({
    required this.id,
    required this.kind,
    required this.label,
    required this.files,
    this.archive = LocalComponentArchive.none,
    this.executable,
    this.requiredFiles = const [],
    this.systemNames = const [],
    this.systemPaths = const [],
    this.legacyFiles = const [],
    this.legacyDirectories = const [],
  });

  bool get isRuntime => kind == LocalComponentKind.runtime;

  int get totalBytes => files.fold(0, (sum, file) => sum + file.bytes);
}

/// What one component is doing right now.
class LocalComponentState {
  final LocalComponentPhase phase;
  final int received;
  final int total;
  final int installedBytes;
  final String? message;

  /// A system copy exists, so the feature works even though the component
  /// itself is not downloaded.
  final bool systemAvailable;

  /// Only a downloaded copy may be deleted; a system copy is not ours.
  final bool canDelete;

  const LocalComponentState(
    this.phase, {
    this.received = 0,
    this.total = 0,
    this.installedBytes = 0,
    this.message,
    this.systemAvailable = false,
    this.canDelete = false,
  });

  bool get ready => phase == LocalComponentPhase.ready;

  bool get busy =>
      phase == LocalComponentPhase.checking ||
      phase == LocalComponentPhase.downloading ||
      phase == LocalComponentPhase.verifying;

  bool get usable => ready || systemAvailable;

  double? get progress => total > 0 ? received / total : null;

  LocalComponentState copyWith({
    LocalComponentPhase? phase,
    int? received,
    int? total,
    int? installedBytes,
    String? message,
    bool? systemAvailable,
    bool? canDelete,
  }) {
    return LocalComponentState(
      phase ?? this.phase,
      received: received ?? this.received,
      total: total ?? this.total,
      installedBytes: installedBytes ?? this.installedBytes,
      message: message ?? this.message,
      systemAvailable: systemAvailable ?? this.systemAvailable,
      canDelete: canDelete ?? this.canDelete,
    );
  }
}
