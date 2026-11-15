# 故障排查

> 状态：设计（已实施） · 适用版本 1.32.0 · 最后核对 2026-11-15

> 这份文档只处理「用不了」；要改代码、跑门禁、提 PR，看 [CONTRIBUTING.md](../CONTRIBUTING.md)。

先在下面的「一分钟自查」里找到对应现象，再做一次最小复现（三步以内），最后带上版本号与平台信息反馈——[SUPPORT.md](../SUPPORT.md) 的「提缺陷前先做三件事」同样适用：先升级到最新版，先搜已有 issue，先确认不是上游服务自己的问题。

## 目录

- [一分钟自查](#一分钟自查)
- [音乐库是空的](#音乐库是空的)
- [某个音源搜不到或播放失败](#某个音源搜不到或播放失败)
- [播放中途失败](#播放中途失败)
- [歌词不出来](#歌词不出来)
- [本地组件下载失败](#本地组件下载失败)
- [更新检查失败](#更新检查失败)
- [托盘与媒体控制不生效](#托盘与媒体控制不生效)
- [双击文件不开 Tune 或开出两个进程](#双击文件不开-tune-或开出两个进程)
- [解压发行包后启动报插件加载失败](#解压发行包后启动报插件加载失败)
- [启动慢或内存占用高](#启动慢或内存占用高)
- [Android 上的问题](#android-上的问题)
- [自己从源码跑时的报错](#自己从源码跑时的报错)
- [怎么提供有效信息](#怎么提供有效信息)

## 一分钟自查

| 你看到的 | 先看哪 |
| --- | --- |
| 音乐库一首歌都没有，或扫描完还是 0 首 | [音乐库是空的](#音乐库是空的) |
| 某个音源搜不到歌、点了播不出来，别的音源正常 | [某个音源搜不到或播放失败](#某个音源搜不到或播放失败) |
| 播到一半失败，过一阵再播同一首又失败 | [播放中途失败](#播放中途失败) |
| 歌词区一直空着，或显示「无歌词」 | [歌词不出来](#歌词不出来) |
| 设置 → 本地组件 下载卡住、失败，翻译 / 智能歌词 / 转码用不了 | [本地组件下载失败](#本地组件下载失败) |
| 设置 → 关于 点「检查更新」没反应或报检查失败 | [更新检查失败](#更新检查失败) |
| 没有托盘图标、媒体键不管用、关窗后退出、设默认播放器失败 | [托盘与媒体控制不生效](#托盘与媒体控制不生效) |
| 双击音频文件没打开 Tune，或又开了一个进程 | [双击文件不开 Tune 或开出两个进程](#双击文件不开-tune-或开出两个进程) |
| 启动慢、播放时卡、内存占用高 | [启动慢或内存占用高](#启动慢或内存占用高) |
| Android 上没有通知 / 后台停播 / 扫描不到 / 词稿写不进去 | [Android 上的问题](#android-上的问题) |
| 解压发行包后启动报插件加载失败 | [发行包里的 `tune` 不能单独拷出来](#解压发行包后启动报插件加载失败) |

## 音乐库是空的

**现象**：进「音乐库」一首歌都没有；点扫描后提示「扫描完成」，数量仍是 0。

**可能原因**：没在 `设置 → 音乐库` 添加扫描目录，或目录里没有音频文件（[SUPPORT.md](../SUPPORT.md)）；文件不在列出的目录下（[architecture.md](architecture.md) 的「音乐库的目录」）；Android 的媒体权限被拒，扫描会引导「去设置」而不是悄悄扫出空库（[android.md](android.md) §2 E2）；Android 读的是系统媒体库而不是文件目录（[android.md](android.md) §2 E3）。

**怎么确认**：看 `设置 → 音乐库` 的目录列表与「扫描完成」提示，再扫一次看数字是否变化；在文件管理器里确认目录下确实有 `.mp3` / `.flac`；Android 到系统设置 → 应用 → Tune → 权限看「音乐和音频」，设置页的「权限」分区只有 Android 出现（[android.md](android.md) §2 E2）。

**怎么处理**：

- 「添加文件夹」重选目录或「更换位置」，然后扫描。
- Android 权限被永久拒绝时按提示点「去设置」打开权限，再回来扫描。
- Android 要指定系统媒体库之外的目录，用「更换位置」走 SAF 选择器选可读目录（[android.md](android.md) §5）。
- 「清空音乐库」只清 Tune 的索引，不会删磁盘上的音乐文件（[architecture.md](architecture.md) 的「音乐库的目录」）。

## 某个音源搜不到或播放失败

**现象**：搜索或浏览时某个音源没有结果，或点播放报错；其它音源正常。

**可能原因**：该音源服务端或上游接口本身有问题（[SUPPORT.md](../SUPPORT.md) 的「常见的其实不是 bug」）；自建服务（Navidrome / Jellyfin / Emby / Plex / Subsonic / Ampache / Koel 等）的地址、账号或网络不通；该实例健康度低——健康度里「未知」不按中性算，从未扫描成功、字段缺失都会压低分数，低分主要影响推荐里的权重，不等于音源坏了（[health-unknown.md](health-unknown.md)）。

**怎么确认**：用浏览器打开那个音源的网页界面，用它自己的搜索与播放确认服务端正常（[SUPPORT.md](../SUPPORT.md)）；`设置 → 健康度` 看该实例的分数与维度；换一个音源播同一首歌做对照。

**怎么处理**：

- 上游问题就修上游：服务重启、账号权限、网络或反向代理。
- 重填或重建该音源实例，然后重新扫描。
- 分数长期偏低但能正常用时不用管，它只在推荐排序里被降权（[README.md](../README.md) 的「音源」）。
- 音源凭据以明文存在 `<应用支持目录>/settings/`（Linux 是 `~/.local/share/cn.iouf.tune/settings/`），不进系统钥匙串；请给音乐服务器用独立账号（[SECURITY.md](../SECURITY.md) §1）。

## 播放中途失败

**现象**：一首远程歌播到一半报错停止；隔一段时间再播同一首，又失败。

**可能原因**：远程播放地址会过期（[README.md](../README.md) 的「已知限制」）；只有实现了单曲刷新的音源能自己换新地址，即 Subsonic / Navidrome、Ampache、Koel、Emby、Plex、Jellyfin、Deezer、播客 RSS，其余要重新扫描（[README.md](../README.md) 的「音源」）。

**怎么确认**：同一首改用本地文件或另一个音源播放，是否正常；重新扫描该音源后立刻播放同一首，是否恢复。

**怎么处理**：

- 上面那 8 类音源支持单曲刷新，重新播放时会重新解析地址（[README.md](../README.md)）。
- 其它音源：重新扫描该音源后再播。
- 经常要重扫的曲目，用「下载」留一份本地副本；副本旁边有 `<歌名>.tune` 标记，扫描后仍算同一首（[architecture.md](architecture.md) 的「音乐库的目录」）。

## 歌词不出来

**现象**：正在播放页的歌词区一直空着，或显示「无歌词」。

**可能原因**：本地歌词匹配依赖文件名与元数据，曲目目录或内嵌里没有歌词（[SUPPORT.md](../SUPPORT.md)）；智能歌词的本地组件没装或不可用（[local-components.md](local-components.md) §7）；Android 上批量 / 自动补词整体停用，MediaStore 的曲目没有写词落点，只有 SAF 树内的曲目能生成（[android.md](android.md) §4、§5.3）。

**怎么确认**：看曲目目录里有没有 `<歌名>.lrc` / `<歌名>.manual.lrc` / `<歌名>.smart.lrc`（[architecture.md](architecture.md) 的「持久化」）；`设置 → 本地组件 → 智能歌词` 的状态是不是「可用」，失败时展开「详细信息」看原因；Android 上确认这首歌在 SAF 选中的目录里，而不是只在系统媒体库里。

**怎么处理**：

- 放一份同名 `.lrc` 到曲目目录；想保留自己的版本就用「指定歌词」，写的是 `<歌名>.manual.lrc`，不覆盖已有的 `<歌名>.lrc`（[architecture.md](architecture.md) 的「音乐库的目录」）。
- 装好智能歌词组件后单曲重新生成；Android 上只能一首一首来（[android.md](android.md) §5.3）。
- Android 的 SAF 授权被收回时，重新选一次音乐库文件夹再生成。

## 本地组件下载失败

**现象**：`设置 → 本地组件` 里下载卡住、显示「失败：…」或「部分完成」，翻译 / 智能歌词 / 音频转码因此用不了。

**可能原因**：组件从 GitHub Release 与 HuggingFace 下载（Fun-ASR-Nano 主源 `huggingface.co`、镜像 `hf-mirror.com`），网络不可达时逐个源失败（[local-components.md](local-components.md) §6）；磁盘余量不够，各档位建议在下载量之外再留 500 MB–1 GB（[local-components.md](local-components.md) §7.6）；校验不通过——每个文件都要过字节数与 sha256，镜像也不降低校验强度，不符就不算就绪（[local-components.md](local-components.md) §6）。

**怎么确认**：看卡片状态胶囊是 `失败：原因` / `部分完成 · 已完成 n/m` / `校验中`（[local-components.md](local-components.md) §7.1）；展开「详细信息」看每个文件的来源域名、字节数与失败项；`df -h ~/.local/share/cn.iouf.tune/components` 看剩余空间。

**怎么处理**：

- 点「重试」；「部分完成」点「继续」只补没装完的组件，已完成的保留（[local-components.md](local-components.md) §7.4）。
- 换网络或代理后重试；同一个文件会按主源 → 镜像的顺序重新尝试（[local-components.md](local-components.md) §6）。
- 清理不需要的档位：功能项「删除」会删掉该功能项下所有可删组件（含未选中的档位），系统自带的副本不动（[local-components.md](local-components.md) §7.4）。
- 系统里已有 `ffmpeg` / `whisper-cli` / `llama-cli` 时优先用系统版本，卡片写「使用系统已安装版本」（[local-components.md](local-components.md) §3）。
- 内网或镜像环境可用 `TUNE_COMPONENT_BASE_URL` 覆盖下载基址（只从 `<base>/<id>/<文件名>` 取），这是给测试与镜像用的，不是普通设置项（[local-components.md](local-components.md) §6）。

## 更新检查失败

**现象**：`设置 → 关于` 点「检查更新」没反应，或显示「检查失败：…」；后台也不提示新版本。

**可能原因**：后台检查不是实时的——启动 60 秒后首查，之后每 1 小时 ±10%，两次自动检查至少隔 15 分钟，失败按 30 分钟 → 1 小时 → 2 小时退避，手动检查不受节流（[update-cdn.md](update-cdn.md) §4.3）；网络到不了 jsDelivr 与 raw.githubusercontent.com（中国大陆常见），三档取数全部失败（[updates.md](updates.md) 的「限制」、[update-cdn.md](update-cdn.md) §9）；两份清单不一致时直接拒绝本次更新并报 `manifestMismatch`（[update-cdn.md](update-cdn.md) §4.1、§4.4）；下载完成但字节数或 sha256 不符，会删掉临时文件并提示重试（[update-cdn.md](update-cdn.md) §4.4）。

**怎么确认**：手动点一次「检查更新」，看失败分类是网络超时 / 异常响应 / 清单不一致（[update-cdn.md](update-cdn.md) §4.4）；看标准输出里的取数日志——每个地址每轮一条 `info`，内容是「主机 + 结果 + 耗时」，304 写「沿用上次解析」（[update-cdn.md](update-cdn.md) §4.3.1）；`curl -s https://cdn.jsdelivr.net/gh/pengtang1024/tune@master/version.json` 看能不能取到清单。

**怎么处理**：

- 手动重试；失败退避是设计行为，等下一轮即可（[update-cdn.md](update-cdn.md) §4.3）。
- 换网络后重试；静态清单两档都不可达时才会走 GitHub API 兜底（[updates.md](updates.md)）。
- 提示「两份更新清单不一致」属于发布侧问题，不是你机器的问题，等修复或按 [SUPPORT.md](../SUPPORT.md) 反馈。
- 三档全失败时如实报「检查失败」，不会说成「已是最新」（[updates.md](updates.md) 的「限制」）。

## 托盘与媒体控制不生效

**现象**：托盘没有图标；键盘媒体键或 `playerctl` 控制不了；点关闭后进程退出、音乐停了；「设为默认播放器」失败。

**可能原因**：托盘、MPRIS、默认播放器只有 Linux 桌面提供，Windows 没有托盘、SMTC，也没有自动更新（[README.md](../README.md) 的「已知限制」、[SUPPORT.md](../SUPPORT.md)）；`设置 → 桌面` 的「关闭窗口时最小化到托盘」或「在系统媒体中心显示 Tune」被关掉（[桌面集成方案.md](../需求/桌面集成方案.md) §7）；桌面项没装，设默认播放器会直接报「先安装桌面项」（[桌面集成方案.md](../需求/桌面集成方案.md) §6.1）。

**怎么确认**：`playerctl status` 能不能读到 Tune，`busctl --user introspect org.mpris.MediaPlayer2.tune /org/mpris/MediaPlayer2` 能不能看到两个接口（[桌面集成方案.md](../需求/桌面集成方案.md) §9）；`xdg-mime query default audio/mpeg` 看返回的是不是 `cn.iouf.tune.desktop`；看 `设置 → 桌面` 两个开关的状态。

**怎么处理**：

- 打开两个开关；MPRIS 关掉会释放总线名，媒体键自然失效（[桌面集成方案.md](../需求/桌面集成方案.md) §7）。
- 装桌面项：`./linux/install-desktop-entry.sh`，再点「设为默认播放器」（[README.md](../README.md) 的「桌面图标」）。
- 托盘走 StatusNotifierItem 协议，菜单走 dbusmenu（`com.canonical.dbusmenu`），两者都由纯 Dart 的 `dbus` 包实现，不需要额外的原生依赖。它注册到面板上的 `org.kde.StatusNotifierWatcher`，**找不到这个 watcher 就不显示图标**——GNOME 需要装 AppIndicator / KStatusNotifierItem 一类扩展，KDE、XFCE 等自带面板通常已有。这种情况日志里会是「托盘图标的总线名已被占用，放弃注册」或直接的失败记录，程序不会崩。

## 双击文件不开 Tune 或开出两个进程

**现象**：双击 `.mp3` 没反应或被别的播放器接手；`tune a.mp3` 不播；第二次双击又开一个窗口或进程。

**可能原因**：桌面项缺 `%U` 或 `MimeType`，系统不会把音频文件交给 Tune（[桌面集成方案.md](../需求/桌面集成方案.md) §6.1）；还没设成默认播放器（[桌面集成方案.md](../需求/桌面集成方案.md) §7）；单实例在 Linux 靠会话总线名 `cn.iouf.tune`、在 Windows 靠只监听回环地址的 TCP 端口 47321，Windows 端口被别的程序占用时会退化为独立运行（[SECURITY.md](../SECURITY.md) §3、[architecture.md](architecture.md) 的「Windows 桌面集成待办」）。

**怎么确认**：`xdg-mime query default audio/mpeg`；`pgrep -af tune` 看有几个进程；从终端跑 `tune <文件>`，看标准输出里有没有「已有播放器在运行，把文件交给它」。

**怎么处理**：

- 重装桌面项后再设默认播放器（[README.md](../README.md) 的「桌面图标」）。
- 单实例失效时先把所有 Tune 进程退干净再启动。
- Windows 上端口被占用只能独立运行，这是已知限制（[README.md](../README.md) 的「已知限制」）。

## 解压发行包后启动报插件加载失败

**现象**：从 `tune-linux-x64-<version>.tar.gz` 解压后启动，报找不到 `libapp.so`、插件加载失败，或者窗口能开但界面空白。

**可能原因**：发行包放的是 bundle 的内容，`tune` 必须和它旁边的 `lib/`、`data/`、`share/` 处在同一层（[updates.md](updates.md) 的「产物约定」）；只把 `tune` 一个文件拷到别处，或者解压时只提取了 `tune`，这些目录就丢了。

**怎么确认**：`ls` 一下 `tune` 所在目录，看有没有 `lib/` 与 `data/`；从终端启动看报错原文——找不到 `libapp.so` 是 bundle 不完整，`error while loading shared libraries` 是缺系统库，后者用 `ldd ./tune | grep "not found"` 能列出缺哪个。

**怎么处理**：

- 整包重新解压，`tune`、`lib/`、`data/`、`share/` 保持同层，要挪位置就整个目录一起挪。
- 装到固定路径用仓库里的 `./tool/upgrade_local.sh ~/.local/opt/tune`，它会自己处理目录与替换，别手工拼（[updates.md](updates.md)）。
- 缺系统库按发行版装对应的 `libmpv`、GTK 3 运行库；桌面项要指向 `tune` 的真实路径，重装跑 `./linux/install-desktop-entry.sh`。

## 启动慢或内存占用高

**现象**：冷启动要等几秒；曲库很大时滚动、搜索发涩；播放中内存涨到几百 MB 甚至更高。

**可能原因**：曲库大——超过 1000 首时首帧只读第一窗，翻页再从 SQLite 取，这是设计，不是全库驻留（[architecture.md](architecture.md) 的「持久化」）；损坏标签——某个文件的标签声明了 GB 级帧，修复前会把启动内存抬到约 1.5 GB（[performance.md](performance.md) §10 D8，已修）；启动串行读偏好、每次停顿重扫全表等旧问题（[performance.md](performance.md) §12 D10、§1 的 D1–D11 结论，均已修）。

**怎么确认**：`设置 → 关于` 确认版本，先升级到最新版本再判断；`ps -o rss= -p $(pgrep -n tune)` 采样常驻内存，隔几秒再采一次，看是否持续上涨；`flutter run -d linux` 跑一遍复现路径，看输出里有没有 `[E]` 开头的错误（损坏标签、解码失败等）。

**怎么处理**：

- 升级到最新版本，这些修复已并入主线（[performance.md](performance.md) §1）。
- 仍复现时用二分法缩小范围：把音乐库目录分几批移出扫描范围，看是哪一批触发，内存异常高时尤其有效。
- 按下面「怎么提供有效信息」附上内存采样与复现路径。

## Android 上的问题

**现象**：Android 上没有播放通知 / 切后台就停；扫不到歌；智能歌词不能批量生成，或提示「词稿无处可写」。

**可能原因**：权限——Android 13+ 要 `POST_NOTIFICATIONS` 与 `READ_MEDIA_AUDIO`，12 及以下要 `READ_EXTERNAL_STORAGE`，拒绝后扫描会引导「去设置」（[android.md](android.md) §2 E2）；后台播放靠 `audio_service` 前台服务，耳机实体按键、锁屏视觉与长时间后台仍需真机复核（[README.md](../README.md) 的「已知限制」、[android.md](android.md) §2 E1）；智能歌词在 Android 上 ffmpeg 不可执行，批量 / 自动补词整体停用，MediaStore 行没有写词落点，只有 SAF 树内的曲目能生成（[android.md](android.md) §4、§5.3）；SAF 授权被收回时，生成词稿前会直接判 `unsupported`，不会重试（[android.md](android.md) §5.3）。

**怎么确认**：设置页「权限」分区（只有 Android 出现）看两项权限，系统设置 → 应用 → Tune → 通知 / 音乐和音频；播放时下拉通知栏，看有没有媒体会话与三个动作；智能歌词失败时看提示是「无处可写」还是「写权限已被收回」（[android.md](android.md) §5.3）。

**怎么处理**：

- 去系统设置把权限打开，再回 Tune 重新扫描。
- 词稿写不进去：重新选一个可写的音乐库文件夹（SAF），只对 SAF 树内的曲目生成。
- 批量补词在 Android 不提供，改单曲生成；后台仍被系统停掉时，带上机型、ROM 版本与复现步骤反馈（真机差异未验，见 [android.md](android.md) §3）。

## 自己从源码跑时的报错

**现象**：`flutter analyze` 在中文路径下报 `FormatException: Unexpected end of input`；联网测试失败。

**可能原因**：工程路径里有中文时，Flutter 3.47.x 的分析服务会收到截断的 LSP 报文，这是 SDK 自身 bug，本地靠补丁绕过，而 `flutter upgrade` 会把补丁冲掉（[verification.md](verification.md) 的「门禁的前提：SDK 补丁」）；`test/services/` 里的联网用例访问真实外部服务，离线或外部服务 404 时失败属正常（[verification.md](verification.md) 的「联网测试」）。

**怎么确认**：报错原文是否就是 `FormatException: Unexpected end of input`，且工程路径含中文；`./tool/live_sources.sh` 单独跑那两个文件，看是网络问题还是映射问题（[verification.md](verification.md)）。

**怎么处理**：

- 按 [verification.md](verification.md) 重打补丁并重建工具快照；临时兜底用 `dart analyze`。
- 联网测试失败先确认网络与上游服务；实测过单次请求 26 秒的情况，那种失败不是代码问题（[verification.md](verification.md)）。

## 怎么提供有效信息

按 [SUPPORT.md](../SUPPORT.md) 的模板填，四样东西缺一样都会让排查变慢：

1. **版本**：`设置 → 关于` 里的完整版本号与构建号（形如 `1.32.0+52`）。
2. **环境**：Linux 发行版与版本、桌面环境（GNOME / KDE / 其它）、是否 Wayland、自己编译还是装了发行包；Android 写机型、系统版本与 ROM。
3. **最小复现**：三步以内，写清点了哪里、选了哪个音源、期望什么、实际什么。
4. **日志**：Tune 没有单独的日志文件，排障日志打在标准输出——用 `flutter run -d linux` 跑一遍复现路径，或从终端启动安装版，把输出贴上来。

贴之前先脱敏：音源密码、API Key、token、Cookie 都不要贴，完整家目录路径替换成 `~`（[SUPPORT.md](../SUPPORT.md)）。日志里出现凭据请直接删掉那一行。

安全漏洞（凭据泄漏、路径穿越、更新链劫持等）不要开公开 issue，按 [SECURITY.md](../SECURITY.md) 私下报告。

只想知道某个功能为什么不能用、该怎么设置，走「使用问题」模板；确定是可复现缺陷再用「缺陷报告」模板（[SUPPORT.md](../SUPPORT.md)）。

## 相关文档

- [文档索引](README.md) — 先确认该看哪份文档
- [音源设计](../需求/音源设计.md) — 来源权重、健康度与排序
- [本地组件](local-components.md) — 组件注册、下载校验与设置页
- [自动更新](updates.md) — 数据源、产物命名与发布步骤
- [推荐](recommendation.md) — 发现页的模型、入口与隐私边界
- [参与贡献](../CONTRIBUTING.md) — 改代码、跑门禁、提 PR

