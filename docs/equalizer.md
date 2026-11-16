# 音乐均衡器

> 状态：设计（已实施） · 适用版本 1.41.0 · 最后核对 2026-11-16
>
> 2026-11-16 立项。回答「桌面播放器怎么加 10 段均衡器：界面、状态与音频后端各归谁」。
> `AGENTS.md` §4 曾把均衡器列为 v1 之外；读者 2026-11-16 明确要求增加，这一版按本方案实施，§4 那一行随之改成「已实施」。
> 结论：桌面走 media_kit / libmpv 的 `af` 属性挂 ffmpeg 均衡器链；移动端本轮不做。
>
> 2026-11-16 增补（1.40.0）：可以把当前曲线存成自己的预设，名字与增益一起落盘；自存曲线与内置曲线同表参与高亮，内置优先。
>
> 2026-11-16 增补（1.41.0）：步进改为 0.5 dB 且允许键入数值；十个频段共用一档带宽（1 / 2⁄3 / 1⁄2 / 1⁄3 倍频程）；预放可手动覆盖。三项都只存在于完整编辑器，快捷面板仍是开关 + 四组曲线。

## 目录

- [目标与非目标](#目标与非目标)
- [结论](#结论)
- [现状与约束](#现状与约束)
- [方案对比](#方案对比)
- [数据模型](#数据模型)
- [后端映射](#后端映射)
- [状态与依赖](#状态与依赖)
- [界面](#界面)
- [文案](#文案)
- [测试与验收](#测试与验收)
- [落地顺序](#落地顺序)
- [风险与回滚](#风险与回滚)
- [不在范围](#不在范围)
- [相关文档](#相关文档)

## 目标与非目标

- 10 段 ISO 中心频率，增益 ±12 dB，步进 0.5 dB，可键入到 0.1 dB；
- 12 个内置预设 + 自存预设 + 自定义；预设是查找表，不是第二份状态；
- 开关即旁路：关闭后 mpv 上不留任何均衡器滤镜；
- 频段宽度、预放（自动或手动）可调，与曲线一起落盘；
- 拖动即时生效，重启恢复；换歌、暂停、seek 都不重挂滤镜；
- 一套面板，三个入口：底栏、正在播放页、设置「播放」卡；
- Linux 桌面验收；Windows 共用同一后端，未真机验收前不写成已验收。

不做：

- Android / iOS 的 `AudioEffect`（后续单独立项）；
- 自动均衡、房间校正、按输出设备分别保存；
- 压缩器、限幅器、响度归一化、空间音频；
- 频谱可视化与「低音增强」独立旋钮。

## 结论

| 决策 | 选择 | 原因 |
| --- | --- | --- |
| 频段 | 10 段 ISO（31 Hz–16 kHz） | 常见 EQ 口径，读者与其它播放器的预期一致 |
| 处理位置 | libmpv 的 `af` 滤镜链 | 后端现成，零新依赖，不动 Dart 音频线程 |
| 状态所有者 | `EqualizerController`（`features/player/application`） | 与播放域同层；设置页只读它，不存第二份 |
| 持久化 | 偏好键 `audio_equalizer_v1`（JSON） | 一个偏好一个文件；不入库，无迁移 |
| 界面 | 快捷面板 + 完整编辑器两个面板，共用一份状态 | 播放器旁边放不下十个滑块；控件不复制状态 |
| 默认值 | 关闭、平坦（全 0） | 不改变现有听感 |
| 平台 | Linux 验收，Windows 同码路径 | 后端能力由运行时探测决定，不写进平台能力表 |

## 现状与约束

- 桌面播放链是 `MediaKitAudioPlayerService` 直连 media_kit 的 `Player`，已经通过 `player.platform as NativePlayer` 写 mpv 属性（`_applyPolicy`，`lib/data/services/impl/media_kit_player_service.dart:68`）。均衡器沿用这一个碰底层的点，不开第二条到 mpv 的通道。
- mpv 的 `af` 是运行时属性。本方案在 mpv 0.41 / ffmpeg 8.0.1 上用 IPC 实测（2026-11-16）：

```text
set_property af "lavfi=[volume=-3dB,equalizer=f=31:width_type=o:width=1:g=4,equalizer=f=1000:width_type=o:width=1:g=-5]"  → success
get_property af → 图串原样读回
set_property af "" → success（清空）
```

- 方括号内的逗号不会被 mpv 当成滤镜分隔符，一个 `lavfi` 节点里可以串 10 个 `equalizer`。
- 移动端是 `just_audio`，没有暴露均衡器；Android 要 `android.media.audiofx.Equalizer` 加平台通道，不在本轮。
- 架构约束：状态只在 application 层改；`data/services` 不依赖 Riverpod；播放域之外不复制播放状态（见 [architecture.md](architecture.md)）。
- `AGENTS.md` §4 的旧范围与本方案冲突，已改成「已立项、未实施」，避免下一个协作者照着旧句删掉入口。

## 方案对比

| 方案 | 做法 | 判断 |
| --- | --- | --- |
| A（采用） | mpv `af` + ffmpeg `equalizer` | 后端现成、频点可控、已实测；与既有 mpv 属性写法同源 |
| B | ffmpeg `superequalizer` | 18 个固定频点，与 10 段界面对不上，映射不直观 |
| C | 系统级 / 平台 `AudioEffect` | Linux 没有统一接口；Android 需平台通道，本轮不做 |
| D | Dart 侧自建 DSP | 实时音频回调不在 Dart 层，等于换播放后端，代价不成比例 |

## 数据模型

| # | 中心频率 | 带宽 |
| --- | --- | --- |
| 1 | 31 Hz | 1 octave |
| 2 | 62 Hz | 1 octave |
| 3 | 125 Hz | 1 octave |
| 4 | 250 Hz | 1 octave |
| 5 | 500 Hz | 1 octave |
| 6 | 1 kHz | 1 octave |
| 7 | 2 kHz | 1 octave |
| 8 | 4 kHz | 1 octave |
| 9 | 8 kHz | 1 octave |
| 10 | 16 kHz | 1 octave |

- 增益 `-12.0`–`+12.0` dB，步进 `0.5`；`enabled` 默认 `false`；`gains` 长度固定 10。面板滑块 48 格（24 dB ÷ 0.5），点增益数字可以键入数值，读到的小数按 0.5 吸附（`clampGain`）。
- 存 `enabled`、`gains` 与 `userPresets`；当前值命中哪组就高亮哪组，否则显示「自定义」。
- `userPresets` 是读者自己存的曲线：`[{"id": "user-<微秒>", "name": "...", "gains": [...]}]`，可空、可缺省（旧文件读进来就是空表，不迁移、不改 `version`）。
- 命中顺序：先 12 组内置曲线，再按顺序比自存曲线；同一根曲线既像内置又像自存时显示内置名——内置说法不因读者存了一份副本而改名。
- 同名再存是覆盖那一条的增益，id 不变；删掉正在用的曲线只动预设表，增益原样留着，于是回落到「自定义」。
- 读取时按长度、范围、NaN 归一；版本不认识就回默认，不抛异常——坏偏好不能拦住启动。
- 频段宽度 `bandWidth`：十个频段共用一档，取值只有 `1`、`2/3`、`1/2`、`1/3` 倍频程（`EqualizerSettings.bandWidths`，写入前经 `clampBandWidth` 吸附）。等于 `1` 是默认值，不写进 JSON。
- 预放默认是派生值 `preampDb = -max(0, max(gains))`，用来抵消提升段带来的削波；读者可以手动覆盖成 `-24`–`0` 的整 dB 值（`preampOverrideDb`，经 `clampPreamp` 取整并夹紧），此时才写进 JSON 的 `preampDb`。`copyWith(useAutoPreamp: true)` 回到自动。

```json
{
  "version": 1,
  "enabled": true,
  "gains": [7, 6, 4, 1, 0, -1, 0, 1, 3, 3],
  "userPresets": [
    {"id": "user-1731763200123456", "name": "我的低音", "gains": [7, 6, 4, 1, 0, -1, 0, 1, 3, 3]}
  ],
  "bandWidth": 0.5,
  "preampDb": -9
}
```

- 没存过曲线时 `userPresets` 整个字段不写，文件形状与 1.39.0 一致。
- `bandWidth` 只在不是 1 倍频程时写；`preampDb` 只在手动覆盖时写。旧文件读回来两者都取默认（1 倍频程、自动预放），不迁移、不改 `version`。

预设曲线（代码常量 `EqualizerPresets`；改曲线不改 schema）。1.37.3 起 12 组，`quick` 是快捷面板给的那四组：

```json
{
  "flat":       [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
  "pop":        [-1, 0, 1, 2, 3, 3, 1, 0, 1, 2],
  "rock":       [4, 3, 2, 1, 0, -1, 1, 2, 3, 4],
  "jazz":       [3, 2, -1, -1, 1, 2, 2, 1, 2, 3],
  "classical":  [2, 1, 0, 0, 0, 0, -1, -2, -3, -4],
  "acoustic":   [4, 3, 2, 1, 1, 1, 1, 2, 2, 2],
  "bass":       [6, 5, 4, 2, 0, 0, 0, 0, 0, 0],
  "vocal":      [-2, -1, 0, 2, 4, 4, 2, 0, -1, -2],
  "hiphop":     [7, 6, 4, 1, 0, -1, 0, 1, 3, 3],
  "electronic": [4, 3, 0, -1, -2, 0, 1, 2, 3, 4],
  "live":       [4, 3, 1, -1, -1, 0, 1, 2, 3, 2],
  "soft":       [2, 1, 0, 0, -1, -1, -2, -2, -3, -4]
}
```

`EqualizerPresets.quick = [flat, pop, rock, bass]`：播放器旁边只给这四个，其余在设置里。自存曲线不进 `quick`，只在编辑器里出现。

## 后端映射

```dart
abstract class AudioEqualizerBackend {
  Future<void> apply(EqualizerSettings settings);
  Future<void> clear();
}
```

- `AudioPlayerService` 增加 `AudioEqualizerBackend? get equalizer`：`MediaKitAudioPlayerService` 返回自己，`JustAudioPlayerService` 与测试替身返回 `null`（本轮移动端没有均衡器）。接口加成员后，`test/app/fake_audio_player_service.dart` 也要补。
- 图串由纯函数生成：`MpvEqualizerFilter.build(settings)` 返回 `null` 或空串表示清空 `af`。
- 关闭、或 10 段全 0：写 `af = ''`，而不是留一条 0 dB 的链。

```text
lavfi=[volume=-4dB,equalizer=f=31:width_type=o:width=1:g=4,…,equalizer=f=16000:width_type=o:width=1:g=3]
```

- `width` 是倍频程数，跟着 `settings.bandWidth` 走：1 → `1`、2⁄3 → `0.667`、1⁄2 → `0.5`、1⁄3 → `0.333`（`MpvEqualizerFilter._octaves` 取三位小数）。十个频段共用同一档。

- 启动探测：`init()` 之后写一次 `af='lavfi=[volume=0dB]'` 再清空。失败只记一次日志并把后端置空，界面据此隐藏入口，播放不受影响。
- 写入串行化：同一时刻最多一个 `setProperty` 在飞，只保留最新一份待写；拖动时节流 100 ms（每秒最多 10 次重建滤镜链）。
- 换曲、seek、暂停都不重挂：`af` 是播放器属性，下一首沿用；后端重新 `init()` 时用缓存的最新设置重放一次。

| 平台 | 后端 | 本轮 |
| --- | --- | --- |
| Linux | media_kit / libmpv | 实现并验收 |
| Windows | media_kit / libmpv（audio-only libs） | 同代码路径，未真机验收 |
| Android | just_audio | 不支持，入口隐藏；后续接 `AudioEffect` |
| iOS / 其它 | just_audio / 无 | 不支持 |

## 状态与依赖

| 文件 | 职责 |
| --- | --- |
| `lib/domain/models/equalizer_settings.dart` | 模型、频段常量、预设表、JSON、预放 |
| `lib/data/services/audio_equalizer_backend.dart` | 后端接口 |
| `lib/data/services/impl/mpv_equalizer_filter.dart` | 设置 → `af` 字符串（纯函数） |
| `lib/data/services/impl/media_kit_player_service.dart` | 实现后端；串行写 `af` |
| `lib/features/player/application/equalizer_controller.dart` | 唯一状态所有者：加载、应用、节流、落盘 |
| `lib/features/player/application/equalizer_providers.dart` | `equalizerControllerProvider`、`equalizerAvailableProvider` |
| `lib/shared/ui/equalizer_sheet.dart` | 快捷面板与完整编辑器（两个面板、一套状态） |
| `lib/config/app_initializer.dart` | 音频初始化后恢复一次 |

- 启动顺序：`PersistenceService.init()` → `AudioPlayerService.init()` → `EqualizerController.restore()`；失败只记日志，不拦住首屏（与播放会话同一口径）。
- 写盘时机：拖动中不写；停下 400 ms 写一次，关闭面板时再补一次；值没变不写。
- 读路径：面板 `ref.watch(equalizerControllerProvider)`；底栏只看 `equalizerAvailableProvider`，不因拖动重建。
- 播放域仍由 `PlaybackController` 独占；均衡器不持有队列，不碰音量与 MPRIS 音量。

## 界面

- 面板走 `showCompactSheet`（`lib/shared/ui/compact_sheet.dart`），宽 `CompactTokens.sheetWidth`，内容超高时面板内滚动。
1.37.3 起分两层，状态仍是同一个 `EqualizerController`：

| 面板 | 谁打开 | 内容 |
| --- | --- | --- |
| 快捷面板 `EqualizerQuickSheet` | 底栏「更多」菜单、正在播放页顶栏 | 标题 + 开关 + 4 个常用曲线（平坦 / 流行 / 摇滚 / 重低音）；手动改过的曲线追加高亮的「自定义」；底部一行小字指向设置（`equalizerQuickHint`） |
| 完整编辑器 `EqualizerEditorSheet` | 设置 › 播放 › 均衡器 | 标题 + 开关 + 「存为预设」「重置」+ 12 个内置 chips + 自存 chips（带删除标记）+ 频段宽度 chips + 预放（自动/手动 + 滑杆）+ 10 个竖向滑块 + 底部预放说明（`equalizerHint`） |

- 为什么分两层：底栏和正在播放页顶栏只有几百像素，十个滑块加十二枚 chip 会跟播放控件抢空间；听歌时选曲线本来也只需要「按心情点一下」。
- 快捷面板用 `EqualizerPresets.quick`，编辑器用 `EqualizerPresets.all`；两张表都在 model 里，面板不自己写一份。
- 关闭状态：两个面板的控件仍可改，灰显但不锁死；读者可以先调曲线再打开开关。
- 后端不可用：两个面板照常打开，控件置灰且不回调，顶部写 `equalizerUnavailable`。
- 编辑器里的滑块中心 0 dB，上 +12、下 -12，48 格（0.5 dB 一格），拖动时在滑轨上显示当前 dB；小数按 1 位显示（+3.5 dB），整数不带小数点。
- 点频段上方的 dB 数字弹出 `AlertDialog` 直接键入数值：解析失败或超范围就留在对话框里提示 `equalizerGainDialogHint`，合法值按 0.5 吸附后立刻下发。
- 频段宽度在 chips 行下面单列一排，四档（1 / 2⁄3 / 1⁄2 / 1⁄3 倍频程），按 `EqualizerSettings.bandWidths` 顺序画；当前档高亮。十个频段共用一档，不是每段单独设。
- 预放是一个开关加一条滑杆：默认「跟随最大增益」（自动，滑杆不显示），切到手动后露出 -24–0 dB 滑杆，取整 dB；改回自动即清掉覆盖值。
- 「存为预设」弹出 `AlertDialog` 要一个名字（去空白后为空就不存）；存下的曲线立刻以 `InputChip` 出现在 chips 行，点击即应用，右侧 × 删除。面板自己记住刚存下的 id，所以不必重开面板。
- 自存曲线的名字是数据，直接当 chip 文字；内置曲线仍走 ARB。设置行副标题对两者都显示名字（`equalizerCurrentPresetLabel`）。

入口：

| 入口 | 位置 | 打开 |
| --- | --- | --- |
| 底栏 | `player_dock.dart` 动作行 → 「更多」菜单 | 快捷面板。动作行 1.37.2 起只画三个图标：收藏、队列、`Icons.more_horiz_rounded`；迷你窗口与均衡器折进菜单（`Icons.picture_in_picture_alt_rounded` / `Icons.equalizer_rounded`），不再按宽度藏入口 |
| 正在播放页 | `_TopBar` 队列按钮右侧的 `_RoundButton` | 快捷面板；只按可用性判断，不受宽度限制 |
| 设置 | 「播放」卡一行「均衡器」 | 完整编辑器；副标题写「当前曲线名 · 全部预设与十段滑杆」 |

- 滑块带 `Semantics(label: '31 Hz', value: '+4 dB')`，方向键可调；图标按钮统一用 `TuneTooltip`。
- 底栏只订阅可用性；面板打开时才订阅频段值，一次拖动不重建整页。

## 文案

| 键 | 中文 | 用在哪 |
| --- | --- | --- |
| `equalizerTitle` | 均衡器 | 面板标题 |
| `equalizerEnable` | 启用均衡器 | 开关 |
| `equalizerPresetFlat` / `Pop` / `Rock` / `Jazz` / `Classical` / `Acoustic` / `Bass` / `Vocal` / `Hiphop` / `Electronic` / `Live` / `Soft` | 平坦 / 流行 / 摇滚 / 爵士 / 古典 / 原声 / 重低音 / 人声 / 嘻哈 / 电子 / 现场 / 轻柔 | 12 个预设名 |
| `equalizerCustom` | 自定义 | 未命中预设时的状态 |
| `equalizerReset` | 重置 | 恢复平坦 |
| `equalizerSavePreset` | 存为预设 | 编辑器标题行的保存按钮，也是命名对话框的标题 |
| `equalizerPresetName` | 预设名称 | 命名对话框的输入框 |
| `equalizerPresetDelete` | 删除预设 | 自存 chip 删除标记的 tooltip |
| `equalizerBandWidth` | 频段宽度 | 宽度选择器标题 |
| `equalizerBandWidthHint` | 越窄，一个频段影响的频率范围越小 | 宽度选择器说明 |
| `equalizerWidthOne` / `TwoThirds` / `Half` / `Third` | 1 倍频程 / 2⁄3 倍频程 / 1⁄2 倍频程 / 1⁄3 倍频程 | 四个宽度 chip |
| `equalizerPreamp` | 预放 | 预放开关标题 |
| `equalizerPreampAuto` / `Manual` | 跟随最大增益 / 手动 | 预放开关的副标题 |
| `equalizerPreampHint` | 手动调低一点，音量大时更少削波 | 手动预放滑杆旁的说明 |
| `equalizerGainDialogTitle` | 设置增益 | 键入数值对话框标题 |
| `equalizerGainDialogHint` | 以 0.5 dB 为一步 | 键入数值对话框的输入提示与错误提示 |
| `equalizerHint` | 提升的频段会用等量预放抵消，避免削波 | 编辑器底部说明 |
| `equalizerQuickHint` | 更细的频段和全部预设见 设置 › 播放 | 快捷面板底部说明 |
| `equalizerGainDb(value)` | {value} dB | 滑块值与语义标签 |
| `equalizerFrequencyHz(frequency)` | {frequency} Hz | 频段刻度 |
| `equalizerUnavailable` | 这个平台的播放后端不支持均衡器 | 后端不可用时的说明 |
| `settingsEqualizerAction` | 均衡器 | 设置行标题 |
| `settingsEqualizerActionHint` | 全部预设与十段滑杆 | 设置行副标题（前缀是当前曲线名） |
| `playerEqualizer` | 均衡器 | 两个入口的 tooltip |

- 模板是 `lib/l10n/app_zh_CN.arb`，同步 `app_en` / `app_zh` / `app_zh_TW`，再 `flutter gen-l10n`，产物入库。
- 预设 id 是数据，不进 ARB；名称是文案，id → 键的映射在 presentation 层，model 不持有界面文字。

## 测试与验收

单测：

- `test/domain/equalizer_settings_test.dart`：JSON 往返、长度/范围/NaN 归一、未知版本回默认、预设命中与 `custom`、预放；自存预设的存取/覆盖/删除、坏条目跳过、内置优先、`userPresets` 为空时不写字段；步进 0.5 吸附、`bandWidth` / `preampDb` 往返与「默认值不写盘」、`clampBandWidth` / `clampPreamp`、`withGain` 保留宽度与预放。
- `test/services/mpv_equalizer_filter_test.dart`：关闭 → 空；全 0 → 空；10 段顺序与 `width_type=o:width=1`；预放；固定样例与 IPC 实测图串一致；四档宽度对应的 `width=0.5 / 0.667 / 0.333`、0.5 dB 小数增益、手动预放覆盖自动值。
- `test/features/player/equalizer_controller_test.dart`：`FakePersistenceService` + 假后端；预设命中、400 ms 落盘防抖、值不变不写、`dispose` 补写、后端为 `null` 时不崩；存为预设后落盘能读回、空名不存、同名覆盖、删掉在用的预设回落 `custom`；`setBandWidth` 吸附后下发且值不变不下发、`setPreampOverride` 手动/回自动、宽度与预放落盘后重启读得回来。

组件测试：

- `test/shared/equalizer_sheet_test.dart`：快捷面板只画 4 个 chip、没有滑块与重置；编辑器画 12 个 chip 与 10 个滑块，拖动回落到正确频段；手动改动后显示「自定义」；后端不可用时两个面板都置灰且不回调；存为预设对话框回传去空白后的名字并画出 chip、回调给不出 id 时不画、自存 chip 的删除标记回调 id 并消失；滑块 48 格、点 dB 数字键入 3.7 回 3.5、非法输入留在对话框；宽度 chip 回报对应倍频程、预放开关切到手动才露出滑杆。
- `test/shared/equalizer_entry_test.dart`：播放器入口 → 快捷面板的联动（`openEqualizerPanel` 读控制器与平台可用性）；预设与开关落回控制器、面板里不出现滑块；不可用平台仍能打开但只读。

Linux 手测：

- 本地曲目播放中拖 31 Hz 与 16 kHz，听感有变化，进度不跳、不中断；
- 把宽度从 1 倍频程切到 1⁄3，提升 1 kHz 时听感更窄；手动预放拉到 -12 后整体变轻；
- 切歌后设置仍在，关闭开关恢复原声；
- 重启应用设置恢复，关面板再开值一致；
- 读 `PlaybackController` 的音量：改均衡器不改变音量，MPRIS 音量不动。

门禁：

```bash
./tool/check.sh --l10n --tools --docs
```

## 落地顺序

| 里程碑 | 内容 | 完成信号 |
| --- | --- | --- |
| M1 | 模型、预设、JSON、图串纯函数 | 两个单测文件绿 |
| M2 | 后端 getter、mpv 写入、启动探测、controller 与初始化 | 假后端与真机各一次 apply 成功 |
| M3 | 面板、滑块、三个入口、四份 ARB 与 gen-l10n | 组件测试绿，中英文不溢出 |
| M4 | architecture 的状态归属/持久化表、README 与 AGENTS 收口、手测 | `check.sh` 全绿 + 手测清单 |
| M5 | 自存预设：`userPresets` 落盘、存/删对话框与 chips、三处文案 | 领域与控制器用例绿，存下的曲线重启后还在 |
| M6 | 细调维度：0.5 dB 步进与键入、共用频段宽度、手动预放（1.41.0） | 四个测试文件绿，宽度/预放重启后还在 |

## 风险与回滚

| 风险 | 影响 | 处置 |
| --- | --- | --- |
| 滤镜链重建 | 拖动时可能有极短断音 | 100 ms 节流；仍明显就改成拖动结束才 apply（面板不变） |
| 提升段削波 | 大增益时失真 | 自动预放；预设留 4–6 dB 余量；不做 limiter（不在范围） |
| libmpv 未编入 lavfi | apply 失败 | 启动探测失败即隐藏入口，只记一次日志 |
| Windows 未真机验收 | 同码路径可能不工作 | 可用性按运行时探测，发布说明标注未验收 |
| 读者把 EQ 当音量 | 以为在调音量 | 预放写在滤镜内，音量属性与 MPRIS 不动 |

回滚：

- 关闭开关即清空 `af`；删掉偏好键回到默认；
- 不新增数据库表，无迁移；
- 入口按可用性渲染，撤掉界面不需要回滚数据。

## 不在范围

- Android / iOS 的 `AudioEffect` 与耳机端处理；
- 空间音频、低音增强独立旋钮、动态低音；
- 响度归一化、压缩器、限幅器；
- 自动 EQ、房间校正、麦克风采集；
- 频谱可视化、按设备保存预设、全局快捷键。

## 相关文档

- [架构](architecture.md) — 状态归属、持久化与依赖方向
- [设置页重构](settings-redesign.md) — 分区、卡与预设 chips 的语言
- [约定](conventions.md) — 尺寸、字体、日志与文件体积
- [国际化](i18n.md) — 新增文案与四份 ARB
- [验证](verification.md) — 门禁、测试布局与截图探针
