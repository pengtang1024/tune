# 任务清单

## T1 等待目标提交（阻塞中）
- `git fetch origin develop`，确认头提交不是 `3306e2d`。
- 记录提交号与提交标题。

## T2 release 构建
- 在 `/home/pt/Work/IdeaProjects/tune` 执行 `flutter build linux --release`。
- 记录 `build/linux/x64/release/bundle` 体积与 `libapp.so` sha256。

## T3 备份并安装
- `mv ~/.local/opt/tune ~/.local/opt/tune.1.32.0.bak-<日期>-<时分>`。
- `cp -a bundle/. ~/.local/opt/tune/`；核对两份 `libapp.so` sha256 一致。

## T4 用 /tmp 副本启动
- 停掉现有 `tune` 进程；`cp -a ~/.local/share/cn.iouf.tune /tmp/tune-acceptance-data/`。
- `XDG_DATA_HOME=/tmp/tune-acceptance-data setsid ~/.local/opt/tune/tune >/tmp/tune-acceptance.log 2>&1`。
- 等待 ≥ 90s。

## T5 日志取证
- `grep "清单 " /tmp/tune-acceptance.log`：贴两行原文（主机、结果、耗时）。
- 统计条数，确认没有按请求刷屏。
- `grep -c "Scanning single file"` 必须为 0；列出 `Scanning`/`Scan finished` 行。

## T6 截图
- 设置 → 本地组件（三张卡，含说明/体积/推荐）。
- 页头内容作用域菜单（五类）。
- 正常窗口与 mini 形态各一张，记录像素尺寸。

## T7 汇报
- 提交号、安装体积、sha256、四项结论与截图路径、报错原文、需用户手工做的事。
- 用户数据保持未改动（只读复制）。
