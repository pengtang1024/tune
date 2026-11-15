# 参与贡献

> 状态：入口 · 适用版本 1.32.0 · 最后核对 2026-11-15

感谢你愿意花时间改进 Tune。这份文档说明这个项目的协作方式、验证门禁与提交流程。开始之前请先读 [`CODE_OF_CONDUCT.md`](CODE_OF_CONDUCT.md)——参与本项目即表示你同意遵守它。

- 使用问题、讨论与求助 → [`SUPPORT.md`](SUPPORT.md)
- 安全漏洞 → [`SECURITY.md`](SECURITY.md)（**不要**开公开 issue）
- 谁负责、怎么决策 → [`GOVERNANCE.md`](GOVERNANCE.md)
- 代码结构与设计依据 → [`AGENTS.md`](AGENTS.md)（工程文档地图）

## 目录

- [项目是什么](#项目是什么)
- [开发环境](#开发环境)
- [分支模型](#分支模型)
- [提交前门禁](#提交前门禁)
- [提交信息](#提交信息)
- [拉取请求](#拉取请求)
- [文档](#文档)
- [新增依赖与素材](#新增依赖与素材)
- [改文案与本地化](#改文案与本地化)
- [代码约定](#代码约定)
- [提交之后](#提交之后)
- [关于节奏](#关于节奏)

## 项目是什么

Tune 是一款紧凑的本地与在线音乐播放器，使用 Flutter 开发，主要验收平台是 Linux 桌面。当前版本 `1.32.0+52`（代号 Pocket，2026-11-15）。

Windows / Android / iOS 保留工程入口，但不是 v1 验收目标；**macOS 与 Web 已不再支持**，平台工程入口与相关代码已移除。

## 开发环境

| 依赖 | 版本 / 说明 |
| --- | --- |
| Flutter | 3.x（`pubspec.yaml` 要求 Dart SDK `^3.8.1`；开发机实测 Flutter 3.47.7 / Dart 3.13.5 stable） |
| 系统库 | Linux 桌面播放依赖 libmpv（Ubuntu：`libmpv2`） |
| 构建工具 | `ninja-build`、`libgtk-3-dev`（Linux 桌面构建） |

```bash
git clone https://github.com/pengtang1024/tune.git
cd tune
flutter pub get
flutter run -d linux
```

若 `flutter` 不在 `PATH` 中，先把它加进去，例如 `export PATH="/opt/flutter/bin:$PATH"`。

> **工程路径含中文时**（例如放在 `~/文档/` 下），Flutter 3.47.x 的 `flutter analyze` 会因 SDK 自身的
> LSP 报文 bug 报 `FormatException: Unexpected end of input`。处理办法见
> [`docs/verification.md`](docs/verification.md) 的「门禁的前提：SDK 补丁」一节；临时兜底是 `dart analyze`。

## 分支模型

主开发分支是 **`develop`**，不是 `master`。`master` 只承接发版。

| 你要做的事 | 从哪切 | 提到哪 |
| --- | --- | --- |
| 新功能 | `develop` | `develop` |
| 修缺陷 | `develop` | `develop` |
| 文档 | `develop` | `develop` |
| 紧急修复 | `master` | `master` 与 `develop` 都要 |

分支名用简短的英文小写加连字符，表明意图，例如 `fix/mini-player-height`、`feat/source-health-score`。

**不要** force push 到 `main` / `master`，也不要直接往这两个分支推提交。

## 提交前门禁

一条命令跑完静态检查与确定性用例：

```bash
./tool/check.sh                  # analyze + 全部确定性用例
./tool/check.sh --l10n            # 另外断言 lib/l10n 生成产物已提交
./tool/check.sh --l10n --tools --docs   # 再加截图探针与文档结构检查（CI 跑的就是这条）
./tool/check.sh --live            # 连联网用例一起跑，失败先怀疑网络
```

它依次做 `flutter gen-l10n`（仅 `--l10n`）→ `flutter analyze` → `flutter test` → `flutter test tool/…`（仅 `--tools`）→ `tool/check_docs.py`（仅 `--docs`）。CI 跑的是同一份脚本（`./tool/check.sh --l10n --tools --docs`），所以本地绿等于 CI 绿——前提是你的 Flutter 版本与 `.github/workflows/ci.yml` 里钉住的一致。首次克隆先 `flutter pub get`；`flutter` 不在 PATH 时用 `FLUTTER=/opt/flutter/bin/flutter ./tool/check.sh`。

分步等价命令（脚本里做的就是这些）：

```bash
flutter pub get
flutter analyze          # 必须 No issues found
flutter test             # 全绿
flutter gen-l10n         # 改过 ARB 文案才需要，且要提交生成产物
```

细节与测试布局见 [`docs/verification.md`](docs/verification.md)。

### 关于联网测试

`test/services/music_source_e2e_live_test.dart` 与 `test/services/music_source_live_test.dart` 会访问**真实的外部服务**。这两个文件里的用例带 `skip: online ? false : offline`，在没有网络的机器上会被跳过；有网络但外部服务返回 404 或超时时，它们会失败——这属于服务侧问题，不是你的改动引起的。

排查工具：

```bash
./tool/live_sources.sh   # 串行跑这两个文件并打印各自结果
```

只想验证确定性用例时，`./tool/check.sh` 默认就会跳过这两个文件；要手写等价命令是：

```bash
flutter test $(find test -name '*_test.dart' ! -name '*live*' | sort)
```

### 界面改动

改了布局或样式，跑一次截图对比工具，和改动前的 PNG 比一比比读代码更快发现布局问题：

```bash
flutter test tool/layout_shots_test.dart   # 写 PNG 到 build/layout-shots/
```

`tool/` 下的截图工具不属于常规测试套件，`flutter test` 不会跑到它们。

## 提交信息

格式固定为：

```text
type(scope): 中文说明
```

- `type` ∈ `feat` / `fix` / `refactor` / `docs` / `chore` / `perf`
- `scope` 是受影响的模块，例如 `shell`、`scanner`、`update`、`library`、`lyrics`
- 说明用中文，写「做了什么」，不写「改了哪些文件」

真实例子（取自本仓库历史）：

```text
fix(shell): mini 还原时按窗口可用尺寸换排布
refactor(update): 自动检查改为每小时一轮，退避封顶两小时
feat(library): 隐藏零时长曲目并在工具条说明，极短轨改为可选筛选
docs(wiki): 同步 1.32.0 文档更新
```

一次提交只做一件事。把无关的格式化、重构或重命名混进功能提交，会让 review 与回滚都变难。

## 拉取请求

1. 从 `develop` 切出分支，改完跑完门禁。
2. 精确提交你要提交的文件——**不要用 `git add .`**。
3. 向 `develop` 提 PR，按 `.github/PULL_REQUEST_TEMPLATE.md` 填完自检清单。
4. UI 改动附截图；行为改动说明你怎么验证的。
5. 文档与代码一起改：`AGENTS.md` 的文档地图列出每类改动该同步哪份文档。

PR 描述里请写清「为什么」。这个项目的设计文档（`docs/`、`需求/`）记录了每项决定的原因，纯代码 diff 往往看不出动机。

## 文档

改文档前先读 [`docs/document-style.md`](docs/document-style.md)：每页唯一 H1、H1 下状态行、长页目录、代码块标语言、末尾相关文档。`./tool/check.sh --docs` 会检查这些，CI 也跑同一份检查。

文档不是附属品：这个项目的多数设计决定只写在 `docs/` 与 `需求/` 里，纯代码 diff 看不出动机。改行为时按下面三处同步。

- **入口**：[`AGENTS.md`](AGENTS.md) 的文档地图。新增、改名或删除一份文档，就要在那里加/改一行——地图里没有的文档会被当成历史稿。
- **索引**：[`docs/README.md`](docs/README.md) 记录每份设计文档的**状态**（契约 / 规范 / 已实施 / 方案 / 快照）。新文档要在那里登记；状态变了要回去改，否则别人无法判断它还算不算依据。
- **双语 README**：[`README.md`](README.md) 与 [`README_en.md`](README_en.md) 是同一份内容的两个语言版本，章节与条目一一对应。改一面就改另一面，只改一边会让另一种语言的读者读到过期信息。

其他约定：

- 面向用户的变化写进 [`CHANGELOG.md`](CHANGELOG.md) 的当前版本段，按现有分类走：**新增 / 变更 / 修复 / 移除**，必要时加 **性能 / 文档 / 依赖 / 工具 / 迁移 / 许可证 / 说明**。只写用户能感知的变化，内部重构不必逐条列。
- 版本号三处必须一致：`pubspec.yaml` 的 `version`、`lib/config/app_version.dart`、仓库根的 `version.json`。
- 新增设计说明写进 `docs/`（不要散在仓库根），文件名 kebab-case，首段写清状态与日期。
- 面向用户「用不了」的排障写进 [`docs/troubleshooting.md`](docs/troubleshooting.md)，不要混进设计文档。
- 动了界面就去更新截图：跑 `flutter test tool/layout_shots_test.dart`，把 `build/layout-shots/library.png` 与 `library_albums.png` 覆盖到 [`docs/images/`](docs/images/)——两份 README 引用的就是这两张。

## 新增依赖与素材

引入第三方依赖、字体或素材之前先看 [`docs/licensing.md`](docs/licensing.md)：

- GPL / AGPL / SSPL / BUSL / Commons Clause **不得**进入 Tune 自有代码或默认安装包。
- GPL 二进制只允许作为**独立组件归档**分发，并且必须同时提供许可证全文、对应源码与构建配置。
- 新增依赖后同步更新 `THIRD_PARTY_NOTICES.md` 与 `docs/licensing.md` 的表格。
- 引入第三方图标 / 字体 / 截图 / 示例音频，先在 `docs/licensing.md` §4 登记来源与授权。

## 改文案与本地化

界面语言有四种：简体中文、繁體中文、中文（通用）、English。ARB 源文件在 `lib/l10n/`，生成产物 `lib/l10n/app_localizations*.dart` **随仓库入库**。

```bash
flutter gen-l10n   # 改完 ARB 必须跑，并把生成产物一起提交
```

`test/app/localization_test.dart` 与 `localization_render_test.dart` 会扫源码与渲染树，抓硬编码文案、跨语言漏出与超长标签。新增专有名词或格式名，要加进 `test/app/localization_words.dart` 的白名单。

规则见 [`docs/i18n.md`](docs/i18n.md)。

## 代码约定

写代码前先读 [`docs/conventions.md`](docs/conventions.md) 与 [`AGENTS.md`](AGENTS.md) 的架构规则。最容易踩的几条：

- **依赖方向单向**：`presentation → application → domain / data`；`data/`、`domain/` 不反向依赖 `features/`。
- **一份状态只有一个主人**：同一个业务状态不在两个 provider 或两个 service 里各存一份。
- **颜色与尺寸走 token**：颜色用 `Theme.of(context)` 或 `CompactTheme`，间距圆角用 `CompactTokens`，不写裸色值与魔法数。
- **日志用 `Log`**：不带 `--dart-define=DEBUG=true` 的构建会把 `Log.debug` 编译掉，所以要在用户机器上留痕的排障日志一律用 `Log.info`。不用 `print`。
- **不吞异常**：捕获后必须重抛、记录或恢复，禁止空 catch。

## 提交之后

你提交即表示你的贡献按 [MIT License](LICENSE) 授权。本项目不使用 CLA（贡献者许可协议），也不要求签署 DCO 声明——但你需要在 PR 自检清单里确认「改动为我原创或来自许可兼容的来源」。

## 关于节奏

这是一个单人维护的项目（见 [`GOVERNANCE.md`](GOVERNANCE.md)），review 与合并没有固定时限。PR 长时间没有回应时，礼貌地在 PR 下追加一条评论即可，不需要另开 issue 催。

## 相关文档

- [文档地图](AGENTS.md) — 每类改动该读哪份文档
- [架构](docs/architecture.md) — 分层、状态归属与依赖方向
- [验证](docs/verification.md) — 门禁细节与测试布局
- [行为准则](CODE_OF_CONDUCT.md) — 参与前需遵守的规范
- [治理](GOVERNANCE.md) — 谁负责合并与怎么决策
