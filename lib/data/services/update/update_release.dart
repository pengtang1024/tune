/// One release the update source publishes.
class UpdateRelease {
  /// The version without the `v` of the tag.
  final String version;

  /// What changed in the release, in the words of its author.
  final String notes;

  /// The file of the release that belongs to this machine, if any.
  final UpdateAsset? asset;

  const UpdateRelease({required this.version, this.notes = '', this.asset});
}

/// One downloadable file of a release.
class UpdateAsset {
  final String name;
  final String url;
  final int size;

  const UpdateAsset({required this.name, required this.url, this.size = 0});
}
