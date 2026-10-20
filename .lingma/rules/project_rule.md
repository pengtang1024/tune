# 项目规则（唯一来源：根目录 AGENTS.md）

本工程的全部规则写在仓库根目录的 **`AGENTS.md`** 与 **`docs/`**。本文件只做入口，不复制条目——规则只维护一份，避免多处文档互相漂移。

## 读取顺序

1. `AGENTS.md` —— 先读完再动手。它是**文档地图**：一页讲清优先级与红线，其余细节按需跳读。
   - §1 架构优化优先于代码优化（动手顺序、禁止项、三问自检）—— 每次都读
   - §2 验证门禁 · §3 Git 约定 · §4 不在当前范围
2. 按要做的事查 `docs/`：
   - `docs/architecture.md` —— 目录分层、依赖方向、状态归属、扩展路径
   - `docs/i18n.md` —— 文案流程、专有名词、数字格式
   - `docs/conventions.md` —— 日志、主题令牌、体积、注释、平台差异、脚本目录
   - `docs/verification.md` —— 测试布局、替身写法、门禁、截图对比
3. 相关代码 —— 以代码为准；代码与文档冲突时修正文档，不要在别处另立规则。

## 本工具的补充

- 复杂任务先用 MCP 把问题拆成步骤，再逐步执行。
- 需要对同一批文件做多轮正则／条件补丁时，优先用代码执行工具一次性完成，不要串一长串终端命令。

## 已从本文件移除的条目（别再捡回来）

| 旧条目 | 现在在哪 / 为什么删 |
| --- | --- |
| `states` / `providers` / `widgets` 三目录约定 | 已改为 `features/<f>/{domain,application,data,presentation}`，见 `docs/architecture.md` |
| 用 `addPostFrameCallback` 延迟更新 provider 状态 | 与 `AGENTS.md` §1.2 冲突，属于用延迟掩盖状态同步问题，禁止 |
| 「ui 层代码放到 `lib/ui` 目录」 | `lib/ui` 已删除，新 UI 在 `lib/app` 与 `lib/features` |
| 日志级别含 `warn` | `Log`（`lib/utils/logger.dart`）只有 `debug` / `info` / `error`，见 `docs/conventions.md` |
| 文件 ≤200 行、函数 ≤50 行 | 见 `docs/conventions.md`，并注明哪些大文件不得继续膨胀 |
| 本地化参数添加流程 | 见 `docs/i18n.md`，步骤更完整（含两个会抓硬编码文案的测试） |
