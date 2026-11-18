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

2. `lib/src/writers/flac_writer.dart` `_buildVorbisComments`：补写 `PRODUCER`（Vorbis
   comment 的标准键，读侧解析进 `metadata.producer`，上游写侧漏了它，于是每次重写元数据
   都会静默丢掉这个键）；并把 `metadata.unknowns` 里的定制键逐条写回（上游只写固定字段，
   AI 标识的 `AI_GENERATED` / `GENERATOR` / `CONTENT_ID` 这类键写完即丢）。已由固定字段
   写过的键名跳过，避免同一个键出现两份。
3. `lib/src/writers/id3v4_writer.dart` `_writeFrames`：把 `metadata.customMetadata` 写回
   成 TXXX 帧（描述=键名）。上游写侧从不输出 TXXX，任何自定义键都会在重写标签时被丢弃。
   形如 4 字节大写帧 ID 的键跳过——那是读侧从未知二进制帧塞进来的，伪装成 TXXX 会篡改
   原帧语义。上游没有写过 customMetadata，本补丁只可能新增、不可能改变既有行为。
4. `lib/src/parsers/tags/id3v2.dart` `TXXXFrame`：非 UTF-16 分支读完描述符后跳过收尾的
   分隔 NUL；终止空字节按编码分别判定（UTF-16 两个 0、其它单个 0）；各循环补边界检查；
   `rest` 改用 `sublist` 以尊重切片自身的 `offsetInBytes`。不修则本包读回的 TXXX 值带
   前导/尾部 NUL，与 ffprobe 口径不一致，按 `==` 比较的合规校验会把好文件判成没标识。
5. `lib/audio_metadata_reader.dart`：把 `ParserTag` 加进 `src/metadata/base.dart` 的导出。
   `readAllMetadata` 的返回类型就是它，却不在包外可见，写侧只能拿到 `Object`，等于强制
   调用方向下转型。连带删掉 `lib/src/parser.dart`、`lib/src/writer.dart` 里那两行此刻多余
   的 `src/metadata/base.dart` import（公开库已经覆盖，留着会被 `unnecessary_import` 拦）。

## 升级步骤

1. 复制新版包覆盖本目录（保留本文件与 LICENSE）。
2. 重放上面的补丁。
3. 回归 `flutter test`（SongCreator / 扫描相关用例）与一次真实库扫描。
