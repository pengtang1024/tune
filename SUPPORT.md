# 获取帮助

先看这里该走哪个渠道——走对了，问题解决得快很多。

## 该走哪

| 你要做的事 | 走哪 |
| --- | --- |
| 报告可复现的缺陷 | [GitHub Issues](https://github.com/pengtang1024/tune/issues) · 用「缺陷报告」模板 |
| 提功能需求或改进建议 | [GitHub Issues](https://github.com/pengtang1024/tune/issues) · 用「功能需求」模板 |
| 问用法、问配置、问某个音源怎么填 | [GitHub Issues](https://github.com/pengtang1024/tune/issues) · 用「使用问题」模板（标题会自动带 `[问题]`） |
| **报告安全漏洞**（凭据泄漏、路径穿越、更新链劫持等） | **不要开公开 issue**，按 [`SECURITY.md`](SECURITY.md) 私下发邮件 |
| 报告行为准则问题 | 按 [`CODE_OF_CONDUCT.md`](CODE_OF_CONDUCT.md) 私下发邮件 |
| 想知道谁负责、怎么决策 | [`GOVERNANCE.md`](GOVERNANCE.md) |
| 想贡献代码 | [`CONTRIBUTING.md`](CONTRIBUTING.md) |

公开主仓是 <https://github.com/pengtang1024/tune>。Gitee 与 Gitea 上的仓库是镜像，**issue 请提到 GitHub**，只在镜像上提可能不会被看到。

## 提缺陷前先做三件事

1. **升级到最新版本**再看一次。`设置 → 关于` 里能看到版本号（形如 `1.32.0+52`），并可以手动触发「检查更新」。
2. **搜一下现有 issue**，包括已关闭的——很多问题已经被讨论过并有结论。
3. **确认是 Tune 的问题**。音源搜不到歌，先去那个音源的服务端（Navidrome、Jellyfin、Emby 等）网页界面确认它自己能用。Tune 不背着上游服务的故障。

## 提缺陷时请带上

- **版本**：`设置 → 关于` 里的完整版本号与构建号。
- **环境**：Linux 发行版与版本、桌面环境（GNOME / KDE / 其它）、是自行编译还是装了发行包。
- **复现步骤**：越短越好，写清点了哪里、选了哪个音源、期望看到什么、实际看到什么。
- **日志**：用 `flutter run -d linux` 跑一遍复现路径，把输出贴上来。

> **贴日志前先脱敏**：不要贴你的音源密码、API Key、token、Cookie，也不要贴完整家目录路径（把 `/home/你的名字` 替换成 `~`）。日志里出现凭据请直接删掉那行。

## 常见的「其实不是 bug」

| 现象 | 原因 |
| --- | --- |
| 某个音源搜不到、播放失败，其它音源正常 | 该音源服务端或上游接口的问题；先在它的原生网页界面验证 |
| 首次进入音乐库是空的 | 还没配置音乐库目录，或目录里没有音频文件；到 `设置 → 音乐库` 添加并扫描 |
| 歌词一直显示「无歌词」 | 本地歌词匹配依赖文件名与元数据；先确认同目录或内嵌是否有歌词，见 `docs/lyrics.md` |
| 翻译 / 歌词模型下载很慢或失败 | 走的是 GitHub Releases 的下载链路；网络受限时可换用离线包，见 `设置 → 组件` 与 `docs/local-components.md` |
| 更新检查没反应 | 自动检查约每小时一轮，失败会退避（30 分钟 → 1 小时 → 2 小时封顶）；可在 `设置 → 关于` 手动触发一次，不受节流 |
| 桌面启动后没有托盘图标 | 仅 Linux 桌面提供托盘与 MPRIS；Windows 无托盘、无 SMTC |
| 打包成 AppImage 后插件加载失败 | 见 `README.md` 已知限制里的 AppImage 段，需要带 bundle 内的 `lib/` 目录 |

## 响应时间

这是一个单人维护的项目，没有值班表。缺陷与需求会按影响面排序处理，功能讨论可能长期挂着——不回应不等于拒绝。

## 想自己先查

仓库里的文档比 issue 里可能出现的答案更全：

| 想查 | 看 |
| --- | --- |
| 产品范围、验收口径 | [`需求/README.md`](需求/README.md) |
| 代码结构、扩展路径、状态归属 | [`docs/architecture.md`](docs/architecture.md) |
| 跑测试、截图对比 | [`docs/verification.md`](docs/verification.md) |
| 自动更新与 `version.json` | [`docs/updates.md`](docs/updates.md)、[`docs/update-cdn.md`](docs/update-cdn.md) |
| 本地组件（翻译 / 歌词模型 / FFmpeg） | [`docs/local-components.md`](docs/local-components.md) |
| 全部文档地图 | [`AGENTS.md`](AGENTS.md) 开头的表格 |
