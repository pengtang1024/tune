# 自动更新

> 桌面端从发布页发现自己有新版本，下载并换掉正在运行的 bundle，重启后生效。

## 数据源

应用读 GitHub 的 release 接口：

```
GET https://api.github.com/repos/pengtang1024/tune/releases/latest
```

- `tag_name` 是版本号（`v1.4.0` 去掉 `v`），与 `AppVersion.version` 逐段比较。
- `assets` 里按平台挑一个归档：文件名包含 `linux` / `windows` / `macos` 的那个。
- 没有 release（404）时显示「已是最新版本」，不报错。

仓库必须是公开的：私有仓库的 release 接口需要令牌，应用不带令牌。

## 产物约定

每个平台的归档只放 bundle 的内容，不套外面一层目录：

| 平台 | 文件名 | 内容 |
| --- | --- | --- |
| Linux | `tune-linux-x64-<version>.tar.gz` | `tune`、`lib/`、`data/`、`share/` |
| Windows | `tune-windows-x64-<version>.zip` | 同上，`tune.exe` |
| macOS | `tune-macos-<version>.zip` | `.app` |
| Android | `tune-android-<version>.apk` | — |

Linux 用打包脚本生成：

```bash
flutter build linux --release
./tool/package_linux.sh            # 输出 dist/tune-linux-x64-<version>.tar.gz
```

## 发布步骤

1. 改 `pubspec.yaml` 与 `lib/config/app_version.dart` 的版本号。
2. 构建并打包（见上）。
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
- **Windows / macOS / Android**：只显示版本与「到发布页手动下载」，不做替换
  （运行中的可执行文件在 Windows 上无法覆盖）。
- **Web**：不显示更新卡片。

升级失败时旧 bundle 会换回来（新目录换入失败会先把备份还原），不会把应用
留在半装状态。下载与解压都在 UI 线程之外，进度只刷新卡片那一小块。

## 测试

- `test/services/update_service_test.dart`：版本比较（含 `1.9.9` → `1.10.0`
  与 `+build` 后缀）、release 解析、平台归档选择、临时目录里的安装替换。

## 限制

- 更新源固定为 GitHub 的公开 release；不读自建服务器的清单。
- 归档没有签名校验。需要更强保证时，后续可加 `sha256` 字段并拒绝不匹配的包。
- Android 的 APK 安装需要系统 Intent，桌面端尚未接入。
