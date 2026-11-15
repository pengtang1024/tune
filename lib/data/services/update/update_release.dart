/// One release the update source publishes.
class UpdateRelease {
  /// The version without the `v` of the tag.
  final String version;

  /// The build number of the version, `0` when the source names none.
  final int build;

  /// What changed in the release, in the words of its author.
  final String notes;

  /// The file of the release that belongs to this machine, if any.
  final UpdateAsset? asset;

  const UpdateRelease({
    required this.version,
    this.build = 0,
    this.notes = '',
    this.asset,
  });
}

/// One downloadable file of a release.
class UpdateAsset {
  final String name;
  final String url;
  final int size;

  /// The digest the list published; empty when the source names none.
  final String sha256;

  const UpdateAsset({
    required this.name,
    required this.url,
    this.size = 0,
    this.sha256 = '',
  });
}
