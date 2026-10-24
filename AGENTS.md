# Tune 工程规范

> 给 AI 协作代理的**文档地图**：先读本页，再按表跳到需要的那份文档，最后才动手改。
> 规则只维护一份（本页 + `docs/`）；`.lingma/rules/project_rule.md` 与 `.trae/rules/project_rules.md` 只指向这里。
> 与代码冲突时以代码为准，并顺手修正对应文档。

## 文档地图

| 要做的事 | 读哪份 |
| --- | --- |
| 判断改动优先级、要不要先动架构 | 本页 §1 |
| 加文件、放哪一层、能不能跨 feature 引用 | [`docs/architecture.md`](docs/architecture.md) |
| 查某个状态归谁、谁在改它 | [`docs/architecture.md`](docs/architecture.md) |
| 查偏好和本地数据存在哪、谁在写 | [`docs/architecture.md`](docs/architecture.md) 的「持久化」 |
| 加音源 / 加页面 | [`docs/architecture.md`](docs/architecture.md) 的「扩展路径」 |
| 查推荐 / 发现页的模型、入口、隐私边界 | [`docs/recommendation.md`](docs/recommendation.md)（M1–M3 已实施；M4 待做） |
| 查音源的权重、健康度维度/权重、排序与「更多音源」折叠 | [`需求/音源设计.md`](需求/音源设计.md) 的「权重」 |
| 查队列的模型（游标、随机重排、上一首） | [`需求/队列模型方案.md`](需求/队列模型方案.md) |
| 查启动恢复播放：存什么、什么时候写、开关在哪 | [`docs/playback-session.md`](docs/playback-session.md) |
| 查队列的呈现（浮层、入口、关闭） | [`docs/queue-panel.md`](docs/queue-panel.md) |
| 改歌词（取词、解析、高亮、落盘） | [`docs/lyrics.md`](docs/lyrics.md) |
| 查桌面集成（MPRIS、托盘、默认播放器） | [`需求/桌面集成方案.md`](需求/桌面集成方案.md) |
| 加文案、改文案、切语言 | [`docs/i18n.md`](docs/i18n.md) |
| 查流派名怎么翻、认不出的怎么办 | [`docs/genre-localization.md`](docs/genre-localization.md) |
| 继续查本地化覆盖、接着做审计 | [`docs/localization-audit.md`](docs/localization-audit.md) |
| 写代码：命名、日志、主题、体积、注释、脚本目录 | [`docs/conventions.md`](docs/conventions.md) |
| 加 chip、加标识、加事实：图标、颜色、tooltip、详情面板 | [`docs/chips.md`](docs/chips.md) |
| 写测试、跑门禁、截图对比 | [`docs/verification.md`](docs/verification.md) |
| 了解产品、需求与验收范围 | [`需求/README.md`](需求/README.md) |

## 0. 项目快照

- 产品：紧凑的桌面音乐播放器（Flutter）。壳层是左侧导航（音乐库 / 喜欢 / 音源 / 设置）+ 右侧内容区 + 底部播放条；播放队列是底栏和正在播放页打开的非模态侧栏，不是一级导航页；它只遮住内容区，底栏和侧栏仍可用。
- 技术栈：Flutter 3 / Dart 3.8+ · Riverpod 2 · go_router · just_audio（Linux 走 just_audio_media_kit）· dio · shared_preferences（仅 Web 存储与旧数据迁移）· gen-l10n。
- 验收平台：Linux 桌面优先；Android / iOS / Windows / macOS / Web 保留工程入口，但不是 v1 验收目标。
- 需求文档：`需求/README.md` 是入口，那里列的四份是现行权威：`紧凑播放器重构方案.md`（架构现状与验收）、`音源设计.md`（音源扩展）、`队列模型方案.md`（队列模型）、`桌面集成方案.md`（桌面集成）、`多语言设计.md`（文案规则）。
- **旧稿在 [`需求/历史/`](需求/历史/README.md)**：2025 年 12 月那版的架构、框架、功能、账号、ai 架构、旧配色、旧界面风格、默认配置、功能规范都在那里。它们描述的是当时的目录与调色板，**只当历史读，不作规范**。
- `.trae/documents/` 是历史迭代计划，其中还引用 `lib/ui`、`PlaylistService` 等已删除的结构——只当历史读，不当规范。

### 0.1 残留文档：先查，再写

旧稿留在仓库里，是为了留住当初的意图，不是待办。动笔之前：

- **只从本页的地图里取依据**。地图里没有的文档，默认是历史稿，不要照着实现。
- 发现文档与代码冲突，**以代码为准，并顺手改掉那句**（AGENTS.md §3）。
- 看到某一处规则被改过、而文档还写着旧说法，那份文档就是带偏的来源——先改文档，再继续做。
- 新写的设计说明写进 `docs/`，不要另起一份散在仓库根目录。


## 1. 最高优先级：架构优化优先于代码优化

任何改动都先查架构，再查代码细节。架构优化不是「有空再做」的附加项，而是所有实现工作的前置条件。

### 1.1 动手顺序（不可跳步）

1. **边界**：谁拥有状态？谁负责持久化？谁负责 UI 编排？
2. **依赖方向**：presentation → application → domain / data；禁止反向依赖，禁止跨 feature 的 UI 依赖。
3. **单一事实来源**：同一份数据只能有一个权威状态源。
4. **生命周期**：provider 与 controller 不持有 `BuildContext`；不在 build 中写 provider；不用 post-frame 补状态。
5. **接口**：先定义稳定的 service / controller 接口，再写实现。
6. **代码细节**：命名、拆分、常量、缓存、`RepaintBoundary` 等性能优化放在最后。

### 1.2 明确禁止

- 用 `Future.delayed`、`addPostFrameCallback`、`setState` 掩盖状态同步问题。
- 同一个业务状态在两个 provider 或两个 service 中各存一份。
- `data/`、`domain/` 反向依赖 `features/`、`app/`、`shared/ui/`。
- `features/library` 依赖 `features/player` 的 UI；`features/player` 依赖 `features/library` 的 UI。
- 为了兼容错误结构而不断增加判空、兼容分支和重复同步代码。
- 在没有定义清楚状态归属前，先做局部性能优化。

### 1.3 改动前自检（三问）

- 这次改动是否让职责更单一？
- 是否减少了跨层依赖或重复状态？
- 新增一个页面 / 平台时，是否只需接一个新入口，而不是修改一圈旧代码？

三个问题中有两个以上回答「否」，应先调整方案，而不是继续写代码。

## 2. 验证门禁

```bash
flutter analyze          # 必须 No issues found
flutter test             # 全绿
```

改过文案还要 `flutter gen-l10n` 并提交产物。细节与测试布局见 [`docs/verification.md`](docs/verification.md)。

## 3. Git

- 主线分支是 `develop`；提交信息用 `feat|fix|refactor|docs|chore(scope): 中文说明`，一次提交只做一件事。
- 工作区里别人未提交的修改不回退、不覆盖；清理旧代码前先确认引用关系（先 grep 再删）。
- 新约定写进本页或 `docs/`，不要改 `需求/` 里已标注为「早期规划」的文档来表达新规则。

## 4. 不在当前范围

- 移动端通知栏 / 锁屏控制、均衡器、播放历史、账号系统已移出主链路，不要顺手加回来。
- 主要验收平台是 Linux 桌面端；其它平台行为可以不同，但差异要写进 README 的「已知限制」。
