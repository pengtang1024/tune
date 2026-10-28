# Vendored：audio_metadata_reader 1.8.1

- 来源：pub.flutter-io.cn 镜像的 `audio_metadata_reader 1.8.1`，MIT 许可（见
  [LICENSE](LICENSE)，Copyright (c) 2023 Clément Béal）。除下述补丁外未做改动。
- 随包的 `test/` 保留作升级对照；`example/`、`tool/`、`docs/` 未复制。

## 为什么要 vendor

上游 `Buffer.read(size)` 按声明大小无条件 `Uint8List(size)`，不做文件边界校验。
损坏的 ID3v2 帧头（真实案例：`2014-02-12 Bigwords.mp3` 的 `00COM` 帧声明
1,291,845,632 字节，文件本身只有 4,146,688 字节）会让一次标签解析分配 ~1.2 GB
的零填充缓冲并解码成常驻大字符串，扫描库时把 RSS 抬到 1.5 GB+。FLAC
（`containers/flac.dart` 的 `buffer.read(block.length)`）与 MP4
（`containers/mp4.dart` 的 `buffer.read(box.payloadSize)`）共用同一无界读，
属于同一类 bug；在 `Buffer.read` 一处收界即修整类。上游 1.8.1（截至
2026-10 为最新版）无修复，已在此打补丁并走 `dependency_overrides` 接入。

## 补丁清单（升级时需在新版本上重放）

1. `lib/src/utils/buffer.dart` `read(int size)`：读取前把 `size` 收到
   `remainingBytes`（文件真实剩余）内，负数取 0；非正数的请求直接返回空
   列表（越过文件尾的 `skip` 会让 `readAtMost` 传进负数）。只影响分配大小
   与越界请求，不改变各解析器的游标推进，`readAtMost` 语义不变。

## 升级步骤

1. 复制新版包覆盖本目录（保留本文件与 LICENSE）。
2. 重放上面的补丁。
3. 回归 `flutter test`（SongCreator / 扫描相关用例）与一次真实库扫描。
