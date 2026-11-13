# 任务：SAF S2 智能词稿写入

> 依据：`spec.md`。每项完成即勾选；验证不过不进下一阶段。

## A. 原生通道

- [x] A1 `MainActivity.java`：`cn.iouf.tune/saf` 增加 `writeSheet`（查同名 / `createDocument` / `openOutputStream("wt")`）。
- [x] A2 写入失败删除刚建的文档；`SecurityException` → `permission_lost`，其它 → `saf_failed`。
- [x] A3 新建后核对 display name：provider 补扩展名时 `renameDocument` 回 `<歌名>.smart.lrc`。

## B. Dart 侧

- [x] B1 `saf_method_channel.dart`：`SafWrittenSheet` 与 `writeSheet(...)`。
- [x] B2 `saf_document_writer.dart`：`writeSmartLyrics`（名字 `<歌名>.smart.lrc`，先 `canWrite`）。
- [x] B3 `library_paths.dart`：`SheetWriteException` 与默认 `canWriteSheet`。
- [x] B4 `library_paths_io.dart`：`canWriteSheet` 覆盖 + `saveSmartLyrics` 路由（不碰 `File`）。
- [x] B5 `smart_lyrics_service.dart`：运行期落点判断；`permissionLost` 映射为 `unsupported`。

## C. 测试

- [x] C1 `saf_document_writer_test.dart` 补齐写入/不可写/权限收回/树外。
- [x] C2 `library_paths_test.dart` 覆盖三态 `canWriteSheet` 与 SAF 写入路由。
- [x] C3 `smart_lyrics_service_test.dart` 覆盖无落点与授权收回。
- [x] C4 `integration_test/saf_sheet_write_test.dart` + `pubspec.yaml` dev 依赖。

## D. 验证

- [x] D1 `flutter analyze`。
- [x] D2 `flutter test`：非 live 1505 条全绿；两条 live 网络用例单独跑 35 条全绿（全量并发时外网抖动会偶发失败）。
- [x] D3 `JAVA_HOME=~/.jdks/ms-21.0.12.1 flutter build apk --debug` 并装模拟器。
- [x] D4 模拟器跑集成测试；`adb shell ls/cat /sdcard/Music/TuneSaf/` 看落点与内容。

## E. 文档与提交

- [x] E1 `docs/android.md` §5：S2 状态、类名、差异表、读回/音频/批量限制。
- [x] E2 提交 1：`feat(android): SAF 词稿写入通道`。
- [x] E3 提交 2：`feat(smart-lyrics): 词稿写入 SAF 选中目录`。
- [x] E4 提交 3：`docs(android): S2 写入落点与桌面差异`。

## F. 收尾

- [x] F1 `git status` 只含本步文件；不 push。
- [x] F2 汇报：模拟器证据、门禁数字、仍需真机/决定的事项（SAF 音频复制、读回）。
