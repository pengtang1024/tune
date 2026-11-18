# AI 音乐分享（mesh）

> 状态：设计（已实施） · 适用版本 1.38.1 · 最后核对 2026-11-16
>
> 实施范围：**M0 全量、M1 全量、M2 全量**（撤销、举报、黑名单、AcoustID 查重都已接线）。
> `fpcalc` 已登记成可下载组件（`share-fingerprint-runtime`），client key 在分享页填；
> 两样缺任一样查重就返回 null，闸门把它当「没查」而不是「查过没问题」（见 §6、§13）。
>
> 一句话：在**用户自己建的 mesh 房间**里交换「本机生成」或「自己拥有版权」的音频。
> 准入不靠信任，靠**可验证的凭证 + 可撤销的房间**；不做的部分比做的部分更能说明这个功能
> 为什么能存在（见 §2、§11）。

## 目录

- [1. 结论先行](#1-结论先行)
- [2. 合规位置](#2-合规位置)
- [3. 组件的四块](#3-组件的四块)
- [4. 条目与凭证](#4-条目与凭证)
- [5. mesh 网络](#5-mesh-网络)
- [6. 准入闸门](#6-准入闸门)
- [7. 标识合规](#7-标识合规)
- [8. 与现有架构的接缝](#8-与现有架构的接缝)
- [9. 滥用与下架](#9-滥用与下架)
- [10. 分期与验证](#10-分期与验证)
- [11. 不做清单](#11-不做清单)
- [12. 待核实](#12-待核实)
- [13. M0 实施记录](#13-m0-实施记录2026-11-16)

## 1. 结论先行

用户要的是「保证只能分享生成的或有版权的」。**客户端能给出的保证有边界**，分三层说清：

- **能保证（技术强制）**：
  - 本应用只把**验得过**的条目放进房间：本机生成台账里有这个输出、或凭证签名链验得过、
    或版权声明与证据齐备（§6）。
  - 标识**随文件走**：隐式标识写进元数据，显式提示写进分享副本，界面不给「去掉标识」的入口（§7）。
  - 分享**可撤销**：房间解散、撤销列表、对端删文件（§9）。
- **只能提高成本（技术尽力）**：
  - 文件一旦离开本机，第三方仍可剥离元数据、改标题、重新编码。我们做的是让**冒充变贵**，
    不是让它不可能。
  - 用 AcoustID 挡「已知商业录音」；未收录的、独家的、翻唱的挡不住（§6）。
- **不能保证（法律与运营）**：
  - 「用户自称有版权」无法在客户端核验。我们只能做到**明确声明 + 记录 + 抽样复核 + 举报下架**，
    把责任放回用户。
  - 所以：**没有撤销与举报，这个功能就不该发**；没有房间封闭与默认关闭，也不该发。

三个反例值得记住：把「用户自带会员」当抗辩的 MyGo 被来函下线；提供 P2P 软件的飞行网被判帮助侵权；
不做审核只做索引的 BT 站被以侵犯著作权罪定罪。它们死在的地方都不是「播放」，是**分发与索引**。

## 2. 合规位置

### 2.1 四条现在生效的规则

| 规则 | 对我们的约束 |
| --- | --- |
| 《互联网信息服务深度合成管理规定》（2023-01-10） | 生成合成内容要标识；**不得删除、篡改、伪造标识** |
| 《生成式人工智能服务管理暂行办法》（2023-08-15） | 面向境内公众提供生成服务要履行备案/安全评估义务——本地方案不提供服务，接第三方 API 才涉及 |
| 《人工智能生成合成内容标识办法》（2025-09-01）+ 强制国标 GB 45438—2025 | 导出/下载/复制时文件必须带**显式标识**；元数据里要有**隐式标识**（属性、提供者名称或编码、内容编号）；音频的显式标识是语音提示或节奏提示 |
| 《著作权法》 | 信息网络传播权是专有权；录音制作者权 50 年（第 44 条）；交互式点播必须逐权利人授权，集体管理兜不住 |

### 2.2 判例给的三条边界

- **飞行网（Kuro）案**（2006，北京二中院）：P2P 软件提供者被判停止侵害并赔偿 20 万元——「只提供工具」
  不是免责事由，关键看**是否明知、是否提供便利、是否从中获益**。
- **BT 天堂案**（2018，淮安中院）：发布种子链接并靠广告变现，**以侵犯著作权罪定罪**——索引 + 变现是刑事分水岭。
- **快播案**：技术中立抗辩不成立。

### 2.3 我们站在哪

Tune 没有服务端、没有索引、不收费。这让它更接近「工具」而不是「平台」，但**不自动免责**。
所以设计里塞进四条自我限制，缺一条就不做这个功能：

- 默认**关闭**，只在用户明确创建/加入的房间里分享，房间之外不可见。
- **没有公网发现、没有全局索引、没有热门榜、没有变现**。
- 房间有人数与容量上限，随时可解散。
- **撤销与举报是必备功能**，不是可选项。

## 3. 组件的四块

| 块 | 职责 | 放在哪 |
| --- | --- | --- |
| 生成台账 generation ledger | 记下本机每一次生成的输入摘要、模型、输出哈希 | `lib/features/share/data/generation_ledger.dart` |
| 准入闸门 admission gate | 判定一条音频能不能进房间，产出 `Shareable` / `Rejected` | `lib/features/share/domain/share_admission.dart`（纯规则，无 IO） |
| mesh 传输 | 发现、建链、交换清单、分块传输、加密 | `lib/data/services/mesh/`（协议层，不认识「歌曲」） |
| 撤销与举报 | 房间解散、条目撤销、对端删除、本地黑名单 | `lib/features/share/application/` + 表 `share_events` |

分层的理由：准入是**业务规则**（会随法规变），协议是**传输事实**（不会因为法规变）。
两者混在一起，法规一改就要动网络代码，反过来也一样。

## 4. 条目与凭证

一条可分享条目 = 音频文件 + 一份签名清单。清单是事实来源，数据库只是它的投影。

```json
{
  "v": 1,
  "cid": "sha256:9f2c…",          // 音频字节的 sha256，唯一键
  "size": 5242880,
  "mime": "audio/flac",
  "durationMs": 183000,
  "title": "晚风练习曲",
  "artist": "本机作者",
  "createdAt": "2026-11-16T22:40:00+08:00",
  "provenance": {
    "kind": "generated",           // generated | owned
    "generator": "ace-step-1.5",
    "model": "acestep-v15-turbo",
    "promptHash": "sha256:…",      // 提示词只存哈希，原文不出本机
    "seed": 20261116,
    "ledgerId": "gen-7f31",
    "license": "CC-BY-4.0"
  },
  "label": { "aiGenerated": true, "contentId": "tune-20261116-7f31" },
  "sig": { "alg": "ed25519", "peer": "…", "value": "…" }
}
```

- `owned` 条目没有 `provenance.generator`，换成 `claim`：`{kind: own_recording|own_composition|licensed, evidence: [sha256…], acceptedAt}`。
- **签名覆盖整份清单**（除 `sig` 自身）。收端先验签再收字节，不信任发送端的任何字段。
- `promptHash` 而不是提示词原文：传出去的是「可证明是这台机器生成的」，不是作者的创作笔记。

## 5. mesh 网络

### 5.1 拓扑与房间

- **房间**是分享的单位：一个房间 = 一个 32 字节 `roomKey` + 一个人数上限（默认 8，硬上限 16）。
- **全互联 mesh**：房间内每两个 peer 都直连，不做中继、不做超级节点。人数上限就是拓扑上限。
- 建链规则：`peerId` 字典序小的一方主动拨号，避免双连；新 peer 加入后与所有现有 peer 建链并广播 `ANNOUNCE`。
- 两种加入方式：
  - **局域网**：UDP 广播信标（端口 45871，每 2 秒一次、6 秒过期），信标里带 `roomId` 与房间端口。
  - **跨网**：邀请码 = `roomKey + 一组自动探到的可达地址`，粘贴加入；地址由房主那头自己探测（见 5.6）。
    **不做 rendezvous 服务器**——一旦有了「谁在哪个房间」的中心登记，我们就成了 §2.2 里那种提供便利的角色。

### 5.2 帧与消息

帧格式：`4 字节大端长度（含类型字节）+ 1 字节类型 + JSON 负载`。M0 的传输是明文 TCP，加密随 M1 的凭据一起补。

| 消息 | 方向 | 作用 |
| --- | --- | --- |
| `HELLO` | 双向 | 协议版本、peerId、房间证明（用 `roomKey` 的 HMAC） |
| `INVENTORY` | 双向 | 摘要清单：`[{cid, size, manifestHash}]`，只在加入时与变更时发 |
| `ANNOUNCE` | 广播 | 新增一条（带完整清单与签名） |
| `WANT` / `HAVE` | 双向 | 要哪些 cid / 我有哪些（位图） |
| `BLOCK` | 单向 | 256 KiB 分块 |
| `REVOKE` | 广播 | 撤回某个 cid（附原因与签名） |
| `PING` / `PONG` | 双向 | 活性与往返时延 |

### 5.3 加密与身份

- 身份：Ed25519 长期密钥，`peerId = base32(sha256(pubkey))` 前 16 字节。
- 会话：**尚未加密**——M0 的载荷走明文 TCP，靠「局域网/用户自己的隧道」这一层边界；X25519 + ChaCha20-Poly1305 排进 M1 的凭据工作。
- 房间证明：`HMAC-SHA256(roomKey, peerId || nonce)`，证明持有邀请码，不上传 `roomKey`。
- 清单：`MeshInventory` 带 Ed25519 签名，验签先核 `peerId == sha256(公钥) 前 16 字节`，再验正文；坏条目让整份清单作废。

### 5.4 技术选型

| 方案 | 优点 | 代价 | 结论 |
| --- | --- | --- | --- |
| `dart:io` TCP + `cryptography` | 无重量依赖，桌面三端一致，可控 | 自己写 Noise-lite 与连接管理 | **M0 选它** |
| `dart_libp2p` | TCP / QUIC（UDX）、Noise、mDNS 现成 | 体积大、维护者少、API 易变 | M1 若公网 mesh 值得再评估 |
| `flutter_webrtc` 1.6.3 | 有 DataChannel，可穿 NAT | 桌面端稳定性与打包成本；穿透仍要 STUN/TURN，而 TURN 就是中继服务器 | 暂不用 |

### 5.5 配额

- 单 peer 上传限速 2 MiB/s，房间总容量 500 条 / 2 GiB，超出后只收不发。
- 分块 256 KiB，收端按 `cid` 校验整文件，块级失败只重传该块。

### 5.6 跨网：自己探测，不问人也不设按钮

房间里没有任何「填地址」的输入框，也没有「一键穿透」的按钮。开房时房主那头自己探测，探到什么就发什么：

| 探测项 | 怎么探 | 得到的地址 |
| --- | --- | --- |
| 局域网 | 枚举网卡 | `192.168.x.x:port`，同网段最稳 |
| 公网 IPv6 | 枚举网卡，跳过链路本地与 ULA（`fc00::/7`） | `[2001:db8::1]:port`，无需 NAT |
| 路由器映射 | UPnP IGD（SSDP 找网关 → 描述 → `AddPortMapping` → `GetExternalIPAddress`），失败再试 NAT-PMP（网关从 `/proc/net/route` 读） | `203.0.113.7:port`，路由器自己开的口 |

探测有 2 秒预算（`MeshReachability.searchTimeout`），超时就跳过那一项；三项都不成，邀请码里只剩局域网地址，
页面上如实写「没探测到外网入口」。这不是让人去配，而是这条网络确实没有能直连的入口。

邀请码因此带**一组**地址（`tune-share2:`，`seeds` 以换行拼接后 base64url），访客拿到后全部并发拨号，
谁先通就用谁、其余自己关掉；旧版 `tune-share1:` 单个地址仍然认。监听默认绑双栈
（`anyIPv6` + `v6Only: false`，平台不支持 IPv6 时退回 `anyIPv4`）。

**刻意不做的**：STUN/TURN 中继、rendezvous 信令服务器、打洞。前两个会把我们变成「转发/登记」的服务方，
第三个在对称 NAT 下成功率本来有限——与其做一个时好时坏的打洞，不如把能自动拿到的都拿到，
拿不到就如实说。

## 6. 准入闸门

闸门是纯函数：输入「文件 + 清单 + 本机状态」，输出判定。顺序固定，先便宜后昂贵。

```text
0. 编号格式 / 单条大小 / 房间条目数与字节数 / 收到的字节与声明对不上 → rejected
1. 本地黑名单命中？  撤销过、举报过的 cid → rejected（blocked）
2. 清单验签通过？    没签名或验不过 → rejected
3. AcoustID 查重？   命中已知商业录音 → rejected（known_recording）
4. 本机台账命中？    outputHash ∈ generation_ledger → 生成物缺 AI 标识则拒，否则放行（ledger）
5. 生成物但不在台账？ → rejected（unproven_generation）
6. 声明与证据齐备？  provenance ∈ {own_recording, own_composition, licensed}
                     且至少一项证据哈希可校验 → 放行（declaration）
7. 以上都不满足 → rejected
```

- **第 3 条压在第 4 条前面，是实施时的修正**：设计稿把台账放第一，但台账是自证、查重是外部事实；
  把商业曲改名后声明成「生成物」正是要防的那一手，所以外部事实优先。台账仍然是最强的**自证**，
  只是不能推翻查重命中。
- **第 3 条是责任转移**：勾选「我确认这是我自己录制/创作/已获授权」并附证据哈希（DAW 工程、
  分轨、合同扫描件的哈希）。客户端不判断真假，只保证「声明过、有记录、能追溯」。
- **第 3 条是尽力而为**：AcoustID 的指纹库覆盖不全，命中率高的是流行曲；独立音乐、翻唱、
  现场录音大量查不到。它挡的是「把 QQ 音乐下载的文件改个名」这种最省事的冒充。
  算指纹要 `fpcalc`（chromaprint），查库要 AcoustID 的 client key；缺任一样就返回 null——
  那是**没查**，不是**查过没问题**，闸门不会把它当清白证明。
- **收端再验一遍**：发送端验过不算数，接受端用自己的闸门重跑第 1–4 条，失败就丢弃并记 `REVOKE`。

## 7. 标识合规

- **隐式标识**（写进文件元数据，FLAC Vorbis comment / ID3v2 TXXX / MP4 `©too`）：
  `AI_GENERATED=1`、`GENERATOR=<模型名>`、`CONTENT_ID=<contentId>`、`PRODUCER=tune`。
  已实施（2026-11-18）：写侧收口在 `features/share/data/share_label_facts.dart`（键名与容器口径唯一一份）
  与 `share_label_writer.dart`；FLAC/MP3 由随包 vendor 的写侧直接写（`vendor/audio_metadata_reader`），
  MP4 家族与 ogg/opus 交 ffmpeg 改写（`share_label_ffmpeg.dart`），WAV 这类放不下定制键的容器
  判 `unsupportedContainer` 原样保留。每次写入都回读核对，四个键逐条等值才算已标识。
- **显式标识**（写进分享副本的音频流）：开头插入 1.2 秒语音提示「本音频由人工智能生成」；
  不放语音也可以，退化成同样的节奏提示音，二者都符合 GB 45438—2025 对音频的要求。
  已实施：`features/share/data/share_copy.dart` 的 `ShareCopyBuilder` 在发布前生成带提示音的副本
  （默认无声节奏提示音，两声短促；带语音的版本留待录好素材再换），副本头部 1.2 秒前置。
- **界面标识**：列表中用「AI 生成」chip（写法见 [chips.md](chips.md)），详情页显示模型与生成时间。
  已实施：`features/share/presentation/share_lists.dart` 的行标识用 `MetaBadge`（`_AiMark`），
  点开弹窗显示生成者与生成时间。
- **不提供去除能力**：不导出无标识版本，不提供「清理元数据」开关；第三方工具能去，那是它的事，
  但**本应用不给这个按钮**——这一条直接对应《标识办法》「不得删除、篡改、伪造标识」。

## 8. 与现有架构的接缝

### 8.1 目录

- `lib/features/share/domain/`：`share_item.dart`、`share_provenance.dart`、`share_ai_disclosure.dart`、
  `share_declaration.dart`、`share_admission.dart`（纯规则）、`share_session_state.dart`、
  `share_lookup_status.dart`；房间编排不在 domain，房间没有独立状态对象（见 §13）。
- `lib/features/share/application/`：`share_session.dart`（房间状态的所有者）与
  `share_session_controller.dart`（provider）。
- `lib/features/share/data/`：`share_store.dart`、`share_inbox.dart`、`share_ledger.dart`、
  `share_blocklist.dart`、`share_reports.dart`、`share_config.dart`、`acoustid_lookup.dart`、
  `share_migration.dart`，以及标识写入的 `share_label_{facts,writer,ffmpeg}.dart` 与
  提示音副本的 `share_copy.dart`。
- `lib/features/share/presentation/`：`share_pane.dart`（页面）、`share_lists.dart`、
  `share_entry_card.dart`、`share_lookup_section.dart`。
- `lib/data/services/mesh/`：`mesh_{protocol,crypto,identity,messages,peer,room,transfer,discovery,reachability}.dart`
  与 `room_invite.dart`；文件名都带 `mesh_` 前缀，不存在 `discovery.dart`/`transport.dart` 这类裸名。

依赖方向仍是 presentation → application → domain / data，协议层不 import 任何 feature。

### 8.2 不注册成音源类型

**这是刻意的**。注册成音源会被两件事咬到：

- 扫描器会把房间当成曲库去扫，房间一散，库里全是失效条目。
- `lib/features/player/application/track_prefetcher.dart:29` 的预取会把**别人分享的每一条**
  抓成本地副本；`lib/data/services/downloads/song_download_service.dart:10` 的
  `isSupported` 是全局能力，没有按源开关。

所以：分享是**独立 feature**，收到的文件落 `<support>/share/inbox/`，用户点「加入音乐库」才走本地扫描入库。

### 8.3 数据

三张表（已随 M2 落地，细节见 [data-model.md](data-model.md)）：

| 表 | 存什么 |
| --- | --- |
| `share_rooms` | 房间 id、房间名、`roomKey`、创建与关闭时间 |
| `share_items` | cid、标题/字节/缘起、AI 标识、收件落盘位置；`direction` 分「我要分享的」与「收到的」 |
| `share_events` | `generated` / `shared` / `received` / `revoked` / `reported` / `blocked` 的时间线 |

### 8.4 入口

- M0：设置页的**实验开关**（默认关闭）+ 音源页顶部一张入口卡，不占一级导航。
- M1 才考虑一级导航项——加一级导航是壳层改动，要先过 [architecture.md](architecture.md) 的三问。

## 9. 滥用与下架

- **举报**：任一房间成员可举报条目，附理由。已实施：本机删掉收件副本、记一条举报留痕
  （`<support>/share/reports.json`）、广播 `REVOKE`，并把编号写进本地黑名单。
- **撤销**：作者可撤回自己发的条目。已实施：从自己的清单里拿掉、广播 `REVOKE`；
  收端把已收的那份从收件箱删掉（文件也删，用户「加入音乐库」的那份副本不在收件箱里，不受影响），
  并同样进黑名单。「撤销分享」不动作者磁盘上的原始文件。
- **房间解散**：房主一键解散（关房），成员本地清空该房间清单与 blob。
- **黑名单**：本地 `cid` 黑名单（`<support>/share/blocked.json`），撤销过、举报过的编号
  在闸门第一步之后直接 `rejected_blocked`。`peerId` 黑名单留到有跨房间记忆时再说。
- **限速与配额**：见 §5.5；重复 `WANT` 记一次违规，三次断链。

## 10. 分期与验证

| 阶段 | 内容 | 出口判据 |
| --- | --- | --- |
| M0 局域网 ✅ | 房间、UDP 广播发现、清单交换、分块传输、手工「我确认是自有/生成」勾选 | 两台机器同一 Wi-Fi 互相收发 50 MB 音频，中断续传 |
| M1 凭证 ✅ | 生成台账、Ed25519 清单签名、AI 标识写入（隐式写侧 + 提示音副本，2026-11-18 补齐）、收端二次验签 | 伪造清单/改元数据/伪造 ledgerId 三类用例全部被拒 |
| M2 撤销与举报 ✅ | 撤销广播、对端删副本、举报留痕、本地黑名单 | 撤销后对端清单与收件箱都清空；举报落一条 `share_events` 记录且编号进黑名单 |
| 跨网 ✅ | 邀请码带可达地址（公网 IPv6 / 用户自带隧道）、双栈监听 | 两台不同网络（或同机两个地址族）之间用邀请码直连成功 |
| M2 AcoustID 查重 ✅（接线） | `AcoustIdLookup` + `fpcalc` 探测 + 闸门 `known_recording` 优先于台账 | 把商业曲改名混入，被 AcoustID 挡住（或明确落在「未收录」分支） |

测试清单：

- 单元：闸门判定表（12 组输入 × 期望）、清单签名与验签、CID 与字节不一致、块重组与损坏块重传。
- 集成：两个进程回环互通（不需要真网卡），mDNS 报文解析用录制的抓包。
- 滥用用例：剥离元数据后重发、复用别人的清单只换文件、超大文件配额、同一 cid 两个不同内容。

## 11. 不做清单

- 不做**公网 DHT / 索引站 / 种子发布**——那是 §2.2 里 BT 天堂与快播的位置。
- 不做**跨房间搜索、热门榜、推荐**——索引与推荐是「提供便利」的证据。
- 不做**变现**（广告、付费房间、打赏）——营利性会把民事风险推向刑事门槛。
- 不做**去标识**、不做「导出无元数据版本」。
- 不做**内置商业曲库指纹库**（那是版权方资产），只接 AcoustID 这类公开服务。
- 不替用户把文件传到任何第三方平台。

## 12. 待核实

- **接第三方生成 API 时是否需要备案**：《生成式人工智能服务管理暂行办法》对「面向境内公众提供生成服务」
  的要求，是否覆盖「用户自带 API Key、应用只做客户端」——需要看具体条款与监管口径。
- **C2PA 音频在 Dart 侧没有成熟实现**：`c2pa-rs` 有 FFI 与 CLI，要在 Flutter 桌面引入需评估打包与许可证
  （[C2PA 音乐资产指南](https://spec.c2pa.org/specifications/specifications/2.4/music/guidance_applying_content_credential_music_assets.html)）。
- **AcoustID 的服务条款与配额**：免费查询是否允许商用、是否需要 API Key、批量查询的限速。
- **「本机生成」的台账能否被伪造**：数据库在用户机器上，技术上可改；需要决定是否用应用内密钥对台账做
  哈希链（成本低，但只能防「随手改」，防不了逆向）。

## 13. M0 实施记录（2026-11-16）

已交付的代码（都在 `lib/` 下，与 §8 的分层一致）：

| 位置 | 管什么 |
| --- | --- |
| `data/services/mesh/mesh_protocol.dart` | 帧编解码：4 字节大端长度 + 1 字节类型 + 载荷；载荷是 JSON |
| `data/services/mesh/mesh_crypto.dart` | SHA-256 内容编号、HMAC-SHA256 房间证明、房间号派生、常量时间比较 |
| `data/services/mesh/mesh_identity.dart` | Ed25519 身份，落在 `<support>/share/identity.json`，`peerId = sha256(公钥) 前 16 字节` |
| `data/services/mesh/mesh_messages.dart` | HELLO / INVENTORY / WANT / BLOCK / REVOKE / PING / PONG，清单可签名 |
| `data/services/mesh/mesh_peer.dart` | 单条连接的握手、收发与关闭 |
| `data/services/mesh/mesh_room.dart` | 监听、拨号、成员表、广播（默认 8 人，硬上限 16） |
| `data/services/mesh/mesh_transfer.dart` | 256 KiB 分块收发、限速、收端重算内容编号 |
| `data/services/mesh/mesh_discovery.dart` | UDP 广播信标（端口 45871，2 秒一次、6 秒过期） |
| `data/services/mesh/room_invite.dart` | 邀请码 `tune-share1:<房间密钥>:<种子地址>` |
| `features/share/data/share_ledger.dart` | 本机生成台账（`<support>/share/ledger.json`） |
| `features/share/domain/` | 条目、缘起、AI 标识、准入闸门、声明、会话状态 |
| `features/share/application/share_session.dart` | 房间 ↔ 成员 ↔ 清单 ↔ 传输 ↔ 闸门的编排 |
| `features/share/presentation/share_pane.dart` | `/share` 页面：房间、我要分享的、房间里的、收件箱 |

与本文档原设计的偏差（以代码为准）：

- **载荷用 JSON，不是 CBOR**：少一个依赖；音频本身走分块，帧头开销可以忽略。
- **发现层用 UDP 广播信标，不是 mDNS**：同样少一个依赖，且不需要额外权限；mDNS 留作跨网段方案的备选。
- **Ed25519 提前进 M0**：清单签名是「收端不信发送端」的前提，比原计划早一步落地。
- **四份事实已并进 `library.db`**：M0/M1 先用 JSON 快照（收件索引、台账、举报、黑名单），M2 换成
  `share_rooms` / `share_items` / `share_events` 三张表；老快照由 `importLegacyShareJson` 于首次
  打开时搬入并改名 `*.migrated`（`docs/data-model.md` 的「分享的三张表」）。
- **M0 的加密只有对称层**：房间证明与内容寻址够用；分块载荷加密（X25519 + ChaCha20-Poly1305）随 M1 的凭据一起补。
- **入口在音源页底部一张卡**，没有设置页实验开关：少一个持久化开关，也少一处「关掉了但入口还在」的裂缝。

闸门的两处落点：发块前（`_onWant`）与收齐后（`_onBlock`）各跑一遍完整判定，
收端不信发送端的「我已经验过了」。台账命中是强证据，声明 + 证据哈希是次强，
生成物没有台账一律拒（`rejected_unproven_generation`）。

测试：`test/services/mesh_*`（协议 15、房间 9、传输 6、发现 6、身份 6、邀请码 5）与
`test/features/share_*` 与 `test/services/{mesh_*,room_invite}*`（闸门 19、会话 6、页面 2、台账 2、黑名单 2、
查重 8、配置 2、表与迁移 2、跨网 2、邀请码 5、可达探测 9），共 101 条。

### 13.1 跨网：自动探测可达地址（2026-11-17）

- **`data/services/mesh/mesh_reachability.dart`**（新）：`MeshReachability.probe({port})` 汇总局域网地址、
  公网 IPv6、路由器映射三类入口；`UpnpPortMapper`（SSDP → 描述 → `AddPortMapping` →
  `GetExternalIPAddress`）与 `NatPmpClient`（`/proc/net/route` 取网关，RFC 6886 请求）负责自动开端口。
  所有网络动作都有 2 秒预算，失败只影响那一条候选地址。
- **`data/services/mesh/room_invite.dart`**：邀请码升到 `tune-share2:`，载荷是 `seeds` 多地址（换行拼接后
  base64url）；`parseSeed`/`formatSeed` 处理方括号 IPv6；`tune-share1:` 旧码仍可解析。
- **`features/share/application/share_session.dart`**：`host()` 不再收地址，改为 `MeshReachability.probe()`
  的结果直接写进邀请码；`join()` 对邀请码里的所有地址**并发拨号**，首个成功的留下、其余关掉；
  状态里多一个 `isPubliclyReachable`，只用来显示「能不能跨网直连」。
- **`features/share/presentation/share_pane.dart`**：删掉「对外地址」对话框——页面上没有输入框、也没有
  一键穿透按钮；房间成立后只显示邀请码、本机端口，以及一行如实的状态（可跨网 / 仅同网）。
- 仍未做：打洞、中继、房间目录——见 §5.6 与 §11。

### 13.2 AI 标识落地：写入端补齐（2026-11-18）

§10 里 M1 的「AI 标识写入」此前只在清单（disclosure JSON）里登记，文件本身没有标识——
这一轮把它落到字节上，三件事同时交付：

- **隐式标识写入**：`share_label_facts.dart` 收口四个键（`AI_GENERATED` / `GENERATOR` /
  `CONTENT_ID` / `PRODUCER`）与容器口径；`share_label_writer.dart` 负责「写 + 回读核对」，
  FLAC/MP3 走 vendor 写侧（这次补齐了 vendor 的 FLAC `UNKNOWN=`、ID3v2 TXXX 与 MP4 自定义键），
  MP4 家族与 ogg/opus 走 ffmpeg（`-movflags use_metadata_keys` 这对开关不加，自定义键会被丢）；
  WAV 判 `unsupportedContainer`。写失败或回读对不上都是 `failed`，不降级成「当没写」。
- **提示音副本**：`share_copy.dart` 的 `ShareCopyBuilder` 在发布前生成副本——ffmpeg 合成
  1.2 秒节奏提示音前置，音频流不重编码（流复制），副本名带 `.ai-share.` 标记，落
  `<support>/share/outbox/<源编号前 12 位>/`；同源幂等覆盖。带语音版本留待素材录好再换。
- **准入与接线**：闸门新增 `admitted_from_label`——别人分享的 AI 副本不再要求本机台账命中，
  改为凭**读到的字节里的四条标识**放行（`share_admission.dart`，默认关闭，台账命中仍最强）。
  `share_session.dart` 的 `addLocalItem` 对生成物走「建副本 → 写标识 → 用副本字节重算编号」的
  管线，副本登记进 `_derivedCopies`：撤销副本时连原始件一起拉黑、关房时全部清理，
  outbox 不会无界增长。`revoke` 改成异步并先写黑名单再广播，撤销与举报的封禁口径对称。

测试：`test/features/share_label_writer_test.dart`（FLAC/MP3/opus/m4a 写入与回读、幂等、
不支持容器、损坏文件 fail-closed）、`test/features/share_copy_prelude_test.dart`（副本时长、
幂等、非生成物不建副本）、`test/features/share_admission_test.dart` 新增「字节里的隐式标识」
6 例、`test/features/share_ai_copy_e2e_test.dart` 两例真跑 ffmpeg 的端到端（生成 → 副本 →
广播 → 访客收下 → 撤销删副本），share 相关用例共 198 条全绿。

## 相关文档

- 国内音乐方案的评估结论：不做逆向接口、不内置商业曲库（评估稿未随本版发布）
- [音源设计](../需求/音源设计.md) — 音源类型与实例模型（本方案刻意不注册成音源）
- [架构](architecture.md) — 分层、依赖方向、加页面与扩展路径
- [数据模型](data-model.md) — 现有 14 张表与写库纪律（本方案的三张表已并入）
- [许可证与素材边界](licensing.md) — 新增依赖前要登记什么
