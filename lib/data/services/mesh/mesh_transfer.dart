import 'dart:async';
import 'dart:io';

import '../../../features/share/domain/share_item.dart';
import 'mesh_crypto.dart';
import 'mesh_messages.dart';
import 'mesh_peer.dart';
import 'mesh_protocol.dart';

/// 收一条完整内容的结论。`verified` 只有字节与 `contentId`、`sizeBytes`
/// 全都对上才是 true。
class MeshReceiveResult {
  const MeshReceiveResult({
    required this.path,
    required this.bytes,
    required this.verified,
    this.reason,
  });

  final String path;
  final int bytes;
  final bool verified;
  final String? reason;
}

/// 把本地文件按块喂给要它的对端。
///
/// 限速是刻意的：房间是交换，不是让人把别人的整张专辑拖走。
class MeshFileSender {
  MeshFileSender({
    required this.peer,
    required this.contentId,
    required this.file,
    this.blockBytes = MeshBlock.blockBytes,
    this.bytesPerSecond = defaultBytesPerSecond,
  });

  /// 单个对端的默认上限 2 MiB/s。
  static const int defaultBytesPerSecond = 2 * 1024 * 1024;

  final MeshPeer peer;
  final String contentId;
  final File file;
  final int blockBytes;
  final int bytesPerSecond;

  /// 按 [want] 发块，返回真正发出去的块数。
  Future<int> serve(MeshWant want) async {
    if (want.contentId != contentId) {
      throw ArgumentError('want asks for another content');
    }
    final length = await file.length();
    final total = (length + blockBytes - 1) ~/ blockBytes;
    if (total == 0) {
      return 0;
    }
    final raf = await file.open();
    var sent = 0;
    try {
      final last = (want.fromBlock + want.blockCount).clamp(0, total);
      for (var index = want.fromBlock; index < last; index++) {
        await raf.setPosition(index * blockBytes);
        final chunk = await raf.read(blockBytes);
        if (chunk.isEmpty) {
          break;
        }
        final ok = peer.send(
          MeshMessageType.block,
          MeshBlock.encodePayload(
            MeshBlock(
              contentId: contentId,
              index: index,
              total: total,
              data: chunk,
            ),
          ),
        );
        if (!ok) {
          break;
        }
        sent++;
        await _pace(chunk.length);
      }
    } finally {
      await raf.close();
    }
    return sent;
  }

  Future<void> _pace(int bytes) async {
    if (bytesPerSecond <= 0) {
      return;
    }
    final micros = (bytes * 1000000) ~/ bytesPerSecond;
    if (micros > 0) {
      await Future<void>.delayed(Duration(microseconds: micros));
    }
  }
}

/// 收一条内容：边收边落盘，收齐后重算 SHA-256 与条目核对。
///
/// 不信任对端在块里写的任何东西；唯一的判据是本地读回来的字节。
class MeshFileReceiver {
  MeshFileReceiver({
    required this.item,
    required this.destination,
    this.blockBytes = MeshBlock.blockBytes,
  });

  final ShareItem item;
  final String destination;
  final int blockBytes;

  RandomAccessFile? _raf;
  List<bool>? _received;
  int _receivedBytes = 0;
  bool _completed = false;

  /// 落盘队列：帧是一条接一条到的，但 `accept` 是异步的，不排队就会
  /// 两个块同时 setPosition —— RandomAccessFile 不允许并发的 async 操作。
  Future<void> _writeQueue = Future<void>.value();

  int get receivedBytes => _receivedBytes;

  bool get isComplete {
    final received = _received;
    return received != null && received.every((block) => block);
  }

  /// 预期总块数，按条目声明的大小算。
  int get totalBlocks =>
      item.sizeBytes == 0 ? 0 : (item.sizeBytes + blockBytes - 1) ~/ blockBytes;

  /// 收一块。任何对不上的块都抛错——坏了就让上层重来，不做部分信任。
  Future<void> accept(MeshBlock block) {
    final chained = _writeQueue.then((_) => _accept(block));
    _writeQueue = chained.catchError((Object _) {});
    return chained;
  }

  Future<void> _accept(MeshBlock block) async {
    if (block.contentId != item.contentId) {
      throw ArgumentError('block for another content');
    }
    if (block.total != totalBlocks) {
      throw ArgumentError('block count mismatch');
    }
    if (block.data.length > blockBytes) {
      throw ArgumentError('block too large');
    }
    final received = _received ??= List<bool>.filled(totalBlocks, false);
    if (block.index >= totalBlocks) {
      throw ArgumentError('block index out of range');
    }
    if (received[block.index]) {
      return;
    }
    final raf = _raf ??= await File(destination).open(mode: FileMode.write);
    await raf.setPosition(block.index * blockBytes);
    await raf.writeFrom(block.data);
    received[block.index] = true;
    _receivedBytes += block.data.length;
    _completed = isComplete;
  }

  /// 收齐后落盘校验；没收到块时返回未通过，不留下空文件。
  Future<MeshReceiveResult> finish() async {
    await _writeQueue;
    final raf = _raf;
    _raf = null;
    if (!_completed || raf == null) {
      await raf?.close();
      await _deleteQuietly();
      return MeshReceiveResult(
        path: destination,
        bytes: _receivedBytes,
        verified: false,
        reason: 'incomplete',
      );
    }
    await raf.flush();
    await raf.close();
    _raf = null;
    final file = File(destination);
    final length = await file.length();
    final actual = MeshCrypto.contentIdOf(await file.readAsBytes());
    if (length != item.sizeBytes || actual != item.contentId) {
      await _deleteQuietly();
      return MeshReceiveResult(
        path: destination,
        bytes: length,
        verified: false,
        reason: 'content mismatch',
      );
    }
    return MeshReceiveResult(
      path: destination,
      bytes: length,
      verified: true,
    );
  }

  /// 放弃这次接收，清掉半截文件。
  Future<void> abort() async {
    await _writeQueue;
    await _raf?.close();
    _raf = null;
    await _deleteQuietly();
  }

  Future<void> _deleteQuietly() async {
    final file = File(destination);
    if (await file.exists()) {
      try {
        await file.delete();
      } on FileSystemException {
        // 删不掉就算了：半截文件会在下次接收时被覆盖。
      }
    }
  }
}
