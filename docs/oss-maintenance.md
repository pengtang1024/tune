# 开源基建与维护清单

> 状态：设计（已实施） · 适用版本 1.32.0 · 最后核对 2026-11-15
>
> **它是维护清单，不是产品规范。** 这份文档回答两件事：仓库里那些「不是代码、也不是设计文档」的文件各自管什么；哪些东西改了必须同步到别处，否则会悄悄漂掉。
> 与实际的平台设置冲突时，以平台为准，并回来改这一页。

## 1. 根级文件

| 文件 | 管什么 | 什么时候要动 |
| --- | --- | --- |
| [`README.md`](../README.md) / [`README_en.md`](../README_en.md) | 项目介绍、安装、构建、界面图、已知限制、贡献入口 | 功能有增减、版本号变、界面图过期、平台支持范围变化 |
| [`CONTRIBUTING.md`](../CONTRIBUTING.md) | 怎么搭环境、门禁、分支与提交、PR、依赖与素材边界、文档同步规则 | 门禁命令变了、分支模型变了、新增素材要求 |
| [`CODE_OF_CONDUCT.md`](../CODE_OF_CONDUCT.md) | Contributor Covenant 2.1 + 中文处置流程 | 联系方式变了、处置流程变了 |
| [`SECURITY.md`](../SECURITY.md) | 支持范围、报告渠道、已如实披露的三条设计边界 | 版本线前进、更新链签名落地（届时「无签名」这条要删） |
| [`SUPPORT.md`](../SUPPORT.md) | 该走哪个渠道、提缺陷前要做什么 | 渠道增减（例如开了 Discussions，就要从这里和 `config.yml` 一起改） |
| [`GOVERNANCE.md`](../GOVERNANCE.md) | 谁负责、怎么决策、三端仓库与平台差异 | 维护者变化、平台限制变化 |
| [`AUTHORS.md`](../AUTHORS.md) | 作者与贡献者署名规则 | 有新的外部贡献者 |
| [`CITATION.cff`](../CITATION.cff) | 引用信息（CFF 1.2.0） | **每次发版**：`version` 与 `date-released` 必须跟 tag 对齐 |
| [`CHANGELOG.md`](../CHANGELOG.md) | 已发布版本的产品变更 | 每个版本发布时；分类用「新增 / 变更 / 修复 / 移除」 |
| [`LICENSE`](../LICENSE) | MIT | 不变（改协议是大事，需在 README 与 `CITATION.cff` 同步） |
| [`THIRD_PARTY_NOTICES.md`](../THIRD_PARTY_NOTICES.md) | 第三方组件与素材的声明 | 新增依赖、字体、模型、图标 |
| `.editorconfig` / `.gitignore` / `.gitattributes` / `.mailmap` | 编码与行尾、忽略项、生成物标记、提交者归一 | 新增生成产物、新增二进制、新增署名 | 
| `analysis_options.yaml` / `l10n.yaml` / `pubspec.yaml` | 静态检查、本地化生成、依赖与版本 | 见各自的文档（`docs/conventions.md`、`docs/i18n.md`） |

`.gitattributes` 目前只写 `* text=auto`，**故意不写 `eol=lf`**：仓库里有历史文件是 CRLF，强制重写会让一整批文件变成「全文件改动」，掩盖真正的 diff。

## 2. `.github/`

| 路径 | 管什么 | 维护点 |
| --- | --- | --- |
| `workflows/ci.yml` | 唯一的 CI：`bash ./tool/check.sh --l10n --tools --docs` | Flutter 版本**钉死**；升级时改版本号、本地复跑门禁、提交 l10n 产物 |
| `PULL_REQUEST_TEMPLATE.md` | PR 自检清单 | 门禁或文档同步规则变了 |
| `ISSUE_TEMPLATE/bug_report.yml` · `feature_request.yml` · `question.yml` | 三类 issue 表单 | `SUPPORT.md` 的渠道表必须与这里一一对应 |
| `ISSUE_TEMPLATE/config.yml` | 关掉空白 issue、给外部链接 | 新增外部渠道时 |
| `dependabot.yml` | pub 与 github-actions 每周一并一组 | 依赖策略变了 |
| `release.yml` | Release Notes 的分组规则（按 label） | 新增 label 或改分类名时（分类名要与 `CHANGELOG.md` 一致） |
| `CODEOWNERS` | 默认负责人 | 维护者变化 |
| `FUNDING.yml` | 赞助入口 | 目前是纯注释：没有赞助渠道就不写假键 |

`tool/tooltip_shots_test.dart` 不进门禁：它对比的基准图在 `build/tooltip-shots/`（不入库），干净检出上必然失败。要看得先 `flutter test tool/tooltip_shots_test.dart --update-goldens` 生成本地基准，再目检。

## 3. 三端平台元数据

三端（GitHub 主仓 / Gitee 镜像 / Gitea 私有 origin）的元数据必须一致，否则读者在不同镜像上看到两个项目。

| 字段 | 值 | 设置方式 |
| --- | --- | --- |
| description | `Tune 是一款紧凑的本地与在线音乐播放器，使用 Flutter 开发。` | GitHub `PATCH /repos/…` · Gitea `PATCH /api/v1/repos/…`（`description`）· Gitee `PATCH /api/v5/repos/…`（form-urlencoded，**必填 `name=tune`**） |
| homepage / website | `https://github.com/pengtang1024/tune` | 同上（Gitea 字段名是 `website`） |
| topics / 项目标签 | `flutter, dart, music-player, linux-desktop, riverpod, just-audio, go-router, sqlite, mpris, smart-lyrics` | GitHub `PUT /repos/…/topics`（`{"names":[…]}`）· Gitea `PUT /api/v1/repos/…/topics`（`{"topics":[…]}`）· Gitee `PUT /api/v5/repos/…/project_labels`（**裸数组**） |
| issue 标签 | GitHub 12 个；Gitea 10 个；Gitee 11 个 | GitHub 自带 · Gitea `POST /api/v1/repos/…/labels` · Gitee `POST /api/v5/repos/…/labels` |
| wiki | 三端同一份，由主仓 `wiki/` 生成 | `git push` 到各自的 `<repo>.wiki.git` |
| 私密漏洞通报 | GitHub 已开启 | `PUT /repos/…/private-vulnerability-reporting` |

几个平台坑（都不是配置疏漏）：

- **Gitee 的 label 名不允许空格**，只能 `good-first-issue` / `help-wanted`；GitHub 上是带空格的写法。三个平台的标签名因此不完全一致。
- **Gitee 的 `PATCH` 会校验 `name`**，漏了就 400 `name is missing`。
- **Gitea 不认语义标签**（`good first issue` 不会触发任何行为）。
- **GitHub 的 wiki 没有 REST/GraphQL API**：`<repo>.wiki.git` 在网页上建出第一页之前**根本不存在**，`git push` 会报 `Repository not found`。三端 wiki 因此都走 git push；GitHub 那端只有在 wiki 仓尚未初始化时才需要网页操作一次。
- 仓库的 **social preview 图**只能网页手动上传，API 不提供。

## 4. 改了就要同步的六条线

1. **改界面** → 跑 `flutter test tool/layout_shots_test.dart`，把 `docs/images/library.png` 与 `library-albums.png` 覆盖掉，否则 README 上的图和产品对不上。
2. **改 `wiki/`** → 重建页面集并推到三端（Gitee/Gitea 走 HTTPS，GitHub 走 SSH），推完 `git ls-remote` 复核 HEAD。远端副本要把三斜杠的 file 绝对链接转成行内代码，把 `](../path)` 转成 GitHub blob 链接。
3. **加 / 改 issue 标签** → 三端同步，且 Gitee 侧注意空格限制；`release.yml` 用到的 label 必须真实存在。
4. **发版** → tag `vX.Y.Z` · `version.json`（`version` / `build` / `size` / `sha256` / `released_at`）· `pubspec.yaml` 与 `lib/config/app_version.dart` · `CHANGELOG.md` · `CITATION.cff` 的 `version` 与 `date-released` · Release Notes（点 Generate，按 `release.yml` 分组）。
5. **改门禁** → 只改 `tool/check.sh` 一处，CI 调的是同一份脚本；改完同步 `CONTRIBUTING.md`、`AGENTS.md` §2、`README` 两份、`docs/verification.md`、`docs/document-style.md`。
6. **加文档** → 在 [`docs/README.md`](README.md) 登记 + `AGENTS.md` 文档地图加行 + 两份 README 的文档表一一对应。

## 5. 已知未做（不是遗漏，是待定）

| 项 | 为什么没做 |
| --- | --- |
| Release 自动构建产物 | 需要签名密钥与仓库 secrets，且产物要跑 Linux GTK + libmpv 构建；属维护者决策 |
| 更新清单签名（Ed25519） | 方案已在 [`update-cdn.md`](update-cdn.md) §7 定好，排第二阶段；现在靠 size + sha256 + 三档地址交叉核对 |
| GitHub Discussions | 故意不开：单人维护盯不住两个渠道，解题见 `GOVERNANCE.md` |
| social preview 图 | 只有网页入口，需要人工传一张 1280×640 |
| 提交信息规范化检查 | 提交是中文 `type(scope): 说明`，没有 CI 校验；靠 review 与 `CHANGELOG` 人工对齐 |

## 6. 一键核对

```bash
# 门禁（含截图探针）
./tool/check.sh --l10n --tools --docs

# YAML / CFF 语法
python3 -c "import yaml,glob,sys; [yaml.safe_load(open(p)) for p in glob.glob('.github/**/*.yml', recursive=True) + ['CITATION.cff']]; print('yaml ok')"

# 文档链接与表格（相对链接必须存在、表格列数必须一致）
# 详见 docs/verification.md；批量改动后用现成脚本扫一遍
```

## 相关文档

- [自动更新](updates.md) — 发版时要一起改的那串版本号
- [更新清单与 CDN](update-cdn.md) — `version.json` 的字段与自检
- [测试与验证](verification.md) — 门禁脚本与文档检查
- [许可证与第三方声明](licensing.md) — 新增素材时的声明义务
