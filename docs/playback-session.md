# 启动继续上次播放

> 重启 Tune 后恢复上次的队列、曲目、播放模式和进度。入口在设置 → 播放 →
> 「启动时继续上次播放」，默认开启，恢复后停在暂停状态。

## 1. 边界

- **谁拥有会话**：`PlaybackController` 拥有播放状态，`PlaybackSessionStore` 只负责
  读写。没有第二个队列或第二个游标。
- **恢复什么**：队列、`currentUri`、播放模式、上一首历史、当前曲目的进度、音量。
- **不恢复什么**：播放/暂停状态一律恢复成暂停；速度、下载进度、错误信息、缓存状态
  都不落盘，启动后按当前曲目重新推导。
- **开关只决定“启动时读不读”**：运行中的播放仍会写入会话；关掉后启动为空白队列，
  再打开开关时读到的是最近一次的队列。当前这一轮播放不受开关影响。
- **关掉开关后启动的空状态不会自己抹掉旧会话**：启动后什么都没播、队列也没改，
  会话原样留着；一旦播放或编辑队列，新的会话就覆盖旧的。

## 2. 存储

| Key | 内容 | 谁写 |
| --- | --- | --- |
| `playback_queue_v1` | 队列、`currentUri`、`playMode`、`history` | `PlaybackSessionStore` |
| `playback_position_v1` | 当前曲目的 `uri` 与 `positionMs` | `PlaybackSessionStore` |
| `volume` | 音量（沿用旧偏好键） | `PlaybackSessionStore` |

队列与进度分开存：进度每几秒变一次，队列只在切歌、增删、换模式时变。把整条队列
按进度反复重写没有意义，也会让磁盘一直忙。

写盘节奏：

- 队列/模式/历史变化后 600ms 写一次，连续编辑只落一次。
- 进度每 5 秒写一次；暂停、拖动进度、切歌、清空队列时立即写。
- 音量变化后 500ms 写一次。
- `dispose` 时取消计时器并补一次队列与进度，尽量不丢最后一小段。

## 3. 启动

`PlaybackController` 在构造时读取会话，发生在持久化初始化之后、桌面集成启动之前。
恢复后的 `PlaybackState`：

```text
status         paused
queue          上次的队列（按 uri 去重）
currentUri     上次的游标；找不到时回到队列第一首
position       上次的进度；属于别的曲目时归零
duration       当前曲目的元数据时长
playMode       上次的模式
history        仍在队列里的上一首记录
volume         上次的音量
```

按播放时 `resume()` 发现音频后端还没加载这一首，会带着 `state.position` 走
`_startAt`，所以从上次的位置继续，而不是从 0 开始。

## 4. 容错

- 队列 JSON 坏了、为空、不是列表：当作没有会话，启动为空白播放器。
- `currentUri` 不在队列里：落到第一首，至少队列还能用。
- 进度记录的 `uri` 和当前曲目不一致：进度归零。
- 进度落在曲目最后 1 秒：从 0 开始，避免一启动就结束。
- 直播流不恢复进度。
- 历史里已经离开队列的曲目会被丢掉，不会让已删除的曲目复活。
- 远程曲目的播放地址可能过期；恢复不重新解析地址，按播放时仍走原有的刷新逻辑。

## 5. 测试

- `test/app/playback_session_store_test.dart`：JSON 往返、坏文档、去重、历史过滤、
  最后 1 秒归零。
- `test/app/playback_session_test.dart`：恢复暂停态、按播放从原进度继续、开关关闭时
  空白启动、关闭时写盘、清空队列删除会话。
- `test/app/playback_session_provider_test.dart`：Provider 是否把设置开关传给控制器。
- `test/app/settings_controller_test.dart`：开关默认值与持久化。
- `test/app/compact_layout_test.dart`：设置页开关可见、可切换。
