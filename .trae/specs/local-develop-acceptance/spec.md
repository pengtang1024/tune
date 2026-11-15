# 本机 develop 安装验收（更新链路日志轮）

## 目标

把本机安装更新到包含「调度间隔调整」提交之后的 `develop`，实测本轮更新链路与日志改动：
清单取数日志在 release 包中可见、扫描日志不再按文件刷屏、设置页三功能项与五类内容作用域正常、
两种形态尺寸正常。

## 前置条件（当前阻塞）

- 等待 `develop` 出现 `3306e2d` 之后的调度间隔调整提交。
- 实测确认：`origin`（gitea）、`gitee`、`github` 三处 `develop` 均为 `3306e2d`。
- 规则：提交未出现前不构建，不在树中间编译。

## 步骤

1. `git fetch` 后取 `origin/develop`，构建 `flutter build linux --release`（单个工作树，避免并发构建）。
2. 备份 `~/.local/opt/tune` 为 `tune.1.32.0.bak-<日期>-<时分>`，`cp -a build/linux/x64/release/bundle/. ~/.local/opt/tune/`。
3. 用构建提交 + `libapp.so` 的 sha256 前 16 位作为「实际构建提交」证据（`version.json` 仍是 1.32.0+52，不作依据）。
4. 用户数据不动：`~/.local/share/cn.iouf.tune` 只读复制到 `/tmp/tune-acceptance-data/cn.iouf.tune`，
   以 `XDG_DATA_HOME=/tmp/tune-acceptance-data` 启动安装包，stdout/stderr 落 `/tmp/tune-acceptance.log`。
5. 等待 ≥ 90s（启动扫描 + `UpdateScheduler.firstDelay = 60s`），检日志。
6. 截图：设置→本地组件三功能项、五类内容作用域、正常与 mini 两形态。
   真实窗口截图：启动后立即 `agkit shot --app Tune`（新窗口在最上层）；若被遮挡，
   交互动作用临时工作树内的测试内渲染（`OffsetLayer.toImage`）补，并在报告中注明出处。

## 验收判据

| 项 | 判据 |
| --- | --- |
| 构建提交 | `git rev-parse HEAD` + `sha256sum libapp.so` 与安装目录一致 |
| 检查更新日志 | 日志中恰有两条 `清单 <host>：…`（jsDelivr 与 raw 各一条），带耗时；无逐请求刷屏 |
| 扫描日志 | 有 `Scanning N directories` / `Scan finished: …` 汇总；`Scanning single file` 计数为 0 |
| 设置页 | 本地组件三张卡（翻译 / 智能歌词 / 音频转码），各带说明、体积、推荐标记 |
| 内容作用域 | 页头内容菜单五类：音乐 / 播客 / 有声书 / 电台 / 音效 |
| 形态 | 正常窗口约 1070×815；mini 360×88 |

## 非目标

- 不改产品代码（本轮只验收）。
- 不动真实用户数据、不清理旧备份。
