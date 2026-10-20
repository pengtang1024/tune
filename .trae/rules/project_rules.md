# 项目规则（唯一来源：根目录 AGENTS.md）

本工程的全部规则写在仓库根目录的 **`AGENTS.md`** 与 **`docs/`**。本文件只做入口，不复制条目——规则只维护一份，避免多处文档互相漂移。

## 速查

| 想知道 | 去读 |
| --- | --- |
| 改动的优先级与红线 | `AGENTS.md` §1 |
| 目录分层、依赖方向、状态归属 | `docs/architecture.md` |
| 加音源 / 加页面 | `docs/architecture.md` 的「扩展路径」 |
| 加文案 / 改文案 | `docs/i18n.md` |
| 日志、主题令牌、体积、注释、脚本目录 | `docs/conventions.md` |
| 提交前必须跑什么、测试怎么写 | `docs/verification.md` |
| 分支与提交信息 | `AGENTS.md` §3 |

## 本工具的补充

- 启动应用默认 `flutter run -d linux`（Linux 桌面是当前唯一主验收平台）。
- 复杂任务先用 MCP 把问题拆成步骤，再逐步执行。
- 改完必须跑 `flutter analyze` 与 `flutter test`，两者都干净才算完成。

## 已从本文件移除的条目（别再捡回来）

| 旧条目 | 现在在哪 / 为什么删 |
| --- | --- |
| 「ui 层代码放到 `lib/ui` 目录」 | `lib/ui` 已删除，新 UI 在 `lib/app` 与 `lib/features` |
| 日志级别含 `warn` | `Log`（`lib/utils/logger.dart`）只有 `debug` / `info` / `error`，见 `docs/conventions.md` |
| 「文件尽量不要超过 200 行」 | 见 `docs/conventions.md`，并注明哪些大文件不得继续膨胀 |
| 「所有 widget 都要有测试文件」 | 收敛为 `docs/verification.md`：新增逻辑必须有对应测试 |
| 「颜色/数字不要硬编码」 | 收敛为 `docs/conventions.md`：走 `CompactTokens` 与主题 |
| 本地化参数添加流程 | 见 `docs/i18n.md`，步骤更完整（含两个会抓硬编码文案的测试） |
