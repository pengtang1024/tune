# 参与贡献

感谢你愿意花时间改进 Tune。这份文档说明这个项目的协作方式、验证门禁与提交流程。开始之前请先读 [`CODE_OF_CONDUCT.md`](CODE_OF_CONDUCT.md)——参与本项目即表示你同意遵守它。

- 使用问题、讨论与求助 → [`SUPPORT.md`](SUPPORT.md)
- 安全漏洞 → [`SECURITY.md`](SECURITY.md)（**不要**开公开 issue）
- 谁负责、怎么决策 → [`GOVERNANCE.md`](GOVERNANCE.md)
- 代码结构与设计依据 → [`AGENTS.md`](AGENTS.md)（工程文档地图）

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

四项都必须过，缺一不算完成：

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

只想验证确定性用例时，排除这两个文件即可：

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
