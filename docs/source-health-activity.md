# 健康度活跃维度接入播放记录

> 状态：方案（待实现）。最后更新：2026-10-24。
>
> 上位文档：[音源设计](../需求/音源设计.md)、[代码约定](conventions.md)、
> [测试与验证](verification.md)。

## 1. 要解决什么

音源健康度的「活跃」维度现在只看收藏比例：

```text
activity = 来源曲目里被标心的数量 / 来源曲目总数
```

问题是：读者可能经常听某个来源，但很少标心。这个来源在健康度里会被当成
「不活跃」。本地播放记录已经存在（可选、默认关闭、只在本机、只存
`uri → 次数/最近时间`），但只有发现页在读；音源这边读不到，也不该直接依赖
`features/discovery`。

目标：读者开启本地播放记录后，活跃维度同时看**收藏**和**播放**；没有开启时
保持现在的只看收藏。播放记录仍然默认关闭，不新增收集字段。

## 2. 现状与依赖问题

| 东西 | 现在在哪 | 谁在读 |
| --- | --- | --- |
| `TrackListening` | `lib/features/discovery/domain/track_listening.dart` | 发现页 |
| `ListeningSignalStore` | `lib/features/discovery/data/listening_signal_store.dart` | 发现页 |
| `listeningSignalStoreProvider` | `lib/features/discovery/application/discovery_providers.dart` | 发现页 |
| 播放观察器 | `lib/features/discovery/application/discovery_signal_observer.dart` | 应用启动 |

播放记录不是发现页专属的数据：它描述的是「这首歌被听过几次」，音源健康度、
以后的统计都可能用。音源如果直接 import discovery，会形成
`discovery → sources`（健康度分数）和 `sources → discovery`（播放记录）的
双向依赖。

## 3. 方案

### 3.1 把播放记录移到共享层

| 从 | 到 |
| --- | --- |
| `lib/features/discovery/domain/track_listening.dart` | `lib/domain/models/track_listening.dart` |
| `lib/features/discovery/data/listening_signal_store.dart` | `lib/data/services/listening_signal_store.dart` |
| `features/discovery/application/discovery_providers.dart` 里的 provider | `lib/data/services/providers/listening_signal_providers.dart` |

- 存储键继续用 `discovery_listening_v1`，不改名，旧数据不用迁移。
- `DiscoverySignalObserver`、`DiscoveryController`、发现页测试改成新 import，
  行为不变。
- 移动后 `features/sources` 只依赖 `domain/models` 和 `data/services`，
  不再碰 discovery。

### 3.2 活跃维度的公式

`sourceHealthFactsOf` 增加一个可选参数：

```dart
Map<String, SourceHealthFacts> sourceHealthFactsOf(
  List<Song> songs, {
  Set<String> favoriteUris = const {},
  Map<String, TrackListening> listening = const {},
})
```

每个来源先算两个比例：

```text
favoriteShare = 被标心的曲目数 / 曲目总数
playedShare   = 至少播放过 1 次的曲目数 / 曲目总数
```

然后：

| 情况 | activity |
| --- | --- |
| 播放记录关闭 | `favoriteShare`（保持现在） |
| 播放记录开启 | `0.5 × favoriteShare + 0.5 × playedShare` |
| 全库既没有喜欢也没有播放记录 | `0.5`（中性，维持现有规则） |
| 全库有信号，但这个来源两样都没有 | `0`（这个来源确实没被用过） |
| 来源还没有曲目 | 不生成 facts，调用方用 `SourceHealthFacts.neutral` |

- 收藏是显式动作，播放是隐式动作，各占一半；以后要调比例只改这一处。
- 播放次数不按次数加权：听过 1 次和听过 100 次都算「这个来源被用过」。
  避免把某一首循环很多次的曲目当成整个来源活跃。
- 不看跳过：健康度的活跃是「这个来源有没有被使用」，跳过属于推荐排序里的
  负信号，已经有 `skipPenalty` 处理。

### 3.3 读取与刷新

`sourceHealthReportsProvider` 增加：

```dart
final useListening = ref.watch(
  settingsControllerProvider.select((state) => state.useListeningHistory),
);
final listening = useListening
    ? ref.watch(listeningSignalStoreProvider).read()
    : const <String, TrackListening>{};
```

- 关闭时不读存储，行为和现在一致。
- 健康度是粗粒度信号，不在每切一首歌时重新计算：播放记录变化后，等下一次
  自然重建（切到音源页、收藏变化、扫描、设置变化）才生效。
- 如果以后需要实时刷新，再加一个 debounce 的 revision provider；不要直接把
  每次写入都接到健康度上，否则音乐库的来源筛选会跟着每首歌重建。

### 3.4 隐私与文案

播放记录仍然默认关闭，仍然只在本机、只存聚合。但现在开启后不只影响推荐，
也影响音源健康度，所以相关文案要改：

- 设置页「本地播放记录」的说明：推荐和音源健康度都会用。
- 发现页「怎么推荐」浮层：如果那里写了用途，补一句音源健康度。
- 不新增任何字段，不上传，不存曲名或时间线。

## 4. 测试

- `test/services/listening_signal_store_test.dart`：改 import，行为不变。
- `test/app/source_weight_test.dart` / 新的 facts 测试：
  - 播放记录关闭时，活跃仍然等于收藏比例；
  - 开启后，一半收藏一半播放：只标心 10 首 → 0.5；只播过 10 首 → 0.5；
    两样都有 → 1.0；
  - 完全没有喜欢也没有播放记录 → 0.5；
  - 跳过不计入活跃。
- `test/app/discovery_controller_test.dart` / `discovery_signal_observer_test.dart`：
  改 import，全部回归。
- 全量 `flutter analyze` + `flutter test`；在干净 worktree 上验证。

## 5. 回退

- 代码回退：恢复 discovery 内的两个文件与 provider，删除 facts 的 `listening`
  参数即可。
- 数据不回退：存储键没变，旧播放记录仍然可用；关闭设置后健康度回到只看收藏。

## 6. 改动文件

- 移动：`track_listening.dart`、`listening_signal_store.dart`、
  `listening_signal_providers.dart`。
- 改：`source_health_facts.dart`、`source_health_reports.dart`、
  discovery 的 import、设置/发现页文案、`需求/音源设计.md`、
  `docs/recommendation.md`、`CHANGELOG.md`。
- 测试：store、facts、discovery controller/observer、音源页。

## 7. 需要确认的三个点

1. 活跃比例用 `50% 收藏 + 50% 播放`，还是收藏更重（例如 60/40）？
2. 播放记录变化后不实时重算健康度，等下一次自然重建，可以接受吗？
3. 设置页文案改成「推荐和音源健康度都使用本地播放记录」，可以吗？
