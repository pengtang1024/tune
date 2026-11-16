# 自动更新

> 状态：设计（已实施） · 适用版本 1.33.0 · 最后核对 2026-11-15

> 桌面端从静态清单发现自己有新版本，下载并换掉正在运行的 bundle，重启后生效。

## 目录

- [数据源](#数据源)
- [产物约定](#产物约定)
- [发布步骤](#发布步骤)
- [从旧版本升级一次](#从旧版本升级一次)
- [安装行为](#安装行为)
- [测试](#测试)
- [限制](#限制)

## 数据源

应用先读仓库根目录的静态清单 `version.json`，由 CDN 分发：

1. `https://raw.githubusercontent.com/pengtang1024/tune/master/version.json`
   （分支地址；`@latest` 会因仓库超过 jsDelivr 的 50 MB 包上限被拒）
2. `https://cdn.jsdelivr.net/gh/pengtang1024/tune@master/version.json`（仓库越过 jsDelivr 50 MB 包上限后已降为第二档，2026-11-16）
3. 前两档都拿不到时，才读 GitHub 的 release 接口（有 token 挂 Bearer，没有就匿名）

两份清单都拿到时会交叉核对：`build` 不同取较新的（CDN 边缘过期是发布后的常态），
同一个 `build` 却资产不同才拒绝。清单字段、调度、退避与失败分类见 [update-cdn.md](update-cdn.md)。

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

- 本地翻译模型不再随平台包分发。模型、llama.cpp 运行时与许可证打成一个可选组件包
  `tune-translation-qwen2.5-0.5b-b12274.zip`（约 500 MB），单独作为 Release 附件
  发布；应用在设置页按需下载，元数据见 `translation/manifest.json`。
- 组件包文件名以 `tune-translation-` 开头，不含平台名，因此不会被自动更新选中。
- 1.32.0 起本地能力已收敛为统一组件注册表（[local-components.md](local-components.md)）：
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

v1.33.0（2026-11-15）按这个顺序走通了一遍，照抄即可。

| # | 动作 | 命令与要点 |
| --- | --- | --- |
| 1 | 改版本号与 CHANGELOG | `pubspec.yaml`、`lib/config/app_version.dart`、`CHANGELOG.md` 的 `## [x.y.z] - 日期`；再把「当前版本」三处改掉：`README.md`、`README_en.md`、`wiki/README.md` |
| 2 | 构建并打包 | `flutter build linux --release` → `./tool/package_linux.sh`（离线包加 `--offline`） |
| 3 | 生成清单 | 脚本顺带写 `dist/version.json`；仓库根那份用 `dart run tool/write_version_manifest.dart --archive dist/tune-linux-x64-<version>.tar.gz --root` 一次写两处 |
| 4 | 跑门禁 | `./tool/check.sh --l10n --tools --docs` |
| 5 | 合并并打 tag | `git checkout master && git merge --no-ff develop`；`git tag -a vX.Y.Z -m "vX.Y.Z"` |
| 6 | 推送三端 | `git push <remote> develop master vX.Y.Z`，三个远程各来一遍；tag 必须推 |
| 7 | 建 release 上传归档 | 三端接口不同，见下表 |
| 8 | 重推三端 wiki | `wiki/README.md` 的当前版本变了 |
| 9 | 失效 CDN 并自检 | 见「发布后自检」 |

第 2 步有个坑：`tool/package_linux.sh` 用 PATH 里的 `dart` 写清单，**找不到就静默跳过**、
只留下归档。要么 `DART=/opt/flutter/bin/dart ./tool/package_linux.sh`，要么事后补第 3 步。

第 4 步不能提前：`test/services/version_manifest_test.dart` 会拿**真实归档**核对 root
`version.json` 的 `size` 与 `sha256`，打包前跑等于没验。

第 5 步的合并不是为了整洁——应用读的是 `master` 分支上的清单，master 不前进，tag 打得再对
也不会有人看到新版本。

### 三端 release 的接口差异

| 平台 | 建 release | 传附件 | 实测坑 |
| --- | --- | --- | --- |
| GitHub | `POST /repos/{o}/{r}/releases` | `POST {upload_url}?name=<file>`，头 `Content-Type: application/octet-stream`，体 `--data-binary @包` | 用 python `requests` 建 release 可能抛 `RemoteDisconnected`，但请求其实已成功；重试前先 GET 查重，否则建出重复 release |
| Gitea | `POST /api/v1/repos/{o}/{r}/releases` | `POST /releases/{id}/assets?name=<file>` | 没有 `/releases/tags/{tag}` 端点（404），得 `GET /releases?limit=N` 过滤 `tag_name`；改正文用 `PATCH /releases/{id}` |
| Gitee | `POST /api/v5/repos/{o}/{r}/releases?access_token=`，JSON body（`tag_name`、`name`、`target_commitish` 三个字段都要给） | 单独 `POST /releases/{id}/attach_files`（multipart，字段名必须是 `file`） | 建 release 时带 `attach_files` 会 401「Access token does not exist」；改正文 `PATCH /releases/{id}` 同样要求 `tag_name` + `name`，缺任一个都回 400；平台还会自动附上源码 zip / tar.gz；**附件配额 1 GB**，见下 |

三端正文用同一份文本（清单 `notes` 去硬换行 + 一句归档说明），名称沿用
`vX.Y.Z — 一句话`。

**Gitee 的 1 GB 附件配额会被 50 MB 一版的归档吃完**：2026-11-16 发 1.38.1 时
`attach_files` 回 400 `验证失败：文件大小已超出仓库附件配额：1 GB`（此前十来版各挂一份
53 MB 归档）。处理办法是把 Gitee 那份 release 的正文补一句「归档请到 GitHub / Gitea 的
同一 tag 下取」，不再传二进制——Gitee 在本项目里是镜像，下载入口一直是 GitHub；
要腾配额就去删历史 release 的附件，那是维护者的决定，不自动做。

### 组件包（可选）

离线打包用的翻译组件包 `tune-translation-*` 单独上传到同一个 release。自动更新只认平台
归档；组件包由应用在设置页按需下载（1.32.0 起在线用户走统一组件注册表，见
[local-components.md](local-components.md)），所以没上传只影响内网离线分发，不影响普通
用户升级。

### 发布后自检

- [ ] 三端 `git ls-remote --tags <remote> 'refs/tags/vX.Y.Z^{}'` 指向同一个合并提交
- [ ] 三端 `/releases/latest` 都返回新版本
- [ ] 从任一平台下载归档，`sha256sum` 等于根 `version.json` 里的 `sha256`
- [ ] `curl https://purge.jsdelivr.net/gh/pengtang1024/tune@master/version.json` 返回 `status: finished`
- [ ] CDN 与 `raw.githubusercontent.com` 两份清单版本、`build`、`sha256` 一致
- [ ] CDN 那一份**确实是新版本号**：`finished` 只表示 purge 请求被受理，不表示边缘已经换了新内容。
      2026-11-16 发 1.33.2 时出现过「purge 已 finished、CDN 仍返回 1.33.1」约十分钟，
      再 purge 一次并等 15–60 秒就对了。这一项为什么单列：`version.json` 的 `Cache-Control`
      是 `max-age=604800, s-maxage=43200`（浏览器 7 天、边缘 12 小时），而客户端带
      `If-None-Match` 发条件请求——边缘留着旧对象时会回 304，客户端沿用旧清单，
      **用户就一直看不到新版本**，但日志上一切正常。
- [ ] `tar -tzf` 首项是 `./`，且含 `tune`、`resources/`、`share/`（bundle 内容在根）

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

## 相关文档

- [更新清单与 CDN](update-cdn.md) — `version.json`、取数与退避
- [开源基建与维护清单](oss-maintenance.md) — 发版要同步的那几条线
- [本地组件](local-components.md) — 组件包的下载与校验
- [许可证与第三方声明](licensing.md) — 归档里必须带的声明
