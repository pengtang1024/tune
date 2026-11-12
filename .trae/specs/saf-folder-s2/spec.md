# SAF「指定文件夹」S2：智能词稿写入选中目录

> 依据：`docs/android.md` §5（S1 已实施），用户 2026-11-12 的指令：用 `SafDocumentWriter.canWrite(song)`
> 判断，走 `cn.iouf.tune/saf` 通道写入，不给 SAF 目录套 `File` 路径；与桌面端不同的写入失败行为写进
> `docs/android.md`；在模拟器上验证一次写入落点；不 push。

## 结论先行

S2 只做一件事：智能歌词的 `<歌名>.smart.lrc` 能落到用户选中的 SAF 目录里，且落点由运行期的
`canWrite(song)` 判定。批量 / 自动补词、SAF 读回词稿、SAF 音频复制都不在本步，原因写在「不做的事」。

## 范围

### 做

1. **原生写入**（`android/app/src/main/java/cn/iouf/tune/MainActivity.java`）
   - `cn.iouf.tune/saf` 增加 `writeSheet`：参数 `treeUri`、`songUri`、`name`、`content`。
   - 父目录由 `DocumentsContract.getDocumentId(songUri)` 得到；用
     `buildChildDocumentsUriUsingTree(tree, parentId)` 查同名子文档。
   - 同名存在则覆盖（`openOutputStream(uri, "wt")`），不存在则 `createDocument(..., "text/plain", name)`；
     系统 provider 会按 MIME 给 `text/plain` 文档补扩展名（实测 `.lrc` → `.lrc.txt`），
     所以新建后核对 display name，不符即 `renameDocument` 回 `name`（模拟器首轮验证暴露）。
   - UTF-8 写入；**新建后写入失败时删除刚建的文档**，不留半个词稿（与桌面一致）。
   - 返回 `{uri, replaced}`；`SecurityException` → `permission_lost`，其它 → `saf_failed`。
2. **Dart 通道**（`lib/data/services/impl/saf_method_channel.dart`）
   - 新增 `SafWrittenSheet(uri, replaced)` 与 `writeSheet({treeUri, songUri, name, content})`。
3. **写入器**（`lib/data/services/impl/saf_document_writer.dart`）
   - 新增 `writeSmartLyrics(Song song, String lyrics)`：名字取
     `<safeFileName(song.title)>.smart.lrc`；先 `canWrite(song)`，不可写抛
     `SheetWriteException(permissionLost: true)`，不调通道。
   - 通道 `permission_lost` → 同一异常；其它平台错误 → `SheetWriteException`（非 permissionLost）。
4. **落点契约**（`lib/data/services/library/library_paths.dart`、`impl/library_paths_io.dart`）
   - `LibraryPaths` 增加**有默认实现**的 `Future<bool> canWriteSheet(Song song) async => true;`
     （有文件系统的实现默认成立，测试里的假实现无需改动）。
   - `FileLibraryPaths` 覆盖：SAF 树内曲目问 `SafDocumentWriter.canWrite`；其它曲目回落到
     `AppCapabilities.current.lyricsSheetBesideAudio`。
   - `FileLibraryPaths.saveSmartLyrics`：SAF 树内曲目转给 `SafDocumentWriter.writeSmartLyrics`，
     不构造任何 `File`；其它曲目保持原文件写入。
   - `SheetWriteException` 定义在 `library_paths.dart`（接口契约），带 `permissionLost`。
5. **单曲判断**（`lib/data/services/smart_lyrics/smart_lyrics_service.dart`）
   - `generate` 的平台开关换成 `await paths.canWriteSheet(song)`；无落点 → `unsupported`，
     日志改成「词稿无处可写 …（Android 请选一个可写的音乐库文件夹）」。
   - `_save` 区分：`SheetWriteException.permissionLost` → 记一条 info「SAF 目录授权已收回，请重新选择
     音乐库文件夹」并返回 `unsupported`；其它写入错误仍是 `uploadFailed`。
6. **测试**
   - `test/services/saf_document_writer_test.dart`：成功写入的参数与名字、不可写不调通道、
     `permission_lost` 映射、树外曲目。
   - `test/services/library_paths_test.dart`：SAF 行 `saveSmartLyrics` 只走通道、不落 `File`；
     `canWriteSheet` 在 SAF 行/MediaStore 行/桌面三种情况下的答案。
   - `test/services/smart_lyrics_service_test.dart`：`canWriteSheet` 为 false 时 `unsupported`
     且不请求通道；`permissionLost` 写入失败映射为 `unsupported`。
   - 新增 `integration_test/saf_sheet_write_test.dart`（`integration_test` 仅 dev 依赖）：在模拟器上
     用已持久化的 tree 取一首 SAF 曲目，调 `writeSmartLyrics`。
7. **文档**（`docs/android.md` §5）
   - 状态改为「S2 已实施」；§5.3/§5.4 的类与步骤对齐代码。
   - 新增「写入失败与桌面端的差异」：无落点、授权收回、半成品清理、读回限制、批量仍停用、音频仍未复制。
8. **验证**
   - `flutter analyze`、`flutter test`。
   - `JAVA_HOME=~/.jdks/ms-21.0.12.1 flutter build apk --debug`。
   - 模拟器：装 APK → 确认 `TuneSaf` tree 仍持久 → 跑集成测试 → `adb shell ls/cat`
     确认 `/sdcard/Music/TuneSaf/<歌名>.smart.lrc` 内容。
   - 分阶段提交（原生通道 / Dart 写入与落点 / 文档），不夹带无关文件，不 push。

### 不做（并写进文档）

- **SAF 读回词稿**：`readSmartLyrics` 仍只读文件系统；写进树的词稿暂不在歌词面板显示。
- **SAF 音频复制**：`content://` 曲目没有 `localFile`，`generate` 在取音频处就返回 `noAudio`；
  智能歌词在 SAF 曲目上要真正产出词稿，需要把音频复制到应用可读的临时文件（另一步）。
- **批量 / 自动补词在 Android 的开关**：仍按平台能力整体停用；本步只接单曲面板生成。
- 封面写入、S3/S4 的授权收回/同名冲突全链路测试。

## 与桌面端不同的行为（文档口径）

| 场景 | 桌面 | Android |
| --- | --- | --- |
| 落点 | 音频旁的文件系统 | 选中 SAF 树的父文档下 |
| 无落点 | 不会发生 | MediaStore 行 / 未选目录：`unsupported`，零请求 |
| 授权收回 | 无此概念 | `canWrite` 为 false → `unsupported` + 一条 info，不重试 |
| 写到一半失败 | 磁盘错误 → `uploadFailed` | 原生删掉刚建的文档，再 `uploadFailed` |
| 读回 | 直接读文件 | 本步不读，面板看不到 |

## 验收

- 单测覆盖上表与命名；`flutter analyze` 无问题、`flutter test` 全绿。
- 模拟器证据：集成测试通过，且 `adb shell cat` 能看到写入的 `.smart.lrc` 内容。
- 工作区只含本步文件；不 push。
