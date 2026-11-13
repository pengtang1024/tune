# 规范：离线翻译模型随包分发（Git LFS）

状态：待批准（批准后才动代码）
日期：2026-11-11
相关：`docs/licensing.md`、`docs/updates.md`、`AGENTS.md`、`lib/data/services/translation/`、`lib/features/localization/`

## 1. 目标

把 Qwen2.5-0.5B-Instruct（q4_k_m）从「首次运行下载」改为「随安装包分发」：

1. 模型与 llama.cpp 运行时由仓库内的 Git LFS 文件提供，不再由应用联网下载。
2. 打包脚本直接从 LFS 工作区路径读取模型，不在仓库或构建目录里复制第二份。
3. 首次启动不联网；模型缺失、被 LFS 指针替代或校验失败时回退原文，设置页提示重装，不崩溃。
4. 启动不加载模型；实测并给出首帧影响。
5. 许可：随包带 Qwen 的 Apache-2.0 LICENSE/NOTICE 与 llama.cpp 的 MIT 声明，更新 `docs/licensing.md`。
6. 给出改前/改后安装包体积，更新 Linux 产物说明。

不做：Windows/macOS/Web 分发；多量化版本；模型热更新；应用内下载/删除模型。

## 2. 现状（已核实）

- 模型：`qwen2.5-0.5b-instruct-q4_k_m.gguf`，491,400,032 B，
  sha256 `74a4da8c9fdbcd15bd1f6d01d621410d31c6fc00986f5eb687824e7b93d7a9db`。
- 运行时：llama.cpp `b12274` ubuntu-x64 归档 23,287,295 B（sha256
  `5f9de4d1…bcd94`），解包 57 MB
  （`llama-cli` 1.5 MB + 共享库 45 MB + 其它 CLI 工具）。
- `TranslationAssets` 现在用 dio 从 HuggingFace/GitHub 下载到
  `getApplicationSupportDirectory()/translation`，`LocalModelController` 管下载/删除，
  设置卡有下载进度与删除按钮。
- 引擎 `LlamaLocalTranslationEngine` 每批 `Process.start` 一次 `llama-cli`，启动时不预加载。
- 当前发布产物 `dist/tune-linux-x64-1.29.0.tar.gz` = 42,560,141 B（未含模型）。
- 本机 `git-lfs 3.7.1` 已安装；仓库 `.git` 98 MB。
- `tool/package_linux.sh` 把 `build/linux/x64/release/bundle` 的根直接打成 tar.gz。

## 3. 决策与取舍

### 3.1 打包方式：sidecar 目录，不走 Flutter assets

选择：仓库 `translation/` 目录 + 发布包内 `translation/` sidecar，运行时按
`Platform.resolvedExecutable` 定位。

| 方案 | 体积 | 构建时间 | 运行时读取 |
| --- | --- | --- | --- |
| Flutter assets | 额外复制进 `build/flutter_assets`，模型进 asset bundle | 每次构建复制 491 MB，慢且占双份磁盘 | 需 `rootBundle` 落盘才能给子进程用，等于再复制一份 |
| sidecar（选定） | 只随发布包一份；构建不碰模型 | 打包时从工作区直接 tar，无复制 | 直接给 `llama-cli -m <绝对路径>` |

### 3.2 LFS 目录布局（模型与运行时都进 LFS）

```
translation/
  models/qwen2.5-0.5b-instruct-q4_k_m.gguf   # LFS
  bin/llama-b12274-bin-ubuntu-x64.tar.gz      # LFS，运行时归档
  bin/llama-b12274/                           # 构建时解包，.gitignore
  licenses/Qwen2.5-LICENSE.txt                # Apache-2.0 全文（普通文本）
  licenses/Qwen2.5-NOTICE.txt                 # 版权与模型卡署名（普通文本）
  licenses/llama.cpp-LICENSE.txt              # MIT 全文（普通文本）
```

`.gitattributes`（新增）：

```
translation/models/*.gguf filter=lfs diff=lfs merge=lfs -text
translation/bin/*.tar.gz filter=lfs diff=lfs merge=lfs -text
```

只保留 q4_k_m 一个量化版本；不新增其它 gguf。运行时归档固定为
`llama-b12274-bin-ubuntu-x64.tar.gz`（23,287,295 B，sha256
`5f9de4d104502b38fdb1081d00087683ca224ca5c450eaba4eeb436b9a1bcd94`），
由 `tool/prepare_translation.sh` 校验并解包到 `translation/bin/llama-b12274/`，
不再联网下载。

### 3.3 运行时定位顺序

`TranslationAssets.resolve(...)`（可测试的静态方法）：

1. 环境变量 `TUNE_TRANSLATION_DIR`（测试/开发显式指定）。
2. `<可执行文件目录>/translation`（发布包）。
3. 从可执行文件目录向上最多 6 层，找 `translation/models/<模型>`（`flutter run` 开发）。
4. `<应用支持目录>/translation`（旧版下载遗留，兼容读取，不再写入）。

找不到任何候选时返回指向第 2 项的实例，状态为「模型缺失」。

## 4. 代码改动（逐文件）

### 4.1 `lib/data/services/translation/translation_assets.dart`（重写）

- 删除 `dio` 下载、tar 解包、`download()`、`deleteAll()`。
- 保留常量：`binaryVersion`、`modelFileName`、`modelBytes`、`modelSha256`。
- 新增：

```dart
enum TranslationAssetProblem { none, modelMissing, modelCorrupt, binaryMissing }

class TranslationAssetStatus {
  final TranslationAssetProblem problem;
  bool get ready => problem == TranslationAssetProblem.none;
}

class TranslationAssets {
  TranslationAssets(this.root, {this.expectedModelBytes = modelBytes, this.expectedModelSha256 = modelSha256});

  static TranslationAssets resolve({
    required String executablePath,
    required String supportPath,
    Map<String, String>? environment,
    int maxParents = 6,
  });

  static Future<TranslationAssets> forApp();

  Directory get binDirectory;      // <root>/bin
  File get modelFile;              // <root>/models/<name>
  Future<String?> findBinary();    // recursive llama-cli
  Future<TranslationAssetStatus> inspect({bool verifyDigest = false});
}
```

- `inspect` 规则：
  - 模型不存在 → `modelMissing`。
  - 文件大小 ≠ `expectedModelBytes` → `modelCorrupt`（同时覆盖 130 B 的 LFS 指针）。
  - `verifyDigest` 时用 `Isolate.run` 算 sha256 并缓存；不符 → `modelCorrupt`。
  - 模型正常但找不到 `llama-cli` → `binaryMissing`。
- 不再保留任何网络调用；`dio` 依赖本身保留（其它模块在用）。

### 4.2 `lib/features/localization/application/local_model_controller.dart`

- 阶段改为 `checking / ready / missing / corrupt / failed`，字段保留 `message`。
- 删除 `download()`、`delete()`、进度字段。
- `refresh()` 调 `assets.inspect(verifyDigest: true)`；`TranslationAssetException` 可保留供引擎使用，或删除未引用部分。
- provider 保持不变（`onAssetsChanged` 仍用于安装/重装后重建仓库，可保留）。

### 4.3 `lib/features/localization/presentation/settings_localization_card.dart`

- `_LocalModelBlock`：显示状态文案；仅 `missing/corrupt` 显示「请重新安装应用」的说明；
  删除下载按钮、进度条、删除按钮。
- 不再读 `state.progress`。

### 4.4 `lib/data/services/translation/llama_local_translation_engine.dart`

- `translate()` 开头：
  1. `findBinary()`，为空 → `TranslationException(unavailable: true)`。
  2. `inspect(verifyDigest: true)`，非 ready → 按问题抛 `unavailable`。
- 其余（每批一个进程、`LD_LIBRARY_PATH`、ChatML）不变。
- 不改启动路径：应用启动不创建引擎、不读模型。

### 4.5 文案（4 个 ARB + gen-l10n）

`lib/l10n/app_zh_CN.arb`（模板）、`app_en.arb`、`app_zh.arb`、`app_zh_TW.arb`：

删除：`settingsLocalizationLocalDownloading`、`settingsLocalizationLocalDownload`、
`settingsLocalizationLocalPending`。

修改：`settingsLocalizationLocalReady`、`settingsLocalizationLocalMissing`。
新增：`settingsLocalizationLocalCorrupt`、`settingsLocalizationLocalBundled`。

生成：`flutter gen-l10n`，提交生成产物。

## 5. 构建与打包

### 5.1 新增 `tool/prepare_translation.sh`

1. `command -v git-lfs`，缺失则报错退出（提示 `git lfs install`）。
2. 检查 `translation/models/*.gguf`：
   - 不存在 → 提示 `git lfs install && git lfs pull`。
   - 大小 < 1 KB 且内容以 `version https://git-lfs.github.com/spec/v1` 开头
     → 判定为 LFS 指针，报同样的提示并退出。
3. 校验模型大小 = 491,400,032 且 sha256 = 常量；不符退出。
4. 运行时归档（来自 LFS）：
   - 校验 `translation/bin/llama-b12274-bin-ubuntu-x64.tar.gz` 的大小与固定 sha256；
     缺失或仍是 LFS 指针 → 提示 `git lfs pull` 并退出；
   - 解包到 `translation/bin/llama-b12274/`（幂等；已存在则跳过）。
5. 校验 `llama-cli` 存在且可执行。
6. 打印模型与运行时大小。

### 5.2 `tool/package_linux.sh`

- 先执行 `tool/prepare_translation.sh`。
- 要求 release bundle 存在（原逻辑）。
- 归档构造（不复制模型）：
  1. 临时 tar 写入 bundle 内容；
  2. `tar -rf` 追加 `translation/models/<gguf>`、`translation/bin/llama-b12274/`、
     `translation/licenses/`（相对仓库根，归档内路径即 `translation/...`）；
  3. gzip 成 `dist/tune-linux-x64-<version>.tar.gz`。
- 产物根仍是 bundle 内容，自动更新协议不变。
- 打印归档体积。

### 5.3 `.gitignore`

新增 `translation/bin/llama-b12274/` 与 `.cache/translation/`（解包/下载产物不入库）。

### 5.4 构建说明

- `README.md`「构建」：补 `git lfs install`、`git lfs pull`、缺 LFS 的报错表现。
- `docs/updates.md`「产物约定」：Linux 归档内容加 `translation/`；说明整包替换会一并
  替换模型，无需改更新协议；发布前先 `git lfs pull`，LFS 配额与首次 clone 成本。

## 6. 许可

- `translation/licenses/Qwen2.5-LICENSE.txt`：Apache-2.0 全文。
- `translation/licenses/Qwen2.5-NOTICE.txt`：`Qwen2.5-0.5B-Instruct` 来源
  （https://huggingface.co/Qwen/Qwen2.5-0.5B-Instruct-GGUF）、Apache-2.0、未修改、
  GGUF 量化由 Qwen 官方仓库提供。
- `translation/licenses/llama.cpp-LICENSE.txt`：MIT 全文 + 版权行。
- `THIRD_PARTY_NOTICES.md`：新增「Bundled offline translation model」小节，列模型、
  llama.cpp、路径与许可证；说明随包分发、未修改。
- `docs/licensing.md`：§2 清单加两行；§1 边界补「Apache-2.0 与 MIT 可随包，需带
  LICENSE/NOTICE」；§3 流程补 LFS 场景。

## 7. 降级与首次启动

- 正常：`translation/` 随包，`inspect()` 通过，翻译按需起进程。
- LFS 未拉取：打包脚本直接失败（不会产出坏包）；手工运行的开发构建在设置页显示
  「缺失/校验失败，请重新安装」，列表回退原文。
- 模型损坏：`inspect` 报 `modelCorrupt`；引擎抛 `unavailable`；仓库置 `_unavailable`，
  本轮后续行直接回退原文，不再反复起进程。
- 首次启动无网络请求：`TranslationAssets` 无 dio；`translationAssetsProvider` 只在
  真正请求翻译时被订阅。

## 8. 验证与实测

实测结果（2026-11-11，Linux x64）：

- `tool/prepare_translation.sh` 通过：模型 491,400,032 B，sha256
  `74a4da8c…a9db`；运行时归档 23,287,295 B，sha256 `5f9de4d1…bcd94`，
  解包 57 MB。
- `llama-cli` 直接跑 3 行曲名翻译：冷启动 + 生成共 0.97 s，生成约 62 token/s，
  无需 GPU。
- `flutter build linux --release` + `tool/package_linux.sh` 成功：
  - 改前 `1.29.0` 归档 42,560,141 B；
  - 改后归档 543,039,602 B（+500,479,461 B，模型占绝大部分）；
  - 归档内 `translation/`：模型 1 个、运行时 61 个文件/目录项、许可 3 个。
- 首帧（`flutter run --profile --trace-startup`，各两次）：无覆盖 86/88 ms，
  `TUNE_TRANSLATION_DIR` 指向 `translation/` 时 94/103 ms，差异约 8–15 ms，
  属启动噪声；首帧路径不读模型。
- 启动后可见曲目会按需唤起一次 `llama-cli`（`player_dock` 请求当前曲译文），
  发生在首帧之后，不阻塞首帧；没有可见曲目时不触发。
- `flutter gen-l10n`、`flutter analyze`、`flutter test`（1495 项）、
  `dart run tool/check_licenses.dart` 全绿。

原始步骤：

1. `tool/prepare_translation.sh` 成功；打印模型 sha256 与运行时大小。
2. 直接运行解包后的 `llama-cli` 跑一个中文翻译提示，确认可加载模型并输出。
3. `flutter build linux --release` + `tool/package_linux.sh` 成功，记录：
   - 改前 `1.29.0` 归档 42,560,141 B；
   - 改后归档字节数；
   - 归档内 `translation/` 清单与大小。
4. 启动实测：
   - `flutter run --profile -d linux --trace-startup`（或 release 二进制 + 首帧日志）
     分别在有/无 `TUNE_TRANSLATION_DIR` 下记录首帧时间；
   - 记录 `llama-cli` 冷启动 + 一次 12 行批次的耗时；
   - 证明启动阶段没有模型读取（无 llama 进程、无 491 MB 读放大）。
5. `flutter gen-l10n`、`flutter analyze`（No issues found）、`flutter test`（全绿）、
   `dart run tool/check_licenses.dart`。
6. 新增 `test/features/localization/translation_assets_test.dart`：
   - 缺模型 → `modelMissing`；
   - 文件过小（模拟 LFS 指针）→ `modelCorrupt`；
   - 模型大小正确但无 `llama-cli` → `binaryMissing`；
   - 大小与 sha256 都正确 → ready；
   - `resolve()` 优先发布包、其次开发向上查找、最后支持目录。

## 9. LFS 体积与克隆成本

- LFS 对象两个：模型 491,400,032 B（≈469 MiB）+ 运行时归档 23,287,295 B（≈22 MiB），
  合计约 514.7 MB。
- 普通 clone 只拉指针；安装 LFS 后 clone/pull 会额外下载约 515 MB。
- 仓库 `.git` 只增加两个指针文件；内容在 LFS 存储，不进普通 pack。
- 只保留一个量化版本；替换量化版会新增 LFS 对象，旧对象仍留在 LFS 历史。
- GitHub 免费 LFS 配额 1 GB 存储 / 1 GB 月流量，两个对象合计约占一半。发布前需确认
  配额；若上传受限，改为 release 附件 sidecar（回退方案，另行确认）。
- 解包出的 `translation/bin/llama-b12274/` 不入库，由 prepare 脚本幂等生成。

## 10. 验收

- 首次启动无网络也能翻译（断网手测或代码路径确认）。
- 删除/损坏模型时不崩溃，列表显示原文，设置页提示重装。
- 上述门禁全绿。
- 体积与首帧数字写进最终汇报。

批准后按 `tasks.md` 执行。
