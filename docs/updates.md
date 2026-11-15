# 自动更新

> 桌面端从静态清单发现自己有新版本，下载并换掉正在运行的 bundle，重启后生效。

## 数据源

应用先读仓库根目录的静态清单 `version.json`，由 CDN 分发：

1. `https://cdn.jsdelivr.net/gh/pengtang1024/tune@master/version.json`
   （分支地址；`@latest` 会因仓库超过 jsDelivr 的 50 MB 包上限被拒）
2. `https://raw.githubusercontent.com/pengtang1024/tune/master/version.json`
3. 前两档都拿不到时，才读 GitHub 的 release 接口（有 token 挂 Bearer，没有就匿名）

两份清单都拿到时会交叉核对，不一致直接拒绝本次更新。清单字段、调度、退避与
失败分类见 [update-cdn.md](update-cdn.md)。

- `version` 与 `build` 逐段比较；`+build` 只在版本相等时打破平局。
- `assets` 按平台键挑归档（`linux-x64` 等）；第 3 档按文件名包含平台名挑，
  带 `-offline` 后缀的维护者离线包会被跳过。
- 清单与发布页都没有 release 时显示「已是最新版本」，不报错。
- 下载后核对 `size` 与 `sha256`，不符就删掉临时文件并报失败，不进入安装。

## 产物约定

每个平台的归档只放 bundle 的内容，不套外面一层目录：

| 平台 | 文件名 | 内容 |
| --- | --- | --- |
| Linux | `tune-linux-x64-<version>.tar.gz` | `tune`、`lib/`、`data/`、`share/` |
| Windows | `tune-windows-x64-<version>.zip` | `tune.exe` 及其依赖目录 |
| Android | `tune-android-<version>.apk` | — |

本地翻译模型不再随平台包分发。模型、llama.cpp 运行时与许可证打成一个可选组件包
`tune-translation-qwen2.5-0.5b-b12274.zip`（约 500 MB），单独作为 Release 附件
发布；应用在设置页按需下载，元数据见 `translation/manifest.json`。组件包文件名以
`tune-translation-` 开头，不含平台名，因此不会被自动更新选中。
1.32.0 起本地能力已收敛为统一组件注册表（[local-components.md](local-components.md)）：
这个 zip 是「离线打包用的翻译组件」，不再是唯一的本地组件；在线用户由设置页按需下载各组件。

Linux 用打包脚本生成：

```bash
flutter build linux --release
./tool/package_linux.sh            # 输出 dist/tune-linux-x64-<version>.tar.gz 与 dist/version.json
```

打包脚本随后调用 `tool/write_version_manifest.dart`，用 `pubspec.yaml` 与 CHANGELOG
生成 `dist/version.json`（含归档实测的 `size` 与 `sha256`）。维护者需要给没有网络的
机器做本地/内网分发时，用离线包：

```bash
./tool/package_linux.sh --offline  # 输出 dist/tune-linux-x64-<version>-offline.tar.gz
```

离线包会先跑 `tool/prepare_translation.sh`（确认组件包已解压到 `translation/`、
文件大小与 sha256 匹配、运行时能解包出可执行的 `llama-cli`），再追加
`translation/models/*.gguf`、`translation/bin/llama-b12274` 与 `translation/licenses`。
任何一步失败都会直接退出，不会产出缺模型的离线包。离线包不作为更新附件发布。

## 发布步骤

1. 改 `pubspec.yaml` 与 `lib/config/app_version.dart` 的版本号，写 CHANGELOG。
2. 构建并打包平台归档（见上）；离线包需要先把组件包解压到 `translation/`。
3. 把 `dist/version.json` 复制到仓库根 `version.json`（`--root` 参数会直接写）。
4. 提交、打 tag：`git tag -a v1.4.1 -m "v1.4.1"`，推送 tag。
5. 在 GitHub（与 Gitea）创建同名 release，把平台归档作为附件上传。
6. 把离线打包用的翻译组件包 `tune-translation-*` 单独上传到同一个 release。自动更新只
   认平台归档，组件包由应用在设置页按需下载（1.32.0 起在线用户按统一组件注册表下载各组件，
   见 [local-components.md](local-components.md)）。
7. 失效 CDN 缓存并自检：
   `curl https://purge.jsdelivr.net/gh/pengtang1024/tune@master/version.json`，
   再拉一次 CDN 地址确认 `version` 等于刚发的版本。
8. 老版本的应用点「检查更新」就能看到并安装。

Gitea 的仓库是私有的，release 接口要令牌；更新检查只走公开的 GitHub
（静态清单优先，API 兜底），Gitea 的 release 只作为自己人的人工下载入口。

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
  归档是整包替换，但只换应用 bundle；本地组件（翻译/歌词/FFmpeg）装在应用支持目录
  `<support>/components/<id>/`（见 [local-components.md](local-components.md) §3），升级不会被删除，
  更新协议不需要额外字段；`<support>/translation/` 只作旧版翻译组件的兼容读取。
- **Windows / Android**：只显示版本与「到发布页手动下载」，不做替换
  （运行中的可执行文件在 Windows 上无法覆盖）。

升级失败时旧 bundle 会换回来（新目录换入失败会先把备份还原），不会把应用
留在半装状态。下载与解压都在 UI 线程之外，进度只刷新卡片那一小块。

## 测试

- `test/services/update_service_test.dart`：版本比较（含 `1.9.9` → `1.10.0`
  与 `+build` 后缀）、三档取数顺序、双清单交叉核对、304、失败分类、下载校验、
  临时目录里的安装替换。
- `test/services/version_manifest_test.dart`：仓库根 `version.json` 与
  `pubspec.yaml` / `AppVersion` 一致，Linux 归档的 `size` 与 `sha256` 与清单一致。
- `test/app/update_scheduler_test.dart`：首查延时、定时抖动、最小间隔、失败退避。

## 限制

- CDN 与 raw 都可能在中国大陆不可达；三档全失败时如实报「检查失败」，
  不把失败说成「已是最新」。
- 归档没有签名校验（第一阶段仅 `sha256` + `size` + 双源交叉核对）。
  需要更强保证时按 [update-cdn.md](update-cdn.md) §7 补签名。
- Android 的 APK 安装需要系统 Intent，桌面端尚未接入。
- Linux 平台归档约 51 MiB；离线打包用的翻译组件包约 500 MB，1.32.0 起在线用户改为
  从统一组件注册表按需下载各组件（[local-components.md](local-components.md)）。这些下载
  都不占平台归档的更新下载量，但 GitHub Release 附件上限要按各组件量级预留。
- 源码仓库不入库模型与运行时，也没有启用 Git LFS（无 `.gitattributes`、
  `git lfs ls-files` 为空）；本地模型/运行时走 Release 组件包，由应用在设置页按需下载
  （[local-components.md](local-components.md)）。
