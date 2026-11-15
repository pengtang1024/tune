# 更新检查：静态清单 + CDN

> 状态：**已实施**（§8 的 1–4 步；签名按决定留到第二阶段）。
> 动机：`GET /repos/{owner}/{repo}/releases/latest` 匿名限流 60 次/小时/IP，
> 现已确认被限流时旧版会把 403 当成「没有新版本」（v1.32.0 已改为如实报失败，
> 但失败仍然意味着「查不到更新」）。静态清单把「查版本」从 API 挪到 CDN，
> 只剩「下包」一件事，而后者本来就不吃 API 配额。

## 1. 实测数据（2026-11-15，本机，Linux）

### 1.1 jsDelivr 对 GitHub 仓库

| 项目 | 实测结果 |
| --- | --- |
| 仓库可见性 | `pengtang1024/tune` = `visibility: public`、`private: false`、default_branch `develop` |
| 分支寻址 | `@master`、`@develop` 均 200，响应头 `x-jsd-version-type: branch` |
| 标签寻址 | `@v1.32.0` 与 `@1.32.0` 均 200，`x-jsd-version: 1.32.0`，类型 `version` |
| `@latest` | 200，自动解析到 `1.32.0`，类型 `version` |
| 提交寻址 | `@<40 位 sha>` 200 |
| 单文件上限 | **20 MB**。17.7 MB 字体 200；25.1 MB 字体返回 `403 File size exceeded the configured limit of 20 MB.` |
| 是否需要预热收录 | **不需要**。v1.32.0 是 40 分钟前打的 tag，`@v1.32.0` 与 `@latest` 立即命中；`@develop` 的 `CHANGELOG.md` 已含 40 分钟前新增的 `[1.32.0]` 段 |
| 压缩 | `Accept-Encoding: gzip` 时 `content-encoding: gzip`；`vary: Accept-Encoding` |
| CORS | `access-control-allow-origin: *`（桌面端无影响，网页端也够用） |

> **2026-11-15 复测（发版后）**：仓库打包体积 50.6 MiB（两个可变字体合计约 42 MB），
> `@latest/version.json` 稳定返回
> `403 Package size exceeded the configured limit of 50 MB`，
> 而同内容的 `@master/version.json` 仍是 200。
> **所以清单地址固定在 `@master`，不再使用 `@latest`。**

### 1.2 响应头与缓存

| 寻址方式 | Cache-Control | 说明 |
| --- | --- | --- |
| 分支 / `@latest` | `public, max-age=604800, s-maxage=43200` | 浏览器 7 天、边缘 12 小时 |
| 标签 / 提交 | `public, max-age=31536000, s-maxage=31536000, immutable` | 一年，内容不可变 |

- **ETag**：`W/"19fc-ca1057ff9272958b"`（弱校验，随内容变）。
- **304**：带 `If-None-Match` 复验返回 `HTTP 304`，`age: 6`，不传正文。**支持**。
- **purge**：`GET https://purge.jsdelivr.net/gh/pengtang1024/tune@master/README.md`
  返回 200，`status: finished`，`throttled: false`，两个上游（CF / FY）都刷掉。
  实测刷完立即取到新内容。**发版后可以主动失效，不必等 12 小时。**
- 边缘节点：`x-served-by: cache-fra-..., cache-sin-...`（Cloudflare + Fastly 双路）。

### 1.3 备选地址

| 地址 | 实测 |
| --- | --- |
| `raw.githubusercontent.com` | 200，`cache-control: max-age=300`，无 `x-ratelimit-*` 头；**连续 30 次 + 并发 10×100 次全部 200，期间 API 配额 4949 → 4949 未变**（不占 REST 配额）。它有未公开的软限，但实测抗住了 130 次突发 |
| GitHub Pages | `https://pengtang1024.github.io/tune/` 返回 **404**：仓库没开 Pages。要用得先建 gh-pages 分支/工作流、开 Pages，Pages 自身缓存约 10 分钟、站点有 1 GB 软上限 |
| `github.com/.../releases/download/...` | 302 到 `release-assets.githubusercontent.com` 的预签名地址；连下 8 次（Range 请求），API 配额 4949 → 4949 未变。**资产下载与 API 配额无关** |

结论：`raw.githubusercontent.com` 并不像传闻那样受限——至少它不吃 REST 配额，
可以作为 jsDelivr 之后的第二顺位。GitHub Pages 现在不可用，要额外工序，不推荐先上。

### 1.4 现有实现的现状

- [update_service.dart](../../lib/data/services/update/update_service.dart) 的
  `latest()` 打 `https://api.github.com/repos/pengtang1024/tune/releases/latest`：**这是唯一吃 60 次/小时配额的请求**。
- 下载走 `asset.url`，而它来自 `browser_download_url`
  （`https://github.com/.../releases/download/...`）：**现有实现已经正确**，
  下载不吃 API 配额，51 MB 包不受限流影响。
- 改动前检查只在设置页手动触发（`updateControllerProvider` 只被设置卡片引用），没有启动检查，也没有定时器；现在启动流程已接入后台定时器与退避调度（见 §4.3、§8 第 3 步）。

## 2. 可行性结论

**可以做**，且改动面比想象的小：真正要换的只有「取最新版本号」这一个请求，
下载与安装路径不动。

约束与风险：

1. 仓库必须保持 public；jsDelivr 不服务 LFS 指针文件，manifest 不能放进 LFS。
2. manifest 单文件必须 < 20 MB（实际只有几 KB）。
3. 分支寻址有 12 小时边缘缓存，靠发版后 purge 解决；标签寻址是一年 immutable，
   所以「发现最新版」的地址要落在 `@master` 上，不能钉死某个 tag，也不能用 `@latest`
   （仓库超过 jsDelivr 的 50 MB 包上限，见 §1.1 复测）。
4. 中国大陆网络对 jsDelivr / raw.githubusercontent 都可能不通，这是本方案**最大的现实风险**，
   只能靠多级回退 + 静默失败兜住，不能保证一定查到。

## 3. `version.json` 设计

位置：仓库根 `version.json`，随发版提交进 `master`（CDN 走 `@master` 分支地址）。

```json
{
  "schema": 1,
  "version": "1.32.0",
  "build": 52,
  "released_at": "2026-11-15T03:20:00Z",
  "release_url": "https://github.com/pengtang1024/tune/releases/tag/v1.32.0",
  "notes": "### 新增\n- …",
  "min_supported": "1.20.0",
  "assets": {
    "linux-x64": {
      "url": "https://github.com/pengtang1024/tune/releases/download/v1.32.0/tune-linux-x64-1.32.0.tar.gz",
      "size": 53725517,
      "sha256": "0c0e2881…a164"
    }
  }
}
```

字段取舍：

- `version` + `build`：**两个都比**，语义化版本相同但构建号更大时也应提示更新。
  现在的 `isNewer` 直接忽略 `+build`，等于永远不可能发「同版本重打」的包。
- `notes`：直接放 CHANGELOG 对应段落，客户端原样显示。
- `assets`：按平台键（`linux-x64`，预留 `windows-x64` / `android-arm64`）。
  `sha256` 必填，客户端装前校验。
- `min_supported`：低于此版本客户端强制提示，不做静默跳过。
- `signature`：见 §7，第一版留空。

### 3.1 谁生成

由 **打包脚本**生成，不进 CI：

- `tool/package_linux.sh` 打完包后调用 `tool/write_version_manifest.dart`，
  写 `dist/version.json`（数据源来自 `pubspec.yaml`、CHANGELOG 与归档实测）。
- `tool/release.sh`（唯一发版入口）**尚未单独落地**：当前发版仍按 §6 手工走，
  但「写 manifest」已由打包脚本兜住，漏写会立刻被下面的测试抓到。
- 防漏第二道：[version_manifest_test.dart](../test/services/version_manifest_test.dart)
  断言 `version.json.version/build` 与 `pubspec.yaml`、`AppVersion` 一致，
  并核对 Linux 归档的 `size`/`sha256` 与清单一致。
  `flutter test` 是门禁，对不上就直接红。**这条比 CI 更可靠，也不引入 Actions 权限。**

为什么不用 Actions 生成：发版在本机完成（含 LFS、大包），Actions 要么重复打包，
要么得反查 release 资产再回写，两条路都更容易漂移；且 Actions 需要写权限 token。

## 4. App 侧行为

### 4.1 取数顺序

```
1. https://cdn.jsdelivr.net/gh/pengtang1024/tune@master/version.json
2. https://raw.githubusercontent.com/pengtang1024/tune/master/version.json
3. https://api.github.com/repos/.../releases/latest（现有逻辑，解析旧格式；有 token 挂 Bearer，没有就匿名）
```

- 1 与 2 各给 3 s 连接 / 5 s 接收（清单只有几 KB，慢 CDN 不应拖住检查）。
- 两份清单都拿到时**交叉核对**：`version`/`build` 或任一资产的 `url`+`size`+`sha256`
  不一致 → 直接拒绝并报 `manifestMismatch`，**不退回 API**。
- 第 3 档保留现有 `UpdateCheckException` 的失败分类，用于文案；**没配 token 也会试**
  （匿名兜底，仍受 60 次/小时限制）。
- 请求 **不带** `Authorization`（token 不发给 CDN）；只有第 3 档带 Bearer。

### 4.2 304 与缓存

- ETag 与上次解析出的清单**按地址分别**存放，并持久化到用户数据目录
  `<support>/update/version_manifest_cache.json`（不放进组件目录）。条目带三项：
  来源地址、该地址的 ETag、以及该地址解析出的完整清单。因此重启后的第一轮仍会带
  `If-None-Match`，两个源也不会串用彼此的验证器或解析结果。
- 收到 304 时只复用**本地址**此前解析出的清单；双源交叉核对（§4.1）照常执行，
  一方 304、另一方 200 且内容不同时仍报 `manifestMismatch` 拒绝。
  **304 不是时间窗口**：下一轮仍然会发出条件请求，只是省掉一次解析，
  不会让某一轮「查了等于没查」。
- 缓存文件按 `schema` 版本管理：文件损坏、字段缺失或 `schema` 不匹配时**静默丢弃**
  该缓存，退回无条件请求并在拿到新答案后重写；条目内的 `url` 与键不一致也直接跳过。
  任何情况下都不因缓存问题报错或卡住。
- 上次成功的答案在 **10 分钟**内可复用。这个窗口远小于调度器的 1 小时间隔
  （§4.3），只覆盖同一轮里的第二次询问（例如设置页与后台恰好同时要答案），
  绝不会把下一轮的取数吞掉。`forceRefresh`（设置页手动检查）永远真查。
  失败不入缓存，下一次直接重新取数。
- 调度间隔与结果复用窗口必须对齐：正常间隔（1 h）**大于**复用窗口（10 min），
  所以每一轮后台检查都会真正到达 CDN。改动其中任何一个都必须先核对这一条，
  测试见 `test/services/update_service_test.dart` 的「reuse window」。
- 自动检查之间的节流由调度器的**最小间隔 15 min** 承担（见 §4.3），
  不靠「跳过检查」实现。

### 4.3 触发时机

| 触发 | 行为 |
| --- | --- |
| 启动 | 启动后 **60 s** 查一次（`main.dart` 在其它启动任务之后 `start()`，不与首帧抢时间） |
| 后台定时 | 每 **1 h ± 10% 抖动**（54–66 min）一次；失败按退避表等待 |
| 手动 | 设置页按钮，永远真查、永远显示结果（不受节流限制） |
| 节流 | 任意两次自动检查间隔 ≥ **15 min** |
| 失败退避 | 30 min → 1 h → **2 h（封顶）**；连续失败一直停在 2 h，成功后回到 1 h 节奏（异常也按失败计） |
| 离线 | 后台检查静默失败，不弹任何界面；取数过程仍按地址各留一条 `info`（见 §4.3.1） |
| 正在下载/安装 | 自动检查直接跳过，直到状态离开 `downloading/installing`（`ready` 也跳过） |

### 4.3.1 取数日志

日志是这条链路上唯一的排障证据，所以**每个地址每轮检查各一条 `Log.info`**：

- 内容固定为「主机 + 结果 + 耗时毫秒」：命中时带清单的 `version+build`，
  304 写「沿用上次解析」，404 写「无清单」，其它状态码写码值，请求抛异常写异常类型。
- 不带完整 URL 之外的任何东西：不打印响应体，不带 token / 请求头。
- 同一轮同一地址只记一条：重试与退避在调度器（§4.3 的退避表），不在取数循环里重复。
- 两份清单不一致仍然是 `Log.error`，并带上两侧的 `version+build`，一眼能看出是哪一边过期。

用 `info` 而不是 `debug` 的原因：`Log.debug` 整段包在
`const bool.fromEnvironment('DEBUG')` 里，`Log` 早先又用了 logger 包默认的
`DevelopmentFilter`（断言关闭后丢弃所有级别），所以用户机器上什么都看不到。
`Log` 现在走 `ProductionFilter`，`info` 及以上才真正可见——细节见
[conventions.md](conventions.md) 的「日志」。

自动检查发现新版时只更新设置页的更新卡片（不弹模态、不加底栏红点）；是否下载仍由用户点。

### 4.4 失败文案

沿用 v1.32.0 的分类，新增两类：

- 三档全部不可达：按分类显示「检查失败：网络请求超时或无法连接」或
  「检查失败：更新服务返回了异常响应」。
- 两份清单不一致：「检查失败：两份更新清单不一致，已拒绝本次更新」。
- 下载完成但 `size`/`sha256` 不符：「安装包校验不通过，已删除，请重试」，
  并删掉临时文件，不进入安装步骤。

## 5. 现有 token 逻辑怎么处置

**保留，但降级为第三档兜底。**

- 优先级不变：手填 > `GITHUB_TOKEN` > `GH_TOKEN`。
- 只有走到 `api.github.com` 时才挂 Bearer；CDN 两档一律不带。
- 设置页文案改一句：「默认不需要；静态清单不可达时才用 GitHub API 兜底」。
- 环境变量读取逻辑与 `resolveToken` 原样复用，不新增存储键。
- 好处：没有 token 的用户走 CDN，彻底绕开 60/h；有 token 的用户在网络受限时仍有一条路。

## 6. 发布流程（防漏 checklist）

`tool/release.sh` 内固定顺序，任一步失败即停：

1. 门禁：`flutter analyze`、`flutter test`（含 `version_manifest_test`）。
2. bump `pubspec.yaml`、`AppVersion`、CHANGELOG。
3. `flutter build linux --release` → `tool/package_linux.sh` → `dist/version.json`。
4. **校验**：`dist/version.json` 的 `sha256`/`size` 与归档实测一致（脚本内对比，不一致退出）。
5. 提交 `version.json`（与版本号同一笔或紧随一笔）。
6. tag → 推送三端（gitee 走发布点镜像）→ 建 GitHub/Gitea release 并上传。
7. `purge.jsdelivr.net/gh/pengtang1024/tune@master/version.json`（`@latest` 在本仓库不可用）。
8. 自检：拉一次 CDN 地址，断言返回的 `version` 等于刚发的版本；不等则报错并提示手工 purge。

## 7. 签名校验：结论与代价

**建议做，但放在第二阶段（先上静态清单，签名单独一笔）。**

- 威胁模型：GitHub 账号或 CDN 被攻破 → 攻击者能改 `version.json` 的 `url` 与 `sha256`，
  客户端会开开心心下载并安装。仅靠 HTTPS 与 sha256 挡不住「权威源被改」。
- 做法：Ed25519 签名 `version.json` 的规范化字节，公钥编译进 App，私钥离线保存。
  Dart 侧需要 `cryptography` 或 `ed25519_edwards`；脚本侧用 `openssl` 或 `minisign`。
- 代价：
  1. **密钥管理**：离线保管、备份、轮换与吊销都得有流程；私钥丢失 = 后续所有版本无法签名，
     只能发一个「关闭校验」的过渡版，代价很高。
  2. 每台发版机器都要拿到私钥（或人肉签名），不能全自动。
  3. 客户端多一个依赖与一条失败路径（签名不匹配 → 拒绝更新，需要能回滚的公钥更新机制）。
  4. 多语言/文档要解释「为什么校验失败」，用户侧可做的只有等新版本。
- 折中（推荐）：第一版先做 **sha256 + 大小校验 + 双地址交叉核对**（CDN 与 raw 的
  manifest 若不一致则拒绝并报失败）。等确实要对外分发到不可信网络时再补签名。

## 8. 实施顺序（评审通过后）

1. ✅ `version.json` 模型 + 生成脚本 + 一致性测试。
2. ✅ `UpdateService` 换数据源，三档回退 + ETag + 校验；保留 API 解析旧格式。
3. ✅ 定时与退避调度，接到启动流程。
4. ✅ 设置页文案微调 + 失败文案补两条。
5. ⏳ （第二阶段）签名。

回滚：`latestGitHubApi()` 的旧解析仍留在 `parseRelease`，`version.json` 解析持续失败时会自然退回 API 路径。

## 9. 已知风险

| 风险 | 影响 | 缓解 |
| --- | --- | --- |
| 中国大陆访问 jsDelivr / raw 不稳定 | 查不到更新，或首次失败 | 三档回退、失败静默、手动重试；必要时后续加国内镜像 |
| jsDelivr 单文件 20 MB | 无（manifest 几 KB）；但别把模型塞进仓库 | 大文件继续走 release 资产 |
| 分支 12 小时边缘缓存 | 发版后最长半天内老客户端查不到 | 发版脚本主动 purge + 发布自检 |
| 仓库转私有 | jsDelivr 立即失效 | 保持 public；转私有需同时切回 API 或 Pages |
| `version.json` 与真实资产不一致 | 下载校验失败 | 生成脚本内比对 + 发布自检 |
