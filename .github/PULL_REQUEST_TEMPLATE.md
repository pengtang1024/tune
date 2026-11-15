<!--
感谢你的贡献。

提交前请先读 CONTRIBUTING.md 与 AGENTS.md（工程规范与文档地图）。
标题格式：type(scope): 中文说明，type ∈ feat / fix / refactor / docs / chore / perf。
一次 PR 只做一件事；改哪块就只动哪块，不要顺带重构无关代码。
-->

## 变更说明

<!-- 说清「改了什么」和「为什么改」。一句话能说清就一句话。 -->

## 关联 issue

<!-- 例如：Closes #123。没有关联 issue 就写「无」。 -->

## 变更类型

<!-- 勾选一项。与提交信息的 type 保持一致。 -->

- [ ] 新增（feat）
- [ ] 修复（fix）
- [ ] 重构（refactor）
- [ ] 文档（docs）
- [ ] 性能（perf）
- [ ] 依赖（deps）
- [ ] 工具（chore）

## 自检清单

- [ ] `./tool/check.sh --l10n --tools --docs` 全绿（CI 跑的就是这条：gen-l10n 一致性 + `flutter analyze` + 确定性用例 + 截图探针 + 文档结构）
- [ ] 改过 `lib/l10n/*.arb` 的，生成产物已一并提交（`lib/l10n/app_localizations*.dart` 是入库文件，不是构建垃圾）
- [ ] 没有提交任何密钥、凭据或 token（包括日志、截图、示例配置里的）
- [ ] 改动范围最小，没有顺带重构无关代码
- [ ] 文档已同步：对照 `AGENTS.md` 顶部的「文档地图」改掉了受影响的文档
- [ ] UI 改动附了截图，或说明跑过 `flutter test tool/layout_shots_test.dart`（产物写到 `build/layout-shots/`）

> **联网测试说明（别误判成自己改坏了）**
>
> `test/services/music_source_live_test.dart` 与
> `test/services/music_source_e2e_live_test.dart` 访问真实外部服务，依赖网络与对方站点。
> 它们失败**很可能是网络问题或对方服务的问题**，与本次改动无关；文件里用
> `skip: online ? false : offline` 控制，机器没网时会被跳过。
>
> 排查用 `./tool/live_sources.sh`：它把这两个文件**串行**跑（不与其余用例并发），
> 再打印各自结果；单独跑仍失败时，先用一次请求量一下服务状态再判断。
>
> `./tool/check.sh` 默认就排除这两个文件（CI 同样排除）；要连它们一起跑用
> `./tool/check.sh --live`，或直接 `flutter test` 全量。

## 验证证据

<!-- 贴证据，不要只写「已测试」：
     - ./tool/check.sh --l10n --tools --docs 的结论（all gates passed，或哪一步红了）
     - flutter test 的结果（通过数 / 失败数；跑的是哪条命令）
     - 关键日志、截图路径或录屏
     没跑的项目写「未验证」并说明原因，不要留空冒充通过。 -->

## 截图

<!-- 只有 UI 改动需要。拖入改动前后的截图（或写明 build/layout-shots/ 下的文件名）。
     纯逻辑 / 文档改动可以删掉本节。 -->
