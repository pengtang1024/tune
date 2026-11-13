# 验收清单：SAF S2 智能词稿写入

- [x] 原生 `writeSheet`：同名查重后截断重写、无则新建、写到一半失败删除新建文档、`permission_lost` 映射。
- [x] provider 擅自补扩展名时改回 `<歌名>.smart.lrc`（模拟器实测）。
- [x] `SafMethodChannel.writeSheet` 返回 `{uri, replaced}`，Dart 侧 `SafWrittenSheet` 对齐。
- [x] `SafDocumentWriter.writeSmartLyrics` 用 `<safeFileName(title)>.smart.lrc`，写前再问 `canWrite`。
- [x] `LibraryPaths.canWriteSheet` 三态：SAF 行问原生、MediaStore 行用能力位、桌面为 true；SAF 写入不构造 `File`。
- [x] `SmartLyricsService`：无落点 `unsupported` 且零请求；授权收回记一条 info 并 `unsupported`。
- [x] 单测覆盖写入参数与名字、不可写不调通道、`permission_lost`、树外曲目、无落点、授权收回。
- [x] `flutter analyze` 无问题；`flutter test` 非 live 1505 条全绿，两条 live 用例单独跑 35 条全绿。
- [x] `JAVA_HOME=~/.jdks/ms-21.0.12.1 flutter build apk --debug` 成功。
- [x] 模拟器集成测试通过，`/sdcard/Music/TuneSaf/Saf_One.smart.lrc` 名字与 UTF-8 内容正确。
- [x] `docs/android.md` §5 写明 S2 状态、落点、写入失败与桌面端的差异、读回/音频/批量限制。
- [x] 分阶段提交（原生 / Dart / 文档 / spec）只含本步文件，未 push。
