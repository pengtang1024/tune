# 设计文档索引

> 状态：索引 · 适用版本 1.33.0 · 最后核对 2026-11-15
>
> 这个目录放「为什么这么设计」。**入口与规则**在 [`../AGENTS.md`](../AGENTS.md) 的文档地图；本页按「什么时候该读它」把每份文档归位，包括地图里没列的审计与评估快照。
> 与代码冲突时**以代码为准**，并顺手把文档里那句改掉（`AGENTS.md` §3）。

## 目录

- [改代码前必读（契约）](#改代码前必读契约)
- [跨功能规范（只有一份，别处只指向它）](#跨功能规范只有一份别处只指向它)
- [功能设计（已实施，动这块功能前读）](#功能设计已实施动这块功能前读)
- [现状与排障](#现状与排障)
- [维护（改平台设置、发版、同步镜像前读）](#维护改平台设置发版同步镜像前读)
- [快照（只作历史，不作规范）](#快照只作历史不作规范)
- [设计稿](#设计稿)
- [写新文档](#写新文档)

## 改代码前必读（契约）

这五份是硬约束，不是建议。改动方向性的事之前先读对应那份。

| 文档 | 什么时候读 |
| --- | --- |
| [`architecture.md`](architecture.md) | 加文件、放哪一层、能不能跨 feature 引用、状态归谁、持久化怎么落 |
| [`conventions.md`](conventions.md) | 写代码：命名、日志、主题色、尺寸 token、体积、注释、脚本放哪 |
| [`verification.md`](verification.md) | 写测试、跑门禁、截图对比；含联网测试与中文路径的 SDK 补丁 |
| [`data-model.md`](data-model.md) | 加表、加列、改索引、写 SQL 之前：11 张表的列与约束、迁移方式、写库纪律 |
| [`document-style.md`](document-style.md) | 写或改任何 Markdown 之前：状态行、目录、标题层级、密度、表格、代码块、末尾去处 |

## 跨功能规范（只有一份，别处只指向它）

| 文档 | 管什么 |
| --- | --- |
| [`i18n.md`](i18n.md) | 加文案、切语言、新增音源名称怎么进 ARB |
| [`genre-localization.md`](genre-localization.md) | 流派名怎么翻、翻哪些、认不出来的怎么办 |
| [`chips.md`](chips.md) | chip / 标识的统一写法：图标、颜色、tooltip、详情面板 |
| [`licensing.md`](licensing.md) | 许可证边界；新增依赖、字体、素材前要登记什么 |
| [`health-unknown.md`](health-unknown.md) | 健康度里 `unknown` 的处理约定（不按中性算） |

## 功能设计（已实施，动这块功能前读）

| 文档 | 管什么 |
| --- | --- |
| [`library-redesign.md`](library-redesign.md) | 音乐库页头、列头、排序、密度与多列 |
| [`library-browse.md`](library-browse.md) | 分类树、分面筛选、浏览视图与可持续机制 |
| [`settings-redesign.md`](settings-redesign.md) | 设置页分区导航、预设、自定义与搜索 |
| [`recommendation.md`](recommendation.md) | 发现页的推荐模型、入口、隐私边界与「明确不做」清单 |
| [`smart-lyrics.md`](smart-lyrics.md) | 智能歌词的票池共识、账本口径与里程碑 |
| [`lyrics.md`](lyrics.md) | 歌词链路：取词、解析、高亮、落盘 |
| [`source-extension.md`](source-extension.md) | 音源类型与实例的扩展路径（结论已并回 `需求/音源设计.md`） |
| [`queue-panel.md`](queue-panel.md) | 播放队列浮层的入口、呈现与关闭 |
| [`playback-session.md`](playback-session.md) | 启动恢复上次播放：存什么、什么时候写、开关在哪 |
| [`performance.md`](performance.md) | 卡顿、重建风暴、内存的诊断与修复（D1–D11） |
| [`performance-row-design.md`](performance-row-design.md) | 列表行为什么这么画：表格列、提示层、行高（D5） |
| [`local-components.md`](local-components.md) | 本地组件的注册、下载校验、档位与设置页（1.32.0 起） |
| [`updates.md`](updates.md) | 自动更新：数据源、产物命名、发布与本地升级步骤 |
| [`update-cdn.md`](update-cdn.md) | `version.json`、CDN 三档取数、退避调度与签名规划 |
| [`android.md`](android.md) | Android 的后台播放、通知、权限、MediaStore / SAF 扫描 |
| [`equalizer.md`](equalizer.md) | 10 段均衡器：mpv `af` 滤镜链、状态、面板与三处入口（1.37.0 起） |

## 现状与排障

| 文档 | 用途 |
| --- | --- |
| [`troubleshooting.md`](troubleshooting.md) | **面向用户**的排障：现象 → 可能原因 → 怎么确认 → 怎么处理 |
| [`localization-audit.md`](localization-audit.md) | 本地化覆盖现状、做法与踩过的坑 |

## 维护（改平台设置、发版、同步镜像前读）

| 文档 | 管什么 |
| --- | --- |
| [`oss-maintenance.md`](oss-maintenance.md) | 开源基建全景：根级与 `.github/` 每个文件管什么、三端元数据怎么设、哪六条线改了必须同步、已知未做 |

## 快照（只作历史，不作规范）

这两份是某个时间点的审计与评估记录。它们记载的是当时的判断和数字，**不要照着实现**；需要现状就去读代码或上面那些现行文档。

| 文档 | 时间 |
| --- | --- |
| [`audit-2026-10-28.md`](audit-2026-10-28.md) | 2026-10-28 全系统审计 |
| [`local-ai-evaluation.md`](local-ai-evaluation.md) | 2026-11-13 本地 AI（ASR / 翻译 / 音频解码）选型评估 |

## 设计稿

[`mockups/`](mockups/) 放界面设计稿与改版前后对照（HTML 与 PNG）。它们是设计过程材料，不是验收依据；界面以实际代码为准。

## 写新文档

1. 写进 `docs/`，文件名 kebab-case，用中文正文。
2. 首段写清**状态**：`契约` / `规范` / `已实施` / `方案（未实施）` / `快照（日期）`。没有状态的文档，别人无法判断它还能不能当依据。
3. 在本页登记一行，再到 [`../AGENTS.md`](../AGENTS.md) 的文档地图加一行——那里是给协作者找入口用的，不能漏。
4. 状态变了要回来改首段：方案落地后改成 `已实施`，过期的审计改成 `快照` 并注明日期。
