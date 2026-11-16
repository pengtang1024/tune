# 健康度：unknown 应该算负面

> 状态：规范 · 适用版本 1.45.1 · 最后核对 2026-11-17

> 给正在开发健康度系统的会话：2026-10-24。
> 这不是推荐系统的权重表，而是对健康度输入语义的提醒。

## 结论

**未知（unknown）不是中性。** 一个来源没有给出某项事实，不能按 0.5 处理，
否则「不知道」会和「一半可用」拿到同样的分，健康度会偏高。

推荐侧现在按健康度分数消费：`sourceHealthScoresProvider → healthFactor`。
如果健康度把 unknown 当中性，推荐也会跟着高估这个来源。

## 需要区分的三种情况

| 情况 | 建议 |
| --- | --- |
| 还没有任何曲目（从未扫描成功） | 扫描相关维度按未知处理，总分应低于 60；不要把 `.5` 当成“还行” |
| 有曲目，但字段缺失（无播放地址、无封面、无艺人/专辑/年代） | 该维度按 **0** 计，不按 0.5 |
| 没有扫描历史 / 没有上次成功时间 / 没有产出统计 | 可靠性、稳定、新鲜、产出、速度按未知处理，不能高于中性 |
| 有明确失败 | 继续走现有封顶（不配置 ≤40，扫描失败/缺配置 ≤55） |

## 代码里目前的中性点

2026-11 起这条已经落地：`SourceHealthFacts.unknown` 把 `playable / artwork /
metadata / activity` 四项都定成 `0.25`，`SourceHealth.report` 的同名参数默认值就是它；
`SourceHealthFacts.neutral`（四项 `0.5`）已从代码里删掉。

其余维度在同一份文件里也走同一个常量：`scan`、`freshness`、`speed`、`reliability`
在缺少输入时返回 `unknown`，`stability` 没有历史时同样。唯一还留着 `0.5` 的是
「扫描被跳过」的产出——跳过是说「这次不到期」，不是「扫出零首」。

所以现在的口径是：

1. 只有「从未有曲目的新来源」保留明确的 `unknown` 状态；
2. 一旦来源有曲目，四项事实缺失就是 `0`（`playable / artwork` 按曲目比例算，
   全缺即 0）；
3. 没有扫描历史或产出时用 `0.25`，不用 `0.5` 假装“平均”；
4. unknown 有测试守着：`test/app/source_weight_test.dart` 里
   「activity is unknown before the first heart」与「favorites outside the library
   keep activity unknown」两条都断言 `0.25`。

## 「不到期」不是一个样本

2026-11-17 修掉了一个让健康度整体失真的缺陷：自动扫描会按间隔跳过每个来源，
而 `skipped` 以前被当成一次**真实结果**写进两处：

- 健康历史（`SourceScanHealthHistory`，只留最近 5 条）——连跳五次就把上一次
  成功或失败挤出去，稳定度定格在 0.75 左右，所有来源看起来一样好；
- 上次扫描摘要（`LibraryState.sourceSummaries`）——跳过一次就把上一次的
  「成功」覆盖成「跳过」，于是页头一直挂着「有来源有问题」，健康度的扫描/产出/
  可靠性三项永远读 0.66/0.5/0.75。

现在的口径：`skipped` **不写入健康历史**，也**不覆盖上一次真实摘要**；没有更早
摘要时才把这次跳过留作占位。判据由两条用例守着：
`test/app/music_sources_controller_test.dart` 的「a scan that is not due yet is
not a health sample」与 `test/app/library_source_merge_test.dart` 的
「a scan that is not due yet keeps the last real summary」。

## 推荐侧的配套

- `sourceHealthOf` / `_sourceHealthOf` 对不在健康度结果里的来源按 **0.25**
  处理（负面，不是 0.5）。
- 健康度低于 `0.60` 的来源不单独出「来自 X」分段。
- 健康度权重仍由音源页单独管理；推荐不复制 `SourceHealthWeights`。

## 验收

- 未知维度不会把来源推过 `60`；
- 有曲目但无播放地址 / 无封面 / 无元数据的来源分数明显低于同一来源的正样本；
- 推荐里的未知来源轨道继续降权，不会因为“没有数据”而得到中性待遇。

## 相关文档

- [音源设计](../需求/音源设计.md) — 健康度的维度、权重与排序
- [架构契约](architecture.md) — 这些分数归谁算、谁订阅
- [推荐](../需求/音源设计.md) — 未知来源在推荐里的降权口径
