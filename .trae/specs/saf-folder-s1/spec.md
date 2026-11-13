# 规范：SAF「指定文件夹」第一步（S1）落地

状态：待批准（批准后才动代码）
日期：2026-11-12
相关：`docs/android.md` §5、`AGENTS.md` §1/§2/§3、`lib/data/services/`、`lib/features/settings/presentation/settings_pane.dart`

## 1. 目标

按 `docs/android.md` §5 的 S1 做「选择器 + 只读扫描」，并给出写入侧的落点判断：

1. 用户能在 Android 上通过系统目录选择器挑一个音乐文件夹；授权用
   `takePersistableUriPermission(READ | WRITE)` 持久化，跨重启可用；拿不到写权限时仍可作为只读来源。
2. 新增原生通道 `cn.iouf.tune/saf`：`pickDirectory`、`listTree(uri, offset, limit)`、`canWrite(uri)`。
3. 新增 `SafMusicScanner implements CrossPlatformMusicScanner`，按 500 行分页读树；
   `addressesSystemLibrary = true`。
4. 未选择文件夹时 Android 仍走 MediaStore（行为不变）；选择后本地源改为读该树。
5. 写入落点判断：`SafDocumentWriter.canWrite(song)` 只在「歌曲 URI 属于已选树且系统仍持有写权限」时为真；
   本步不接歌词写入（S2）。
6. 模拟器上能验证的部分全部验证：选目录、扫出曲目、重启后仍可读、logcat 无 ERROR。

不做：词稿/封面写入 SAF（S2/S3）、跨来源去重指纹、iOS、桌面行为变化。

## 2. 现状（已核实）

- 扫描入口：`LocalDirectorySourceAdapter.scan` → `CrossPlatformMusicScanner.scanMusicInDirectoriesWithProgress`；
  `MusicSourceService.localReadsSystemLibrary` 决定库是否按「URI 全集」判定失效行。
- Android 扫描：`MediaStoreMusicScanner` + `MainActivity` 的 `cn.iouf.tune/media_store`。
- 偏好：`LibraryPaths.rootKey = 'library_folder'`；`SettingsController.setLibraryFolder` 已是唯一写入口。
- 设置页：`settings_pane.dart::_pickLibraryFolder` 现在用 `FilePicker.getDirectoryPath`，
  Android 上返回的只是路径，没有持久授权。
- 22 个未提交文件属于另一会话。其中仅 `settings_controller.dart` 与 SAF 相关，
  且它的 diff 是纯 `dart format` 重排；本规范**不修改**该文件，避免夹带他人改动。
  `settings_cards.dart`、`settings_pane.dart` 不在未提交列表内，可以改。

## 3. 决策

### 3.1 偏好键：只存 tree URI，不新增可写标志

- Android 选目录后仍写 `library_folder`（存 tree URI），复用 `SettingsController.setLibraryFolder`，
  不新增写入口。
- 「可写」不落盘，改为运行期问原生 `canWrite(uri)`：系统持久授权本身就是事实来源，
  避免偏好与真实授权漂移。
- `FileLibraryPaths.root()` 遇到 `content://` 值时忽略并回退默认音乐目录：SAF 地址不是文件系统路径，
  不能让 `Directory('content://…')` 出现在任何写入路径。

### 3.2 原生通道

`android/app/src/main/java/cn/iouf/tune/MainActivity.java`：

- `pickDirectory`：`ACTION_OPEN_DOCUMENT_TREE` + READ/WRITE/PERSISTABLE 标志，
  `startActivityForResult`；回调里 `takePersistableUriPermission`，返回
  `{uri, name, writable}`；取消返回 `cancelled`。
- `listTree(uri, offset, limit)`：`DocumentsContract.buildChildDocumentsUriUsingTree` 递归，
  `limit` 默认 500；只收 `audio/*`、`application/ogg` 与常见音频扩展名；
  行字段与 MediaStore 对齐（`uri`、`mediaId`=documentId、`title`、`artist`、`album`、
  `durationMs`、`dateAddedSeconds`、`size`、`mimeType`）；标签与时长用
  `MediaMetadataRetriever` 尽力读取，失败时退回文件名。`SecurityException` 返回
  `permission_lost`。
- `canWrite(uri)`：遍历 `getPersistedUriPermissions()`，匹配 URI 且 `isWritePermission()`。

### 3.3 Dart 侧

| 文件 | 内容 |
| --- | --- |
| `lib/data/services/impl/saf_method_channel.dart`（新） | 通道封装：`pickDirectory`、`listTreePage`、`canWrite` |
| `lib/data/services/library/saf_tree_store.dart`（新） | 只读偏好助手：`treeUri`、`isTreeUri`、`displayName` |
| `lib/data/services/impl/saf_music_scanner.dart`（新） | 分页扫描；无树时委托 `MediaStoreMusicScanner` |
| `lib/data/services/impl/system_library_row.dart`（新） | 行 → `Song` 的共用映射（MediaStore 与 SAF 复用） |
| `lib/data/services/impl/media_store_music_scanner.dart` | 改用共用映射，行为不变 |
| `lib/data/services/providers/cross_platform_music_scanner_provider.dart` | Android 返回 `SafMusicScanner` |
| `lib/data/services/impl/saf_document_writer.dart`（新） | `canWrite(Song)`：树内 URI + 原生写权限 |
| `lib/features/settings/presentation/settings_pane.dart` | `_pickLibraryFolder` 在 Android 走 SAF 选择器；文案路径显示树名 |
| `lib/features/settings/presentation/settings_cards.dart` | 树 URI 显示为可读名称（解码最后一段） |

错误语义：`permission_lost` 让扫描**失败**而不是返回空列表，避免把本地行全部标成失效；
只记一次 info，不逐首报错。

## 4. 验证

1. `flutter analyze` 无问题；`flutter test` 全绿。
   - 新增 `test/services/saf_tree_store_test.dart`（树 URI 识别 / 显示名）。
   - 新增 `test/services/saf_music_scanner_test.dart`（通道分页 500+1、无树回退 MediaStore、
     `permission_lost` 抛出）。
   - 新增 `test/services/saf_document_writer_test.dart`（无树 / MediaStore 行 / 树外行进 / 树内且可写）。
2. `JAVA_HOME=~/.jdks/ms-21.0.12.1 /opt/flutter/bin/flutter build apk --debug` 成功。
3. AVD `tune-api35`：
   - `adb push` 两个已知 WAV 到 `/sdcard/Music/TuneSaf/`；
   - 设置页「更改音乐库文件夹」→ DocumentsUI 选 `TuneSaf` → 扫描；
   - 库中出现这两首（`content://…/tree/…`），`library.db` 中 `source_id='local'` 的对应行 `active=1`；
   - 杀掉进程重启后再次扫描仍能读出（持久授权生效）；
   - logcat 无 `保存封面失败`、无 SAF `ERROR`。
   - 选择器自动化若被 DocumentsUI 挡住，记录具体停在哪一步，不以「未验证」冒充通过。

## 5. 提交

按主题分三次提交，不夹带 22 个他人文件，不 push：

1. `feat(android): SAF 目录选择与树扫描通道` —— 原生通道 + Dart 通道封装 + 行映射重构。
2. `feat(library): SAF 指定文件夹扫描与写入落点判断` —— 扫描器、provider、writer、设置页接线、测试。
3. `docs(android): SAF 第一步落地状态与验证` —— `docs/android.md`。

## 6. 第二件事：22 个未提交文件的归属调查（只读）

对 `git status` 里的 22 个文件逐个 `git diff`，输出一张表：文件、改动主题、是否完整、
是否与已提交内容冲突、推测所属任务。不提交、不丢弃、不回退。已知线索：
`settings_controller.dart` 只有 `dart format` 重排；其余集中在音乐库行/详情面板/紧凑令牌与对应测试。
