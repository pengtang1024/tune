import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:tune/data/services/update/version_manifest.dart';
import 'package:tune/utils/logger.dart';

/// One address, the validator it answered with and the list it published.
class VersionManifestCacheEntry {
  const VersionManifestCacheEntry({
    required this.url,
    required this.etag,
    required this.manifest,
  });

  /// The address the entry belongs to: a validator is never sent to another.
  final String url;
  final String? etag;
  final VersionManifest manifest;
}

/// The last list and validator of each address, kept across restarts.
///
/// A cold start would otherwise send an unconditional request for every
/// address and read both files in full. The entries live in the user data
/// directory — `<support>/update/`, not the component directory — keyed by
/// address, so a validator from one host is never presented to another.
///
/// A missing, corrupt or older file is dropped without an error: the next
/// request is unconditional and the file is written again when an answer
/// arrives. [VersionManifestCache.memory] keeps the same behaviour inside one
/// process without touching the disk, which is what the tests use.
class VersionManifestCache {
  VersionManifestCache({Future<Directory> Function()? supportDirectory})
    : _supportDirectory = supportDirectory ?? getApplicationSupportDirectory;

  /// No disk at all: validators last until the process ends.
  VersionManifestCache.memory() : _supportDirectory = null;

  /// Bumped when the shape below changes; an older file is discarded.
  static const schema = 1;

  static const fileName = 'version_manifest_cache.json';

  final Future<Directory> Function()? _supportDirectory;
  final Map<String, VersionManifestCacheEntry> _entries = {};
  Future<void>? _loading;

  /// Writes run one after another, so the last answer wins in the file.
  Future<void> _writes = Future<void>.value();

  /// The entry of [url], loaded from the disk on first use.
  Future<VersionManifestCacheEntry?> entryFor(String url) async {
    await _load();
    return _entries[url];
  }

  /// Remembers the answer of [url]. A `null` [etag] drops the old validator,
  /// so a host that stops sending one is not asked with a stale value.
  Future<void> put(String url, String? etag, VersionManifest manifest) async {
    await _load();
    _entries[url] = VersionManifestCacheEntry(
      url: url,
      etag: etag,
      manifest: manifest,
    );
    await _write();
  }

  Future<void> _load() => _loading ??= _readFile();

  Future<void> _readFile() async {
    try {
      final file = await _file();
      if (file == null || !await file.exists()) return;
      final data = jsonDecode(await file.readAsString());
      if (data is! Map || data['schema'] != schema) {
        Log.debug('更新清单缓存版本不匹配，丢弃');
        return;
      }
      final entries = data['entries'];
      if (entries is! Map) return;
      for (final item in entries.entries) {
        final url = item.key.toString();
        final raw = item.value;
        // An entry whose source does not match its key is not trusted: the
        // list and the validator must belong to the address they are for.
        if (raw is! Map || raw['url'] != url) continue;
        final manifest = VersionManifest.fromJson(raw['manifest']);
        if (manifest == null) continue;
        final etag = raw['etag']?.toString().trim() ?? '';
        _entries[url] = VersionManifestCacheEntry(
          url: url,
          etag: etag.isEmpty ? null : etag,
          manifest: manifest,
        );
      }
    } catch (error) {
      Log.debug('更新清单缓存无法读取，按无缓存处理: $error');
      _entries.clear();
    }
  }

  Future<void> _write() {
    final next = _writes.then((_) => _writeFile());
    _writes = next.catchError((Object _) {});
    return next;
  }

  Future<void> _writeFile() async {
    try {
      final file = await _file();
      if (file == null) return;
      await file.parent.create(recursive: true);
      await file.writeAsString(
        jsonEncode({
          'schema': schema,
          'entries': {
            for (final entry in _entries.entries)
              entry.key: {
                'url': entry.value.url,
                'etag': entry.value.etag,
                'manifest': entry.value.manifest.toJson(),
              },
          },
        }),
        flush: true,
      );
    } catch (error) {
      Log.debug('更新清单缓存无法写入: $error');
    }
  }

  Future<File?> _file() async {
    final resolve = _supportDirectory;
    if (resolve == null) return null;
    final base = await resolve();
    return File(path.join(base.path, 'update', fileName));
  }
}
