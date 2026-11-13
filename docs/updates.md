# 自动更新

> 桌面端从发布页发现自己有新版本，下载并换掉正在运行的 bundle，重启后生效。

## 数据源

应用读 GitHub 的 release 接口：

```
GET https://api.github.com/repos/pengtang1024/tune/releases/latest
```

- `tag_name` 是版本号（`v1.4.0` 去掉 `v`），与 `AppVersion.version` 逐段比较。
- `assets` 里按平台挑一个归档：文件名包含 `linux` / `windows` / `android` 的那个。
- 没有 release（404）时显示「已是最新版本」，不报错。

仓库必须是公开的：私有仓库的 release 接口需要令牌，应用不带令牌。

## 产物约定

每个平台的归档只放 bundle 的内容，不套外面一层目录：

| 平台 | 文件名 | 内容 |
| --- | --- | --- |
| Linux | `tune-linux-x64-<version>.tar.gz` | `tune`、`lib/`、`data/`、`share/`、`translation/` |
| Windows | `tune-windows-x64-<version>.zip` | `tune.exe` 及其依赖目录（不含 `translation/`，v1 未做 Windows 离线模型打包） |
| Android | `tune-android-<version>.apk` | — |

`translation/` 是离线翻译的 sidecar：模型（约 469 MiB）、llama.cpp 运行时
（解包后约 57 MiB）与两份许可证。它们由 `tool/prepare_translation.sh` 从仓库的
Git LFS 工作区校验后直接追加进归档，不复制第二份。

Linux 用打包脚本生成：

```bash
flutter build linux --release
./tool/package_linux.sh            # 输出 dist/tune-linux-x64-<version>.tar.gz
```

打包前脚本会先跑 `tool/prepare_translation.sh`：确认 `git-lfs` 存在、两个 LFS
文件已拉取（不是 130 B 指针）、大小与 sha256 匹配、运行时能解包出可执行的
`llama-cli`。任何一步失败都会直接退出，不会产出缺模型的包。

## 发布步骤

1. 改 `pubspec.yaml` 与 `lib/config/app_version.dart` 的版本号。
2. `git lfs install && git lfs pull`，再构建并打包（见上）。
3. 提交、打 tag：`git tag -a v1.4.1 -m "v1.4.1"`，推送 tag。
4. 在 GitHub（与 Gitea）创建同名 release，把归档作为附件上传。
5. 老版本的应用点「检查更新」就能看到并安装。

Gitea 的仓库是私有的，release 接口要令牌，应用不带令牌——所以更新检查
统一走公开的 GitHub；Gitea 的 release 只作为自己人的人工下载入口。

## 从旧版本升级一次

「检查更新」是 1.5.0 才加进去的，更早的版本里没有这段代码，所以它们无法自己
发现新版本。装过一次 1.5.0 之后就不用再管：

```bash
# 默认升级 ~/.local/opt/tune，旧版本备份为 tune.previous
./tool/upgrade_local.sh
# 升级后重启应用
./tool/upgrade_local.sh ~/.local/opt/tune --restart
```

脚本从 GitHub 的 latest release 下载 Linux 归档，解压前先备份；新包不完整时
会把备份换回来。

## 安装行为

- **Linux**：归档下载到临时目录，解压到 bundle 同级的 `.tune-update`，再把
  旧 bundle 换成 `.tune-previous`、新目录换入原位；旧目录随后删除。完成后
  提示「重启后生效」，按钮直接启动新进程并结束旧进程。
  归档是整包替换，`translation/` 里的模型与运行时也会一起换成新版本；更新协议
  不需要额外字段。
- **Windows / Android**：只显示版本与「到发布页手动下载」，不做替换
  （运行中的可执行文件在 Windows 上无法覆盖）。

升级失败时旧 bundle 会换回来（新目录换入失败会先把备份还原），不会把应用
留在半装状态。下载与解压都在 UI 线程之外，进度只刷新卡片那一小块。

## 测试

- `test/services/update_service_test.dart`：版本比较（含 `1.9.9` → `1.10.0`
  与 `+build` 后缀）、release 解析、平台归档选择、临时目录里的安装替换。

## 限制

- 更新源固定为 GitHub 的公开 release；不读自建服务器的清单。
- 归档没有签名校验。需要更强保证时，后续可加 `sha256` 字段并拒绝不匹配的包。
- Android 的 APK 安装需要系统 Intent，桌面端尚未接入。
- Linux 归档从约 41 MiB 增大到约 515 MiB（含模型与运行时），更新下载量与
  GitHub Release 附件上限都要按这个量级预留。
- 源码仓库用 Git LFS 存模型与运行时归档：普通 clone 只有指针，装好 LFS 后
  clone/pull 会额外拉约 515 MB。GitHub 免费 LFS 配额是 1 GB 存储 / 1 GB 月流量，
  发布前先确认余量；上传受限时改用 release 附件分发，另行确认。
