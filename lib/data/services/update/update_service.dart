import 'dart:io';

import 'package:dio/dio.dart';
import 'package:tune/data/services/update/update_release.dart';
import 'package:tune/utils/logger.dart';

/// Finds, downloads and installs a newer release of the app.
///
/// The releases live on the project page; every release carries one archive
/// per platform. A check reads the latest release, a download writes the
/// archive of this machine, and the install replaces the bundle the app
/// runs from. The app then asks the reader to restart: the running process
/// still holds the files it started with.
class UpdateService {
  /// The repository the releases live in.
  static const _repo = 'pengtang1024/tune';

  static const _apiHost = 'https://api.github.com';

  final Dio _dio;

  /// The release read the last time, and when.
  UpdateRelease? _cached;
  DateTime? _cachedAt;

  /// How long a check may reuse the last answer.
  static const _cacheFor = Duration(minutes: 10);

  UpdateService({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 20),
              headers: const {'Accept': 'application/vnd.github+json'},
            ),
          );

  /// The newest release, or `null` when the project published none.
  Future<UpdateRelease?> latest() async {
    final cachedAt = _cachedAt;
    if (cachedAt != null && DateTime.now().difference(cachedAt) < _cacheFor) {
      return _cached;
    }
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '$_apiHost/repos/$_repo/releases/latest',
        options: Options(
          // A project without a release answers with 404; that is an answer,
          // not a failure of the network.
          validateStatus: (status) => status != null && status < 500,
        ),
      );
      if (response.statusCode == 404) {
        _cached = null;
        _cachedAt = DateTime.now();
        return null;
      }
      final release = parseRelease(response.data);
      _cached = release;
      _cachedAt = DateTime.now();
      return release;
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  /// Reads one release of the answer of the project page.
  static UpdateRelease? parseRelease(Map<String, dynamic>? data) {
    if (data == null) return null;

    final tag = data['tag_name']?.toString().trim() ?? '';
    final version = tag.replaceFirst(RegExp(r'^v'), '');
    if (version.isEmpty) return null;

    final rawAssets = data['assets'];
    final assets = <UpdateAsset>[];
    if (rawAssets is List) {
      for (final raw in rawAssets) {
        if (raw is! Map) continue;
        final name = raw['name']?.toString().trim() ?? '';
        final url = raw['browser_download_url']?.toString().trim() ?? '';
        if (name.isEmpty || url.isEmpty) continue;
        assets.add(
          UpdateAsset(
            name: name,
            url: url,
            size: (raw['size'] is num) ? (raw['size'] as num).toInt() : 0,
          ),
        );
      }
    }

    return UpdateRelease(
      version: version,
      notes: data['body']?.toString() ?? '',
      asset: assetFor(assets, platform: Platform.operatingSystem),
    );
  }

  /// Whether [latest] is newer than [current].
  ///
  /// The versions are compared part by part, so `1.10.0` is newer than
  /// `1.9.0` while a plain string comparison would say the opposite.
  static bool isNewer(String current, String latest) {
    final left = _parts(current);
    final right = _parts(latest);
    final length = left.length > right.length ? left.length : right.length;
    for (var index = 0; index < length; index++) {
      final a = index < left.length ? left[index] : 0;
      final b = index < right.length ? right[index] : 0;
      if (b > a) return true;
      if (b < a) return false;
    }
    return false;
  }

  /// The archive of a release that belongs to [platform].
  ///
  /// The release names its archives after the platform they run on, so the
  /// check never downloads a Windows build on a Linux machine.
  static UpdateAsset? assetFor(
    List<UpdateAsset> assets, {
    required String platform,
  }) {
    for (final asset in assets) {
      if (asset.name.toLowerCase().contains(platform.toLowerCase())) {
        return asset;
      }
    }
    return null;
  }

  /// Writes the file of [asset] to [destination].
  Future<void> download(
    UpdateAsset asset,
    String destination, {
    void Function(double progress)? onProgress,
  }) async {
    await _dio.download(
      asset.url,
      destination,
      onReceiveProgress: (received, total) {
        if (total <= 0) return;
        onProgress?.call((received / total).clamp(0, 1));
      },
    );
  }

  /// Replaces the bundle the app runs from with the archive.
  ///
  /// The archive is unpacked beside the running bundle and then swapped in;
  /// the running process keeps its own copy and asks for a restart.
  Future<void> installLinux(String archive, String targetDirectory) async {
    final parent = Directory(targetDirectory).parent;
    final staging = '${parent.path}/.tune-update';
    final backup = '${parent.path}/.tune-previous';

    await _delete(staging);
    await _delete(backup);
    await Directory(staging).create(recursive: true);

    final unpacked = await Process.run('tar', ['-xzf', archive, '-C', staging]);
    if (unpacked.exitCode != 0) {
      throw ProcessException(
        'tar',
        ['-xzf', archive, '-C', staging],
        '${unpacked.stderr}',
        unpacked.exitCode,
      );
    }

    final bundle = _bundleDirectory(staging);
    if (bundle == null) {
      throw const FormatException('the update archive holds no bundle');
    }

    await Directory(targetDirectory).rename(backup);
    try {
      await bundle.rename(targetDirectory);
    } catch (error) {
      // The old bundle comes back when the new one cannot take its place.
      await Directory(backup).rename(targetDirectory);
      rethrow;
    }
    // The previous bundle is kept: a build that starts and then fails can be
    // restored by hand. The next update removes the old copy first.
    await _delete(staging);
  }

  /// Starts the new build and lets the old process end.
  Future<void> restart() async {
    final executable = Platform.resolvedExecutable;
    await Process.start(executable, const [], mode: ProcessStartMode.detached);
    exit(0);
  }

  /// The bundle inside the unpacked archive.
  ///
  /// A release packs the bundle itself, but a folder has been added around
  /// it more than once; both shapes are read.
  static Directory? _bundleDirectory(String staging) {
    final root = Directory(staging);
    final direct = Directory('${root.path}/lib');
    if (direct.existsSync()) return root;

    for (final entity in root.listSync()) {
      if (entity is! Directory) continue;
      if (Directory('${entity.path}/lib').existsSync()) return entity;
    }
    return null;
  }

  static Future<void> _delete(String path) async {
    final directory = Directory(path);
    if (directory.existsSync()) {
      try {
        await directory.delete(recursive: true);
      } catch (error) {
        Log.error('清理更新目录失败: $error');
      }
    }
  }

  static List<int> _parts(String version) {
    final cleaned = version
        .trim()
        .replaceFirst(RegExp(r'^v'), '')
        .split('+')
        .first;
    return [
      for (final part in cleaned.split('.'))
        int.tryParse(RegExp(r'^\d+').stringMatch(part) ?? '') ?? 0,
    ];
  }
}
