# 任务：SAF「指定文件夹」S1 落地 + 22 文件归属调查

> 依据：`spec.md`。按顺序执行，每项完成即勾选。
> 状态：全部完成（2026-11-12）。

## A. 原生与通道

- [x] A1 `MainActivity.java` 增加 `cn.iouf.tune/saf`：`pickDirectory`（含持久授权与取消路径）。
- [x] A2 `MainActivity.java` 增加 `listTree`（递归、`audio/*` 过滤、分页、`MediaMetadataRetriever`、`permission_lost`）。
- [x] A3 `MainActivity.java` 增加 `canWrite`（持久授权匹配写权限）。
- [x] A4 新增 `lib/data/services/impl/saf_method_channel.dart`。

## B. 扫描与落点

- [x] B1 新增 `lib/data/services/library/saf_tree_store.dart`；`FileLibraryPaths.root()` 忽略 `content://`。
- [x] B2 新增 `lib/data/services/impl/system_library_row.dart`，`MediaStoreMusicScanner` 改用共用映射。
- [x] B3 新增 `lib/data/services/impl/saf_music_scanner.dart`（500 行分页、无树回退、`permission_lost` 抛出）。
- [x] B4 `cross_platform_music_scanner_provider.dart` 在 Android 返回 `SafMusicScanner`。
- [x] B5 新增 `lib/data/services/impl/saf_document_writer.dart` 的 `canWrite(Song)`。
- [x] B6 `settings_pane.dart::_pickLibraryFolder` 在 Android 走 SAF 选择器；`settings_cards.dart` 显示树名。

## C. 测试

- [x] C1 `test/services/saf_tree_store_test.dart`。
- [x] C2 `test/services/saf_music_scanner_test.dart`（分页、回退、权限丢失）。
- [x] C3 `test/services/saf_document_writer_test.dart`。

## D. 验证

- [x] D1 `flutter analyze`、`flutter test`。
- [x] D2 `JAVA_HOME=~/.jdks/ms-21.0.12.1 /opt/flutter/bin/flutter build apk --debug`。
- [x] D3 模拟器：push WAV → 选目录 → 扫描出曲目 → 重启复扫 → logcat 干净。

## E. 文档与提交

- [x] E1 更新 `docs/android.md`：§1 表格、§2 E3、§5 状态（S1 已完成，S2 待做）。
- [x] E2 提交 1：`feat(android): SAF 目录选择与树扫描通道`。
- [x] E3 提交 2：`feat(library): SAF 指定文件夹扫描与写入落点判断`。
- [x] E4 提交 3：`docs(android): SAF 第一步落地状态与验证`。

## F. 22 文件调查（只读）

- [x] F1 逐个 `git diff`，按主题分组。
- [x] F2 判定完整/半成品/与已提交冲突/所属任务。
- [x] F3 汇总成最终回复里的表；不提交、不丢弃、不回退。
