# Android 立项（移动端第一个平台）

> 结论先行：Android 作为移动端第一个平台独立排期，Linux 仍是唯一验收平台；
> 后台播放、通知、权限、扫描四件事分开做，不合成一次大改。
> 本机已建好 AVD `tune-api35`（API 35，`-no-window` + swiftshader），通知、前台服务、
> 媒体按键与窄屏外壳能在模拟器上验；耳机实体按键、锁屏视觉与「播完再点播」仍需真机复核。

## 0. 范围

- 做 Android；iOS 保留工程入口，不排期。
- 不把移动端逻辑塞进桌面壳层：窄屏排布走 `LayoutMetrics`，桌面能力走 `AppCapabilities`。
- 验收环境：Android 12 / 13 / 14 真机各一台；Linux 的 `flutter analyze` 与 `flutter test` 必须保持干净。

## 1. 现在的状态（代码依据）

| 事项 | 现状 | 位置 |
| --- | --- | --- |
| 工程入口 | 完整，可 `flutter build apk` | `android/` |
| 权限声明 | `INTERNET`、`READ_MEDIA_AUDIO`、`READ_EXTERNAL_STORAGE(maxSdk 32)`、`POST_NOTIFICATIONS`、`WAKE_LOCK`、`FOREGROUND_SERVICE(_MEDIA_PLAYBACK)`；运行时申请走 `permission_handler` | `android/app/src/main/AndroidManifest.xml`、`lib/data/services/impl/permission_handler_mobile_permissions_service.dart` |
| 能力表 | 移动端开 `touchShell` 与 `backgroundPlayback`；`externalToolPipeline` 与 `lyricsSheetBesideAudio` 为 false（见 §2 E3） | `lib/core/config/app_capabilities.dart` |
| 后台播放 | `audio_service` 已接：前台服务、媒体按钮、通知与锁屏控制；队列仍由 `PlaybackController` 独占。模拟器上已验证通知、前台服务与媒体按键；重复播放与真机耳机键仍待验 | `lib/features/player/application/tune_audio_handler.dart`、`lib/main.dart`、`AndroidManifest.xml` |
| 播放后端 | 官方 `just_audio`（ExoPlayer）；`audio_session` 已配播放类别与音频焦点 | `lib/data/services/impl/just_audio_player_service.dart` |
| 本地扫描 | MediaStore：`MethodChannel('cn.iouf.tune/media_store')` 查系统媒体库，行转 `Song` 时 `uri` 保 `content://`；目录遍历在 Android 上不再使用 | `lib/data/services/impl/media_store_music_scanner.dart`、`android/app/src/main/java/cn/iouf/tune/MainActivity.java` |
| 窄屏外壳 | 手机宽度走底部导航 + 紧凑播放条；队列是底部抽屉；正在播放页竖排 | `lib/features/shell/presentation/compact_shell.dart`、`app_bottom_bar.dart` |
| 单实例 | 移动端不参与：`AppCapabilities.singleInstance` 为 false | `lib/data/services/providers/desktop_service_providers.dart` |

构建注意：本机默认 Java 25 与 Gradle 8.14.3 不兼容，Android 构建要显式换 JDK 21：

```bash
JAVA_HOME=~/.jdks/ms-21.0.12.1 /opt/flutter/bin/flutter build apk --debug
```

## 2. 里程碑

### E1 后台播放与通知

目标：切到后台、锁屏后继续播；通知与锁屏按钮能暂停/继续/上一首/下一首，并驱动同一个队列。

选型（已拍板）：`audio_service`。队列的唯一主人是 `PlaybackController`（见 [`需求/队列模型方案.md`](../需求/队列模型方案.md)），
通知不能成为第二个队列主人；`just_audio_background` 会让「通知里点了下一首」与「应用内队列」各走一套，因此不采用。

改动层：

- `lib/features/player/application/tune_audio_handler.dart`：`AudioHandler` 只镜像 `PlaybackController` 的状态，并把通知动作转发回去，不持有第二份队列。放在 application 层是因为 data 层不能依赖 `features/`。
- `lib/main.dart`：Android 上在 `runApp` 前启动服务，首帧后把 handler 接到容器；Linux / Windows 不初始化。
- `AndroidManifest.xml`：媒体播放前台服务、媒体按钮 receiver、`FOREGROUND_SERVICE_MEDIA_PLAYBACK` 与 `POST_NOTIFICATIONS`。
- `MainActivity.java`：继承 `AudioServiceActivity`。

验收：后台 10 分钟不中断；通知按钮与页面按钮改同一份状态；Linux 构建与测试不变。
当前状态：代码与 APK 编译已通过。模拟器（AVD `tune-api35`，API 35，`-no-window`）上核到：

- 媒体会话以 `cn.iouf.tune` 注册，播放中 `active=true`、`state=PLAYING`，通知带 3 个动作（上一首/暂停/下一首）与 `transport` 类别；
- `AudioService` 以前台服务（`mediaPlayback`，id 1124）运行，通知渠道 `cn.iouf.tune.playback`；
- `adb shell input keyevent 85`（KEYCODE_MEDIA_PLAY_PAUSE）能把播放切成暂停，队列不变，说明媒体按键回到 `PlaybackController`；
- 切到桌面后服务仍在。

未验：耳机实体按键（模拟器没有）、锁屏视觉、以及后台 10 分钟的时长验收。

已修：Android 上播放会一直停在 loading（转圈 + 进度 0:00，实际已播到结束）。
根因是 `just_audio` 的 `play()` 要等整首播完才完成，而调用方在 `await` 之后才
记下「后端已装载这首」，于是位置与播放事件全被当作旧曲丢弃。现在
`JustAudioPlayerService` 不再 await `play()`，状态由 playing/position 流推进。

已知环境限制：本机 AVD 用 `-no-audio` 起，`PlaybackState` 已是 `PLAYING`、
控制按钮正确，但位置不推进（音频渲染停顿），「进度是否走完」需真机或带音频的模拟器复核。

另见（不属 E1，已在 E3 处理）：智能歌词的 ffmpeg 与本地引擎在 Android 上不可用，现由能力位
`externalToolPipeline` 一次性关掉，见 §2 E3 的「移动端的本地工具边界」。

### E2 权限

目标：扫描前申请，拒绝后给出可理解的出路，不静默失败。

- Android 13+：`POST_NOTIFICATIONS`（通知）与 `READ_MEDIA_AUDIO`（媒体）。
- Android 12 及以下：`READ_EXTERNAL_STORAGE`。
- 选型（已拍板）：`permission_handler`。`Permission.audio` 与 `Permission.storage` 一次申请，哪个版本认哪个，不自己读 SDK 号。
- 分层：`MobilePermissionsService`（data，接口）→ `PermissionHandlerMobilePermissionsService`（data/impl）→ `mobilePermissionsControllerProvider`（settings/application）→ 设置页「权限」分区与首次扫描。
- 拒绝语义：可再问时按钮是「允许」；`permanentlyDenied` 时按钮变成「去设置」，扫描也改成弹「去设置」对话框，而不是扫出一个空库。
- 通知权限在首帧后申请一次；桌面端实现直接返回 granted，不弹窗。

入口：设置页新增「权限」分区（只有 Android 出现）、首次扫描、启动时的通知授权。

验收：首次扫描弹一次；拒绝后再次扫描给出「去设置」；已授权时不重复弹。
当前状态：已实现。模拟器上核到启动时的通知授权弹窗与首次扫描的媒体授权弹窗；两条权限都允许后 `dumpsys package` 里是 granted。

### E3 本地库扫描

目标：选定来源后能看到曲目、能播放、重扫反映增删。

选型（已拍板）：先 MediaStore，SAF 后置。MediaStore 读系统媒体库，拿 title/artist/album/duration 与 `content://` URI，起步快；SAF 作为「指定文件夹」的补充，等 MediaStore 跑通后再做。

共同改动：

- `Song.uri` 需要承载 `content://`；`audioSourceAddress` 已按 URI 传给 just_audio，ExoPlayer 能吃。
- `song_creator` 的 `File` 读取路径要按平台分叉；移动端不再用 `audio_metadata_reader` 读标签。
- 扫描结果仍走分批 upsert（`docs/performance.md` 的写放大规则不变）。

验收：选 500 首的库，首次扫描可交互、不卡首屏；新增/删除文件后重扫正确；播放进度与桌面一致。

当前状态：已实现并在 AVD `tune-api35` 上核到。

- 原生：`MainActivity` 保留 `AudioServiceActivity`（后台播放引擎不动），新增
  `MethodChannel('cn.iouf.tune/media_store')`，方法 `listAudio` 用 `ContentResolver` 查
  `MediaStore.Audio.Media`（`IS_MUSIC != 0`，按标题排序），每行给出 `uri`（`content://`）、
  `mediaId`、title/artist/album/durationMs/dateAdded/year/size/mimeType。
- Dart：`MediaStoreMusicScanner` 实现 `CrossPlatformMusicScanner`，忽略目录参数；
  `crossPlatformMusicScannerProvider` 在 Android 上返回它，其余平台仍是目录遍历。
  `audioSourceAddress` 只对 `content://` 透传，`tune://` 与相对路径的旧语义不变。
- 行形态归一：同一首 content URI 重扫命中同一行（主键是 `uri`），不写放大。
- 库的「覆盖」判定分两种：目录扫描按文件夹判定本地行；系统媒体库扫描按「这次读到的
  URI 全集」判定——读不到的本地行（含旧的文件路径行）标为不在库内。`content://` 行
  不再被文件夹规则误判（这正是之前扫描成功却显示 0 首的根因）。
- 模拟器证据：冷启动后 `library.db` 中 `source_id='local'` 的两条
  `content://media/external/audio/media/...` 行保持 `active=1`，界面显示 2 首本地曲目。

未验（需真机 / 后续）：

- content:// 曲目在真机上的实际出声（模拟器 `-no-audio`，只能看到 `READY/PLAYING` 状态）；
- 拔出/删除媒体后重扫能清掉行（机制已实现，需在真机或带外部存储的模拟器上触发）；
- 500 首库的首屏交互与扫描耗时（模拟器只有两首测试音）；
- SAF「指定文件夹」仍未做（后置）；
- 封面缓存已改到应用私有目录，见下节。

#### 封面的落盘边界

`FileArtworkCache` 原来把封面写进 `<音乐库>/.tune/artwork`，Android 上共享存储对应用只读，
每张封面每进程刷一条 `保存封面失败` ERROR。

- 目录由 `LibraryPaths.coverCacheFolder()` 决定：桌面仍是 `<音乐库>/.tune/artwork`（行为不变）；
  Android 改为 `<应用支持目录>/artwork`，这是应用能写的目录。
- 可用性判断只做一次：目录创建或写入失败时把缓存标记为不可用，封面照常从网络取、只留在内存
  （Flutter 的图片缓存持有它），不再逐张尝试、不再逐张报 ERROR；进程内只记一条 info
  `封面缓存不可写，封面只留在内存: <目录>`。下次启动会重新判断。
- `ArtworkCache.coverFileFor` 是给桌面媒体卡片读本机文件的同步接口；目录还没解析出来时返回
  null（卡片退回网络地址），不影响手机（手机不用 MPRIS）。

未验：真机上应用私有目录的封面在重启后仍能命中（模拟器可验，见本轮记录）。

#### 移动端的本地工具边界（ffmpeg 与本地引擎）

结论：**Android 上 ffmpeg 根本不可用**，不是路径或权限写错。应用不能执行随包附带的
外部二进制（`Process.run` 一律 `Permission denied`），系统也不带 ffmpeg；每次转码都是一次
必败尝试，于是每首歌刷一遍 logcat 并吃掉 CPU。

处理：

- 已有能力位 `externalToolPipeline`（今天只有 Linux 为真）现在真正接成了「能不能调用本机
  外部程序」的唯一事实来源。智能歌词在它为 false 时直接跳过转码（WAV 才转，其余原样交给
  引擎），也不创建 `SherpaLocalEngine` / `WhisperLocalEngine`，进程内只记一条 info。
- `ProcessException` 仍作为兜底：桌面缺 ffmpeg 时也只记一次、后续不再试。

另一条同源的边界：词稿写在音频旁，Android 共享存储对应用只读（没有 SAF），每次生成都在
最后一步写失败。能力位 `lyricsSheetBesideAudio` 表达这条边界，移动端为 false：

- 自动补词（`SmartLyricsAutoFillController`）与批量（`SmartLyricsBatchController`）不再启动，
  不会围着整个库空转；
- 单曲「生成」直接返回 `SmartLyricsFailure.unsupported`，歌词面板显示
  「此平台不能把词稿写到音频旁」，不先花网络请求再失败。

后续要做移动端歌词，需要先接 SAF 或把词稿改存应用私有目录，那是独立里程碑。

### E4 窄屏外壳

目标：手机上导航从左侧栏换成底部栏，队列不再挤在播放条上方。

- 已实施：`LayoutMetrics.usesBottomNavigation` 接进 `compact_shell`，手机宽度走
  `AppBottomBar`（5 个目的地：发现 / 音乐库 / 喜欢 / 音源 / 设置）+ `MiniPlayerBar`；
  队列按钮在紧凑播放条上，打开 `SidePanelHost(bottomSheet: true)` 的底部抽屉。
- 正在播放页在 `maxWidth < LayoutBreakpoints.phoneMaxWidth` 时切成竖排（封面在上、
  信息/歌词居中、进度与传输在下）。
- 页面滚动位置：「底部导航切换」走 `context.go`，各页由 go_router 的 shell 分支保住；
  播放页进出用 `context.push`，与桌面的队列抽屉关闭路径一致。
- 验收：模拟器 390 宽下底部导航与紧凑播放条可见、设置页页头重排不溢出；
  widget 测试覆盖「手机壳层有底部栏无侧栏」「点队列图标打开抽屉」「竖排正在播放」。
- 已修：手机宽度下音乐库工具栏原来一行放不下（搜索框被压到比自身图标还窄，右侧溢出
  约 25px）。现在 `LibraryToolbar` 用 `LayoutBuilder` 在 560dp 以下改两行：搜索框独占一行，
  来源筛选/计数/筛选/排序/视图切换在第二行，排序按钮只留箭头图标。表格列头不再被裁切。
- 遗留：无。

## 3. 风险

- 真机缺口：本机有本地 AVD（`/dev/kvm` 可用），能验通知、前台服务、媒体按键与权限弹窗；
  耳机实体按键、锁屏视觉、真实厂商 ROM 的行为只能在真机上验。
- 通知与队列的双主风险：这是 E1 选 `audio_service` 的原因。
- content URI 与现有文件路径假设的冲突：E3 的主要工作量，不是插件换一下就能完。
- 共享存储只读：扫描能读，写（词稿、旁挂文件）要 SAF；在接上之前靠
  `lyricsSheetBesideAudio` 明确关闭，不做「先跑再失败」。封面缓存已改到应用私有目录，
  不在这一条里。
- Android 构建的 JDK 版本：默认 Java 25 跑不了 Gradle 8.14.3，命令里带 `JAVA_HOME`。

## 4. 已拍板

1. E1 走 `audio_service`，队列仍由 `PlaybackController` 独占。
2. E3 先做 MediaStore，SAF 后置。
3. 移动端只做 Android，iOS 保留工程入口但不排期；这条已写进 `README.md` 的已知限制。
4. E2 走 `permission_handler`：`Permission.audio` + `Permission.storage` 一次申请，
   `POST_NOTIFICATIONS` 单申请；`permanentlyDenied` 走「去设置」，不扫空库。
5. Android 上智能歌词整体停用（ffmpeg 不可执行、词稿无处落盘），等 SAF 或应用私有目录；
   不做「每首歌失败一次」的降级。
6. 封面缓存 Android 走应用私有目录，桌面保持 `<音乐库>/.tune/artwork`；目录不可写时只留内存，
   每进程一条 info。
