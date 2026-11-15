import 'dart:convert';

/// One platform archive of `version.json` (docs/update-cdn.md §3).
class VersionManifestAsset {
  const VersionManifestAsset({
    required this.url,
    required this.size,
    required this.sha256,
  });

  final String url;
  final int size;
  final String sha256;

  /// Reads one archive entry; an entry without a URL or a digest is skipped.
  static VersionManifestAsset? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final url = raw['url']?.toString().trim() ?? '';
    final sha256 = raw['sha256']?.toString().trim().toLowerCase() ?? '';
    if (url.isEmpty || sha256.isEmpty) return null;
    final size = raw['size'];
    return VersionManifestAsset(
      url: url,
      size: size is num ? size.toInt() : 0,
      sha256: sha256,
    );
  }

  bool sameAs(VersionManifestAsset other) =>
      url == other.url && size == other.size && sha256 == other.sha256;

  Map<String, dynamic> toJson() => {
    'url': url,
    'size': size,
    'sha256': sha256,
  };
}

/// The static list a release publishes, read instead of the GitHub API.
///
/// It lives at the repository root and is served by the CDN, so a check no
/// longer spends the sixty anonymous requests of the GitHub API. The fields
/// are the ones the client acts on: which version, what changed, and which
/// archive to download with which digest.
class VersionManifest {
  const VersionManifest({
    required this.version,
    required this.build,
    this.schema = currentSchema,
    this.releasedAt = '',
    this.releaseUrl = '',
    this.notes = '',
    this.minSupported = '',
    this.assets = const {},
  });

  /// The schema this build understands. A newer one is read leniently: the
  /// fields the client knows are used and the rest is ignored.
  static const int currentSchema = 1;

  final int schema;
  final String version;
  final int build;
  final String releasedAt;
  final String releaseUrl;
  final String notes;
  final String minSupported;

  /// Archives keyed by platform, `linux-x64` first (see [platformKey]).
  final Map<String, VersionManifestAsset> assets;

  /// The archive of [platform] (`linux` → `linux-x64`).
  VersionManifestAsset? assetFor(String platform) =>
      assets[platformKey(platform)];

  /// Reads the body of `version.json`; `null` when it is not a manifest.
  static VersionManifest? parse(String body) {
    final Object? data;
    try {
      data = jsonDecode(body);
    } on FormatException {
      return null;
    }
    return fromJson(data);
  }

  static VersionManifest? fromJson(Object? data) {
    if (data is! Map) return null;
    final version = _text(data['version']).replaceFirst(RegExp(r'^v'), '');
    if (version.isEmpty) return null;

    final assets = <String, VersionManifestAsset>{};
    final rawAssets = data['assets'];
    if (rawAssets is Map) {
      for (final entry in rawAssets.entries) {
        final asset = VersionManifestAsset.fromJson(entry.value);
        if (asset == null) continue;
        assets[entry.key.toString()] = asset;
      }
    }

    return VersionManifest(
      schema: _int(data['schema']),
      version: version,
      build: _int(data['build']),
      releasedAt: _text(data['released_at']),
      releaseUrl: _text(data['release_url']),
      notes: _text(data['notes']),
      minSupported: _text(data['min_supported']),
      assets: assets,
    );
  }

  /// Whether two sources published the same release (docs/update-cdn.md §7).
  ///
  /// A CDN copy that disagrees with the raw copy is not trusted: the two are
  /// compared on everything the client acts on, not on the wording of the
  /// notes or the time of the release.
  bool sameAs(VersionManifest other) {
    if (version != other.version || build != other.build) return false;
    if (assets.length != other.assets.length) return false;
    for (final entry in assets.entries) {
      final theirs = other.assets[entry.key];
      if (theirs == null || !entry.value.sameAs(theirs)) return false;
    }
    return true;
  }

  /// Writes the fields [fromJson] reads, so the cached copy round-trips.
  Map<String, dynamic> toJson() => {
    'schema': schema,
    'version': version,
    'build': build,
    'released_at': releasedAt,
    'release_url': releaseUrl,
    'notes': notes,
    'min_supported': minSupported,
    'assets': {
      for (final entry in assets.entries) entry.key: entry.value.toJson(),
    },
  };

  /// The platform key of the manifest, `linux` → `linux-x64`.
  static String platformKey(String platform) => switch (platform.toLowerCase()) {
    'linux' => 'linux-x64',
    'windows' => 'windows-x64',
    'android' => 'android-arm64',
    final other => other,
  };

  static String _text(Object? value) => value?.toString().trim() ?? '';

  static int _int(Object? value) => value is num ? value.toInt() : 0;
}
