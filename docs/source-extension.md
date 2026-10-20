# 音源扩展：类型与实例

> 状态：**已定稿**（2026-10-21）。实现分三阶段，见 §8。
> 本文是音源扩展方式的设计说明。实现完成后，本文的结论会并回
> [`需求/音源设计.md`](../需求/音源设计.md)（那是音源模型的权威文档）。
> 相关：[architecture.md](architecture.md)（依赖方向与状态归属）、
> [chips.md](chips.md)（音源类别与图标）、[i18n.md](i18n.md)（文案规则）。

## 1. 为什么要改

现状是「13 个内置音源 = 13 种类型各恰好一个实例」。由此有三个问题：

1. **加不了第二个实例。** 用户只有一个 Jamendo、一个 Subsonic。想再挂一个服务器、
   换一个关键词，只能改掉原来的那一个。
2. **加不了新类型。** 适配器注册表用 `config.id` 当键，实例 id 与类型是同一个东西。
   界面上的「导入插件」是唯一的例外，而它走的是执行任意 JavaScript 的路子。
3. **任意脚本是合规风险。** 插件能执行任意代码并访问网络，等于给应用开了一个
   「谁来用、就替谁下载」的口子。这类能力不作为扩展方式，只保留**声明式参数**。

目标：音源 = **少量开箱即用的内置实例** + **一个「添加音源」入口**，
用户用声明式参数自己添加各种类型的音源。

## 2. 目标模型：类型与实例分离

```
MusicSourceType（类型 · 代码）
  ├─ type: 'rss'                  类型键，注册表用它查适配器
  ├─ name / description           本地化名
  ├─ kind                         界面分类（颜色、图标）
  ├─ adapter                      怎么取歌
  ├─ browseModes                  这个平台支持哪几种「无词浏览流」
  └─ fields                       用户填什么（configurationFields）
        │
        ▼
MusicSourceConfig（实例 · 数据）
  ├─ id: 'rss:1'                  实例唯一 id
  ├─ type: 'rss'                  指向类型
  ├─ name / description
  ├─ kind
  ├─ enabled
  ├─ settings                     该实例的参数
  └─ builtIn                      内置实例不可删
```

配套改动：

| 位置 | 改动 |
| --- | --- |
| `MusicSourceConfig` | 加 `type` 与 `builtIn`；`kind` 去掉 `plugin`，加 `custom` |
| `MusicSourceAdapter` | `sourceId` getter 改成 `sourceType`；扫描结果与 `failedResult(...)` 的 sourceId 改用 `request.config.id` |
| `MusicSourceService` | 适配器注册表按 **type** 键；`_adapterFor`、`supportsConfig`、`fieldsFor`、`isConfigured`、`configurationHint` 一律查 `config.type` |
| `BuiltInMusicSources` | 拆成「内置实例目录」与「类型元数据」两份 |
| `MusicSourceStore` | 读配置时迁移 `type`；丢弃插件实例 |
| `MusicSourcesController` | 名称与本地化名改按 `type` 查目录；删掉四个插件方法 |
| `sourceIconOf` | 查表键从实例 id 改成 `type` |

**兼容**：`type` 缺失时回退成 `id`。老配置里 `id == type`，回退后行为不变，
不需要数据迁移脚本。

### 2.1 名称与图标属于类型，不属于实例

品牌名、本地化名与图标是**类型**的属性。`jamendo:1` 与 `jamendo:2` 都画 Jamendo 的
图标、都叫 Jamendo；只有实例自己改了名字，才用实例的名字。

现在的代码是按实例 id 查这些的：`BuiltInMusicSources.catalogueOf(...)[config.id]`、
`sourceIconOf(config.id, kind)`。实例化之后必须一起改成按 `type` 查，否则用户加的
第二个 Jamendo 既没有品牌名，也拿不到 Jamendo 的图标，只能落到按类别兜底的通用图标。

## 3. 类型目录

「添加音源」能选的类型，就是全部适配器类型。内置实例只是其中几个预置的实例。

| type | 名称 | kind | 内置实例 | 浏览流 | 用户要填的参数 |
| --- | --- | --- | --- | --- | --- |
| `local` | 本地音乐 | `localDirectory` | `local` | — | 扫描目录（走全局设置） |
| `radio` | 网络电台 | `openCatalog` | `radio` | 台站目录 | 台站目录、关键词、数量 |
| `openverse` | Openverse | `openCatalog` | `openverse` | 最新 | 关键词（可留空） |
| `jamendo` | Jamendo | `openCatalog` | `jamendo` | 排行 | Client ID、关键词（可留空）、音质 |
| `internet_archive` | Internet Archive | `openCatalog` | `internet_archive` | 排行 | 查询条件（可留空）、数量 |
| `ccmixter` | ccMixter | `openCatalog` | `ccmixter` | 排行 | 标签（可留空）、数量 |
| `audius` | Audius | `openCatalog` | `audius` | 排行 | 关键词（可留空）、数量 |
| `wikimedia` | Wikimedia Commons | `openCatalog` | `wikimedia` | 最新 | 关键词（可留空）、数量 |
| `itunes` | iTunes | `openCatalog` | `itunes` | — | 关键词（必填）、数量 |
| `podcast_rss` | 播客 RSS | `openApi` | `podcast_rss` | — | feed 地址、数量 |
| `netease` | 网易云音乐 API | `openApi` | `netease` | 每日推荐 | API 地址、关键词（可留空）、数量 |
| `subsonic` | Subsonic | `openApi` | `subsonic` | — | 服务器、账号、密码、关键词、音质、数量 |
| `jellyfin` | Jellyfin | `openApi` | `jellyfin` | — | 服务器、账号、密码、数量 |
| `direct_url` | 直链音频 | `custom` | — | — | 一组音频地址（每行一条） |
| `m3u` | 播放列表 | `custom` | — | — | 播放列表地址（`.m3u` / `.pls`） |
| `json_api` | JSON 接口 | `custom` | — | — | 接口地址、字段路径映射、请求头 |
| `graphql` | GraphQL 接口 | `custom` | — | — | 接口地址、查询文档、变量、响应路径 |

`direct_url` / `m3u` / `json_api` / `graphql` 是新增类型，`json_api` 与 `graphql` 排到最后做（见 §6）。

**哪些类型站在顶层**：本地目录、网络电台，以及六个明确开放授权的曲库
（Openverse、Jamendo、Internet Archive、ccMixter、Audius、Wikimedia Commons）。
其余的内置类型（iTunes、播客 RSS、网易云 API、Subsonic、Jellyfin）要么要凭据，
要么有授权边界，摆在「更多音源」的折叠区里。类型自己声明这一点（适配器的
`featured`），界面不按 id 硬编码。

`json_api` 与 `graphql` 是同一件事的两档：JSON 接口够用时就用 JSON 接口，
接口需要「按条件挑」而 JSON 的路径映射表达不了时，换 GraphQL —— 它的查询文档
是声明式的，不是表达式，所以不违反 §7 的「不做求值」。

### 3.1 内置实例一个都不删

13 个内置实例全部保留，老用户的配置不丢。改的是**默认展示**与**默认取法**：

- **内置实例的名字与类型相同**（`Jamendo` 就是 `Jamendo`），取法改成平台自己的
  浏览流（推荐/排行/首页），关键词一律留空 —— 用户装完就能用，不用替应用想口味。
- **顶层**：本地目录、网络电台，以及明确开放授权的曲库
  （Openverse、Jamendo、Internet Archive、ccMixter、Audius、Wikimedia Commons）。
- **「更多音源」（折叠）**：iTunes（30 秒试听）、播客 RSS、网易云 API、
  Subsonic、Jellyfin —— 这些要么需要凭据，要么有授权边界，摆在折叠区不碍眼。
- **「我添加的」**：用户自己添加的实例，永远显示，不折叠。

折叠状态存进设置偏好（`SettingsController` 里的 `sources_more_expanded`，与
`auto_scan_on_startup` 同一套偏好存储），用户展开过一次就不再打扰。

### 3.2 浏览流与检索词

曲库型音源不一定要靠关键词。平台自己就有「每日推荐、排行、首页」这类**浏览流**，
它们不需要用户给词 —— 启动扫描默认拉的就是这些。

于是实例有两个参数：

| 参数 | 是什么 |
| --- | --- |
| `browse` | 浏览流（一个下拉框，选项由类型声明）。留空 = 按检索词搜 |
| `query` | 检索词（可留空）。留空 = 走浏览流；填了 = 按词搜，覆盖浏览流 |

**浏览流有哪些**（类型元数据声明，界面渲染成下拉框）：

| 值 | 含义 | 谁有 |
| --- | --- | --- |
| `latest` | 最新（首页、最新上传） | Openverse、Wikimedia、ccMixter |
| `charts` | 排行（人气、下载量、热歌榜） | Audius、ccMixter、Internet Archive、Jamendo |
| `daily` | 每日推荐 | 网易云 API（自建服务） |

**各类型的浏览流与实现**（带验证状态；`✅` 是本次实测有数据）：

| type | 浏览流 | 无词时怎么取 | 验证 |
| --- | --- | --- | --- |
| `audius` | `charts` | 换成 `/v1/tracks/trending` | ✅ |
| `ccmixter` | `charts` / `latest` | 去掉 `tags`；排行加 `sort=rank`，最新什么都不加（接口自己给最新的） | ✅ |
| `internet_archive` | `charts` | `q` 只留 `mediatype:audio`，`sort[]=downloads desc` 已经就位 | ✅ |
| `jamendo` | `charts` / `latest` | 不传 `search`；`order=popularity_total` 是排行，`order=release_date` 是最新 | 代码已支持 |
| `wikimedia` | `latest` | `generator=search` 换成 `generator=categorymembers`（分类即首页），要带 `gcmtype=file` | ✅ |
| `openverse` | `latest` | 去掉 `q` 参数 | ⚠️ 本机连不上，未验证 |
| `netease` | `daily` / `charts` | `/personalized`（每日推荐）或 `/top/song`（热歌榜） | ⚠️ 要自建服务，未验证 |
| `itunes` | 无 | `term` 是必填的，接口不提供无词列表 | — |

**浏览流放在实例的 `settings.browse` 里**，取值只能是该类型声明的那些；类型没有声明
浏览流时，这个字段不出现。适配器声明自己有哪些浏览流，第一个就是它默认的那条。

**「已配置」的定义跟着变**：有浏览流就等于已配置（不用填任何东西）；
只有不支持浏览流的类型（目前只有 iTunes）才要求填检索词。凭据还是要的：
Jamendo 没有 Client ID 照样扫不了，它只是不用填关键词。

**老用户的关键词**：内置实例以前由应用写死一个词（`piano`、`jazz`、`ambient`…），
那是应用的口味，不是用户的。这个词在实例「一个设置都没改过」时会被拿走，
平台自己的列表接上；用户改过的实例保留它写的词。

**类型只是类型，可以有很多个**：同一个类型下，用户可以加多个实例 ——
Jamendo 可以有一个走排行的、一个走检索「ambient」的；Subsonic 可以有一个接家、
一个接公司。区分它们的是**名字 + 参数**，不是类型。

## 4. 实例的命名与持久化

### 4.1 实例 id

| 来源 | id 规则 | 例子 |
| --- | --- | --- |
| 内置实例 | 沿用现有 id | `local`、`subsonic` |
| 用户实例 | `<type>:<序号>`，同类型内递增 | `rss:1`、`subsonic:1` |

id 可读、稳定、不会因为加实例而变动。老配置 id 不动，因此歌曲的 `sourceId`
与 `tune://<sourceId>/<externalId>` 身份标识不受影响。

### 4.2 持久化

`music_sources_v1` 的每条配置增加两个字段：

```json
{ "id": "rss:1", "type": "rss", "builtIn": false, "kind": "openApi", ... }
```

读取规则：

1. `type` 缺失 → 取 `id`（老配置）。
2. `builtIn` 缺失 → `id` 在内置目录里就是 `true`，否则 `false`。
3. `kind` 是 `plugin` → **丢弃**。插件能力下线后这些条目没有对应的适配器，
   留着只会在界面上变成打不开的音源。
4. 用户添加的实例默认**启用**；内置实例的开关照旧由用户自己管。

插件下线是一次性行为：代码、依赖、文案、测试一起删干净，不留「隐藏的入口」。

## 5. 界面

### 5.1 添加音源

```
「+ 添加音源」
   └─ 类型选择（列表：图标 + 名称 + 一句说明）
        └─ 参数表单（该类型的 configurationFields）
             └─ 保存 → 生成实例 id → 启用 → 回到列表
```

- 参数表单复用现有的 `_SourceSettingsDialog`，字段由适配器声明，界面不认识任何具体类型。
- 表单第一项是**名称**（可留空，默认取「类型名 + 序号」），用来区分同一类型的多个实例。
- 有浏览流的类型：表单是「浏览流（下拉，默认取平台最优解）」+「关键词（可留空）」
  两个字段，不给用户丢一个空必填框。
- 没有浏览流的类型（如 iTunes）：表单是「关键词（必填）」。
- 类型选择列表里排除「本地音乐」：本地目录是全局设置，不是可重复添加的实例。

### 5.2 删除

- 用户实例：右侧「⋯」菜单 → 删除（确认框）→ 移除配置 + 移除该源的歌曲
  （复用 `libraryController.dropSource`）。
- 内置实例：没有删除项，只能禁用。本地目录固定启用。
- 插件删除入口随插件一起下线。

### 5.3 顶级 / 更多音源 / 我添加的

三段都由 `MusicSourcesSection` 渲染，音源页与设置页共用它，不写第二份列表逻辑。
分区依据是 `builtIn` 与类型元数据里的 `featured` 标记，不按 id 硬编码。

## 6. 声明式参数

每种类型，用户填的都是**数据**，不是代码。没有表达式、没有函数、没有求值器。

### 6.1 JSON 接口（`json_api`，最后做）

| 参数 | 说明 |
| --- | --- |
| `url` | 接口地址，`${query}` 会被搜索关键词替换 |
| `method` | `GET`（默认）或 `POST` |
| `headers` | JSON 对象字符串，如 `{"Authorization":"Bearer …"}` |
| `body` | POST 时的 JSON 对象字符串，`${query}` 同样替换 |
| `listPath` | 列表在响应里的路径，如 `data.songs`；留空表示根就是数组 |
| `idPath` | 曲目唯一 id；留空则用数组下标 |
| `titlePath` / `artistPath` / `albumPath` / `coverPath` / `urlPath` | 各字段的取值路径 |
| `durationPath` / `genrePath` | 可选 |
| `urlTemplate` | 可选，播放地址模板，如 `https://host/track/${id}` |
| `limit` | 取前多少条 |

路径语法只有一条规则：`a.b.c` 逐段取 map 的键或数组的下标，取不到就当空值。
没有通配、没有过滤、没有拼接表达式 —— 复杂接口的展开交给别的类型。

安全边界：只允许 `http(s)` 地址；请求头只是字符串键值；不执行任何用户内容。

### 6.2 GraphQL 接口（`graphql`，与 JSON 接口同批做）

| 参数 | 说明 |
| --- | --- |
| `url` | 接口地址 |
| `query` | GraphQL 查询文档（声明式查询，不是表达式） |
| `variables` | JSON 对象字符串，`${query}` 会被搜索关键词替换 |
| `headers` | JSON 对象字符串 |
| `listPath` | 列表在响应里的路径，如 `data.tracks` |
| `idPath` / `titlePath` / `artistPath` / `albumPath` / `coverPath` / `urlPath` / `durationPath` / `genrePath` | 与 JSON 接口同一套取值路径 |

与 JSON 接口的区别只有一个：**筛选条件写在查询文档里**，而不是写在映射里。
其余（路径取值、请求头、曲目字段）完全共用同一份实现。

安全边界与 JSON 接口相同：只允许 `http(s)`；查询文档是 GraphQL，不是通用脚本；
应用不执行任何用户内容，只把变量填进请求。

### 6.3 直链音频（`direct_url`）

用户填若干行地址，每行一条；每条变成一首曲目，标题取文件名。

### 6.4 播放列表（`m3u`）

用户填一个 `.m3u` / `.m3u8` / `.pls` 地址，解析条目；每条变成一首曲目。
相对地址按播放列表地址的目录解析。

## 7. 明确不做

| 不做 | 原因 |
| --- | --- |
| MusicFree / LX Music 插件 | 执行任意脚本，合规风险；本设计用声明式参数替代 |
| HTML 选择器抓取 | 与 JSON 映射同构，且网页结构易变；先用 JSON 接口覆盖同类场景 |
| 表达式 / 脚本求值 | 一旦能求值，「声明式」就名存实亡 |
| 网盘、BT、磁力等协议 | 授权边界不清 |

## 8. 分阶段实施

每个阶段一次提交，阶段结束跑通门禁。

### 阶段 A · 地基

1. `MusicSourceConfig` 加 `type` / `builtIn`；`kind` 去掉 `plugin`、加 `custom`。
2. 适配器契约：`sourceId` → `sourceType`；扫描结果与 `failedResult(...)` 的 sourceId
   改用 `request.config.id`。
3. `MusicSourceService` 注册表按 type；`BuiltInMusicSources` 拆分。
4. 名称、本地化名与图标改按 `type` 查（见 §2.1）。
5. **内置实例改走浏览流**：删掉内置的默认检索词（`piano`、`jazz`、`ambient`…），
   改用平台自己的推荐/排行/首页（见 §3.2）；`isConfigured` 的判据跟着改成
   「有没有浏览流」。
6. `MusicSourceStore` 迁移与插件实例丢弃。
7. **下线插件**：删 `lib/data/services/music_sources/plugins/`（约 1400 行）、
   `flutter_js` 依赖、导入入口、相关文案（约 60 键 × 4 语言）、5 个测试文件。
   `Song.sourceData` **保留** —— Subsonic 的文件后缀、电台的正在播出、ccMixter 的
   来源都还在用它，它不是插件专用字段。
8. 界面分区：顶层 / 更多音源 / 我添加的。

### 阶段 B · 添加流程与新类型

9. 类型目录、添加对话框、实例创建与删除。
10. `direct_url` 适配器。
11. `m3u` 适配器。

### 阶段 C · JSON 接口与 GraphQL

12. 映射语法、`json_api` 适配器、表单 UI、测试。
13. `graphql` 适配器：复用同一套路径取值，只多一份查询文档与变量。

## 9. 验证

```bash
flutter analyze
flutter test
```

新增测试：

- `test/services/music_source_type_test.dart`：类型解析、`type` 回退、内置判定、
  类型是否属于顶层。
- `test/app/music_sources_section_test.dart`：三分区的顺序、「更多音源」的折叠与
  记住展开状态。
- `test/services/music_source_browse_test.dart`：各浏览流的请求形态（排行走 trending、
  最新走无词列表）、以及「有浏览流即已配置」的判定。
- `test/app/music_sources_add_test.dart`：添加实例、id 分配、删除实例与歌曲。
- `test/services/direct_url_source_test.dart` / `m3u_source_test.dart`：地址与条目解析。
- `test/services/json_api_source_test.dart`：路径取值与歌曲映射。
- `test/services/graphql_source_test.dart`：查询文档与变量、响应路径取值。

删除：`test/services/music_plugin_adapter_test.dart`、`music_plugin_http_test.dart`、
`music_plugin_repository_test.dart`、`music_plugin_runtime_test.dart`、
`music_plugin_url_test.dart`。

## 10. 同步的文档

实现完成后逐份更新：

| 文档 | 改什么 |
| --- | --- |
| `需求/音源设计.md` | 重写 §1、§2、§4、§7；删 §4.1、§4.1.1；补类型目录与迁移 |
| `需求/README.md` | 音源设计那行的简介：去掉「MusicFree JS 插件」 |
| `需求/紧凑播放器重构方案.md` | 验证一节里「3 个 QuickJS 插件测试默认跳过」要改成插件下线后的测试数 |
| `docs/architecture.md` | 音源章节的类型 / 实例模型；「加一个音源」的扩展路径改成「注册一个类型」 |
| `docs/chips.md` | 音源类别表（删 `plugin`，加 `custom`）；「13 个内置音源各有一个自己的图标」改成按类型查 |
| `docs/conventions.md` | 测试隔离那句里的「插件存储」改成「音源脚本/插件目录」或直接删掉 |
| `docs/localization-audit.md` | 门禁没画到的界面里去掉「插件安装对话框」，加上新的「添加音源」对话框 |
| `需求/多语言设计.md` | 音源名字规则（实例名 vs 类型名） |
| `README.md` | 已知限制：删插件相关，写明「不支持任意脚本插件」 |
| `CHANGELOG` | 记录插件能力下线与迁移行为 |
