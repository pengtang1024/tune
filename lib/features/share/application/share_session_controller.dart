import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tune/data/services/components/local_component_registry.dart';
import 'package:tune/data/services/components/local_components.dart';
import 'package:tune/data/services/mesh/mesh_crypto.dart';
import 'package:tune/data/services/mesh/mesh_identity.dart';
import 'package:tune/data/services/mesh/room_invite.dart';
import 'package:tune/data/services/providers/library_paths_provider.dart';
import 'package:tune/features/library/application/library_controller.dart';
import 'package:tune/features/share/application/share_session.dart';
import 'package:tune/features/share/data/share_inbox.dart';
import 'package:tune/features/share/data/share_ledger.dart';
import 'package:tune/features/share/data/share_migration.dart';
import 'package:tune/features/share/data/acoustid_lookup.dart';
import 'package:tune/features/share/data/share_blocklist.dart';
import 'package:tune/features/share/data/share_config.dart';
import 'package:tune/features/share/data/share_reports.dart';
import 'package:tune/features/share/data/share_store.dart';
import 'package:tune/features/share/domain/share_declaration.dart';
import 'package:tune/features/share/domain/share_item.dart';
import 'package:tune/features/share/domain/share_lookup_status.dart';
import 'package:tune/features/share/domain/share_provenance.dart';
import 'package:tune/features/share/domain/share_session_state.dart';

/// 分享会话的界面侧入口。
///
/// 底层（发现、传输、校验）都在 `lib/data/services/mesh/`，这里只做三件事：
/// 拿身份、建/进房间、把文件与声明接进会话。状态一律是 [ShareSession] 推上来的，
/// 本类不另存一份，否则两边会各说各话。
final shareSessionProvider =
    AsyncNotifierProvider<ShareSessionController, ShareSessionState>(
      ShareSessionController.new,
    );

class ShareSessionController extends AsyncNotifier<ShareSessionState> {
  ShareSession? _session;
  StreamSubscription<ShareSessionState>? _subscription;
  MeshIdentity? _identity;
  ShareStore? _store;
  ShareInbox? _inbox;
  ShareLedger? _ledger;
  ShareReports? _reports;
  ShareBlocklist? _blocklist;
  AcoustIdLookup? _lookup;
  ShareConfig? _config;

  @override
  Future<ShareSessionState> build() async {
    ref.onDispose(() {
      unawaited(_subscription?.cancel());
      unawaited(_session?.close());
    });
    return ShareSessionState.idle;
  }

  /// 本机身份，落在支持目录里，第一次用时生成。
  Future<MeshIdentity> _loadIdentity() async {
    final cached = _identity;
    if (cached != null) {
      return cached;
    }
    final dir = Directory('${(await getApplicationSupportDirectory()).path}/share');
    await dir.create(recursive: true);
    final identity = await MeshIdentity.loadOrCreate(
      File('${dir.path}/identity.json'),
    );
    _identity = identity;
    return identity;
  }

  /// 分享的元数据跟曲库同一个库（`<support>/library/library.db`），
  /// 第一次打开时把 M0 的 JSON 快照搬进来。
  Future<ShareStore> _loadStore() async {
    final cached = _store;
    if (cached != null) {
      return cached;
    }
    final base = await getApplicationSupportDirectory();
    final libraryDir = Directory('${base.path}/library');
    await libraryDir.create(recursive: true);
    final store = ShareStore.open(File('${libraryDir.path}/library.db'));
    await importLegacyShareJson(store, Directory('${base.path}/share'));
    _store = store;
    return store;
  }

  Future<ShareInbox> _loadInbox() async {
    final cached = _inbox;
    if (cached != null) {
      return cached;
    }
    final dir = Directory('${(await getApplicationSupportDirectory()).path}/share/inbox');
    final inbox = ShareInbox(await _loadStore(), dir);
    _inbox = inbox;
    return inbox;
  }

  /// 本机生成台账。声明为「AI 生成」的条目要先进台账，闸门才认。
  Future<ShareLedger> _loadLedger() async {
    final cached = _ledger;
    if (cached != null) {
      return cached;
    }
    final ledger = ShareLedger(await _loadStore());
    _ledger = ledger;
    return ledger;
  }

  /// 举报台账：只在本机留痕，不外发。
  Future<ShareReports> _loadReports() async {
    final cached = _reports;
    if (cached != null) {
      return cached;
    }
    final reports = ShareReports(await _loadStore());
    _reports = reports;
    return reports;
  }

  /// AcoustID 查重：要 `fpcalc` 与 client key 两样都齐。
  ///
  /// 之所以还没放进设置页：`fpcalc` 桌面三端都还没随包分发（见
  /// docs/ai-music-sharing.md §13）。现在只认环境变量 `TUNE_ACOUSTID_CLIENT`，
  /// 没配就是「没接」，闸门不会把它当成清白证明。
  Future<AcoustIdLookup?> _loadLookup() async {
    final cached = _lookup;
    if (cached != null) {
      return cached;
    }
    final clientKey = await _clientKey();
    if (clientKey.isEmpty) {
      return null;
    }
    // 先看系统装没装，再看组件目录（docs/local-components.md §3 的顺序）。
    final components = LocalComponents(
      supportDirectory: await getApplicationSupportDirectory(),
    );
    final fpcalc =
        await components.executable(LocalComponentRegistry.fingerprintRuntime) ??
        AcoustIdLookup.findFpcalc();
    if (fpcalc == null) {
      return null;
    }
    final lookup = AcoustIdLookup(clientKey: clientKey, fpcalc: fpcalc);
    _lookup = lookup;
    return lookup;
  }

  Future<ShareConfig> _loadConfig() async {
    final cached = _config;
    if (cached != null) {
      return cached;
    }
    final file = File('${(await getApplicationSupportDirectory()).path}/share/config.json');
    final config = ShareConfig(file);
    _config = config;
    return config;
  }

  /// 设置页填的 key 优先，其次才认环境变量（老装法不用改）。
  Future<String> _clientKey() async {
    final stored = await (await _loadConfig()).acoustIdKey();
    if (stored.isNotEmpty) {
      return stored;
    }
    return (Platform.environment['TUNE_ACOUSTID_CLIENT'] ?? '').trim();
  }

  /// 查重现在能不能跑，以及卡在哪一步。
  Future<ShareLookupStatus> lookupStatus() async {
    final hasKey = (await _clientKey()).isNotEmpty;
    final components = LocalComponents(
      supportDirectory: await getApplicationSupportDirectory(),
    );
    final fpcalc =
        await components.executable(LocalComponentRegistry.fingerprintRuntime) ??
        AcoustIdLookup.findFpcalc();
    if (fpcalc == null) {
      return hasKey ? ShareLookupStatus.missingFpcalc : ShareLookupStatus.missingKey;
    }
    return hasKey ? ShareLookupStatus.ready : ShareLookupStatus.missingKey;
  }

  /// 写进 `<support>/share/config.json`；空串表示清掉。写完把查重实例作废，
  /// 下一次开会话按新 key 重建。
  Future<void> saveAcoustIdKey(String key) async {
    await (await _loadConfig()).setAcoustIdKey(key);
    _lookup = null;
  }

  Future<ShareBlocklist> _loadBlocklist() async {
    final cached = _blocklist;
    if (cached != null) {
      return cached;
    }
    final blocklist = ShareBlocklist(await _loadStore());
    _blocklist = blocklist;
    return blocklist;
  }

  /// 开房间。[reachableAddress] 填了就把这个地址写进邀请码（跨网时填隧道域名
  /// 或公网地址），不填就带局域网地址。
  Future<void> hostRoom() async {
    if (_session != null) {
      return;
    }
    state = const AsyncLoading();
    try {
      final session = await ShareSession.host(
        identity: await _loadIdentity(),
        displayName: _localName(),
        inbox: await _loadInbox(),
        ledger: await _loadLedger(),
        reports: await _loadReports(),
        blocklist: await _loadBlocklist(),
        recordingLookup: await _recordingLookup(),
      );
      _attach(session);
    } catch (error) {
      state = AsyncError(error, StackTrace.current);
    }
  }

  /// 邀请码认不出就走正常错误路径，不要半开着房间。
  Future<void> joinRoom(String inviteText) async {
    if (_session != null) {
      return;
    }
    final invite = RoomInvite.tryParse(inviteText);
    if (invite == null) {
      throw const FormatException('invite');
    }
    state = const AsyncLoading();
    try {
      final session = await ShareSession.join(
        invite: invite,
        identity: await _loadIdentity(),
        displayName: _localName(),
        inbox: await _loadInbox(),
        ledger: await _loadLedger(),
        reports: await _loadReports(),
        blocklist: await _loadBlocklist(),
        recordingLookup: await _recordingLookup(),
      );
      _attach(session);
    } catch (error) {
      state = AsyncError(error, StackTrace.current);
    }
  }

  void _attach(ShareSession session) {
    _session = session;
    _subscription = session.states.listen((next) => state = AsyncData(next));
    state = AsyncData(session.state);
  }

  /// 把本地文件加进「我要分享的」，缘起由界面问用户要。
  ///
  /// 返回认不出的原因，成功返回 null。
  Future<String?> addLocalFile(String path, ShareProvenance provenance) async {
    final session = _session;
    if (session == null) {
      return 'closed';
    }
    final file = File(path);
    if (!await file.exists()) {
      return 'missing';
    }
    final contentId = await _contentIdOf(file);
    final declaration = ShareDeclaration(
      provenance: provenance,
      declaredAt: DateTime.now(),
    );
    final item = declaration.toItem(
      contentId: contentId,
      name: _basename(path),
      sizeBytes: await file.length(),
    );
    if (provenance.isGenerated) {
      // 本机声明为生成：先记台账，再让它进房间。
      await (await _loadLedger()).add(contentId);
    }
    final added = await session.addLocalItem(item, file);
    return added ? null : 'rejected';
  }

  Future<void> receive(ShareItem item) async {
    await _session?.request(item);
  }

  /// 收件箱里的文件复制进音乐库目录，再让扫描器收一遍。
  Future<String?> importToLibrary(ShareInboxEntry entry) async {
    final source = File(entry.path);
    if (!await source.exists()) {
      return 'missing';
    }
    final root = ref.read(libraryPathsProvider).root();
    await root.create(recursive: true);
    // 名字来自对端，可能带路径分隔符：只留最后一段，别让它写出音乐库去。
    final name = _safeName(entry.item.name);
    var destination = File('${root.path}/$name');
    var attempt = 1;
    while (await destination.exists()) {
      destination = File('${root.path}/$name ($attempt)');
      attempt++;
    }
    await source.copy(destination.path);
    await ref
        .read(libraryControllerProvider.notifier)
        .scan(<String>[destination.path], auto: true);
    return null;
  }

  /// 本人下架：从房间和自己的清单里拿掉，房里的人会被通知删掉那份。
  void revokeLocal(String contentId) {
    _session?.revoke(contentId);
  }

  /// 举报并下架：本机删掉收件、记一条留痕。
  Future<void> reportEntry(ShareInboxEntry entry, {String reason = 'unknown'}) async {
    final session = _session;
    if (session == null) {
      return;
    }
    await session.report(entry, reason: reason);
  }

  /// 把查重包成会话要的形状；没配就返回 null（闸门里那一格是「没查」）。
  Future<ShareRecordingLookup?> _recordingLookup() async {
    final lookup = await _loadLookup();
    if (lookup == null) {
      return null;
    }
    return (item, file) => lookup.match(file);
  }

  Future<void> closeRoom() async {
    final session = _session;
    _session = null;
    await _subscription?.cancel();
    _subscription = null;
    await session?.close();
    state = const AsyncData(ShareSessionState.idle);
  }

  static String _localName() {
    final name = Platform.localHostname;
    return name.isEmpty ? 'Tune' : name;
  }

  /// 只保留文件名的最后一段，并挡住 `..`。
  static String _safeName(String name) {
    final last = name
        .replaceAll('\\', '/')
        .split('/')
        .where((part) => part.isNotEmpty && part != '.' && part != '..')
        .lastOrNull;
    return last ?? 'shared-audio';
  }

  static String _basename(String path) {
    final separator = path.lastIndexOf(Platform.pathSeparator);
    return separator < 0 ? path : path.substring(separator + 1);
  }

  static Future<String> _contentIdOf(File file) {
    return MeshCrypto.contentIdOfFile(file);
  }
}

/// 查重状态给界面看的那份。`ShareSession` 自己不看它——闸门只认「查没查」。
final shareLookupStatusProvider = FutureProvider<ShareLookupStatus>(
  (ref) => ref.watch(shareSessionProvider.notifier).lookupStatus(),
);
