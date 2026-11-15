# 安全策略

> 状态：规范 · 适用版本 1.33.0 · 最后核对 2026-11-15

## 支持范围

只有最近发布的主线版本接收安全修复。

| 版本 | 支持 |
| --- | --- |
| `1.33.x`（当前主线，最新 `1.33.0+53`） | ✅ 接收修复 |
| `1.32.x`（上一版） | ✅ 仅接收安全修复 |
| `1.31.x` 及更早 | ❌ 仅建议升级 |

发行包与更新清单见 [Releases](https://github.com/pengtang1024/tune/releases) 与 `version.json`。

## 报告漏洞

**请勿**通过 GitHub / Gitee / Gitea 的公开 issue、PR 或讨论区报告安全漏洞——那会立刻暴露给所有人。

两条渠道，效力相同：

- **推荐：GitHub 私密漏洞通报** —— [Report a vulnerability](https://github.com/pengtang1024/tune/security/advisories/new)。
  报告只对维护者可见，可以在里面直接讨论修复与 CVE 申请。该功能已在本仓库开启（2026-11-15 核实）。
- **保底：邮件** —— 发到 **pengtang1024@qq.com**，标题以「安全」开头。没有 GitHub 账号、或不想留平台记录时走这条。

报告请尽量包含：

| 字段 | 要求 |
| --- | --- |
| 受影响的版本 | 如 `1.33.0+53`，以及平台（Linux 发行版 / 桌面环境 / 是否 Wayland） |
| 漏洞类型 | 例如路径穿越、凭据泄漏、命令注入、越权读文件、更新链劫持 |
| 复现步骤 | 能给出最小复现最好 |
| 影响评估 | 攻击者需要什么前提（本地用户？同机进程？网络中间人？），能达成什么后果 |
| 署名与披露（可选） | 你希望如何署名，以及是否计划公开披露 |

### 我们的节奏

这是一个单人维护的项目，下面的时间是**目标**而非合同承诺：

| 阶段 | 目标 |
| --- | --- |
| 确认收到 | 7 天内 |
| 初步评估与分级 | 14 天内 |
| 修复或缓解方案 | 视严重度，通常 30 天内 |
| 公开披露 | 修复发布后，与你协商时间，默认不早于修复版本发布前 7 天 |

修复发布时会在 `CHANGELOG.md` 里致谢（除非你要求匿名）。

## 已知的设计边界（不是漏洞）

以下行为是当前设计的**已知取舍**，报上来我们会当讨论而非漏洞处理——但如果你发现它们的实际后果比这里描述的更严重，那仍然值得报告。

### 1. 音源凭据以明文形式存在应用数据目录

Subsonic / Navidrome、Ampache、Koel、Emby、Plex、Jellyfin、Kodi、LMS 等音源实例的地址、用户名与密码，保存在应用支持目录下的偏好文件中：

```text
<应用支持目录>/settings/          # 每个偏好一个文件
```

**没有加密**，也不使用系统钥匙串。保护依赖于操作系统的文件权限（当前以默认 umask 创建）。这意味着：能以你的账户身份读文件的进程、或 root，都能读到这些凭据。

因此请**为音乐服务器使用独立账号**，不要复用你其它服务的密码。若你要在这台机器上与不可信程序共存，这属于当前实现无法防御的场景。

### 2. 更新链只校验完整性与一致性，不校验签名

自动更新从仓库根目录的静态清单 `version.json` 取版本信息，按下列顺序尝试：

1. `https://cdn.jsdelivr.net/gh/pengtang1024/tune@master/version.json`
2. `https://raw.githubusercontent.com/pengtang1024/tune/master/version.json`
3. GitHub Releases API（`https://api.github.com`）

下载到的归档会校验**字节数与 SHA-256**（见 `lib/data/services/update/update_service.dart` 的完整性检查），但清单本身**没有数字签名**。

后果：如果 GitHub 仓库或 CDN 被攻破、能改写 `version.json`，攻击者可以同时替换下载地址与 `sha256`，完整性与一致性校验都会通过。这项风险的缓解（Ed25519 签名清单、公钥编译进客户端）已设计但**尚未实施**，见 [`docs/update-cdn.md`](docs/update-cdn.md) §7。

你可以据此决定是否启用自动下载。手动下载安装包后自行核对 release 页面公布的 SHA-256，可以规避这条链路。

### 3. 单实例端口只监听回环地址

为了保证再次启动时能唤醒已有窗口，应用会在 `127.0.0.1:47321` 绑定一个 TCP 端口并做一次握手。它不监听外部网卡、不对外暴露服务。同机的本地进程可以连上该端口并尝试发送文件参数——这是设计内的行为（等价于「命令行打开文件」），不构成远程攻击面。

### 4. 第三方组件按各自许可证分发

FFmpeg、whisper.cpp、sherpa-onnx、llama.cpp、Qwen 模型等以独立组件形式下载或随归档分发，各自许可证见 [`THIRD_PARTY_NOTICES.md`](THIRD_PARTY_NOTICES.md) 与 [`docs/licensing.md`](docs/licensing.md)。第三方组件本身的漏洞请向对应上游报告；若 Tune 的集成方式放大了影响，也请告诉我们。

## 不在范围

- 需要**物理接触**设备、或需要攻击者已取得你的账户 / root 权限才能利用的问题。
- 第三方服务本身的漏洞（音乐服务器、播客目录、封面提供方、CDN）。
- 社会工程、钓鱼、以及针对维护者个人的攻击。
- 缺少 HTTPS、HSTS 之类的「最佳实践」建议本身，除非能给出具体的利用路径。
- 通过堆栈溢出、超大本地文件等纯粹本地拒绝服务（会记录为缺陷，但按普通 bug 处理）。
- 自动化扫描器产出的、未经人工确认的报告。

## 安全相关内容在代码里的位置

| 关注点 | 位置 |
| --- | --- |
| 更新清单取数与完整性校验 | `lib/data/services/update/` |
| 音源实例与凭据的读写 | `lib/data/services/impl/preference_store_io.dart`、`lib/features/sources/` |
| 单实例端口 | `lib/data/services/impl/desktop/socket_single_instance_service.dart` |
| 本地组件下载与解压 | `lib/data/services/components/` |
| 数据库访问 | `lib/data/services/database/` |

## 致谢

已修复漏洞的报告者会记在 `CHANGELOG.md` 对应版本的条目里。

## 相关文档

- [第三方声明](THIRD_PARTY_NOTICES.md) — 依赖与素材的许可证与来源
- [更新清单与签名规划](docs/update-cdn.md) — 自动更新链的已知边界
- [行为准则](CODE_OF_CONDUCT.md) — 社区互动的行为边界
- [获取帮助](SUPPORT.md) — 非安全问题的提问渠道
