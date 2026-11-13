# 任务：离线翻译模型随包分发（Git LFS）

> 依据：`spec.md`。按顺序执行，每项完成即勾选。

## A. LFS 与仓库布局

- [x] A1 新建 `translation/` 目录骨架：`models/`、`bin/`、`licenses/`。
- [x] A2 下载模型到 `translation/models/qwen2.5-0.5b-instruct-q4_k_m.gguf`，校验大小与 sha256。
- [x] A3 放入 llama.cpp b12274 归档到 `translation/bin/llama-b12274-bin-ubuntu-x64.tar.gz`，校验大小与 sha256。
- [x] A4 新增 `.gitattributes`：gguf 与 llama 归档走 LFS；`git check-attr` 校验。
- [x] A5 `.gitignore` 增加 `translation/bin/llama-b12274/`。
- [x] A6 写入 `translation/licenses/` 三份许可文本（Qwen LICENSE、Qwen NOTICE、llama.cpp MIT）。

## B. 代码

- [x] B1 重写 `lib/data/services/translation/translation_assets.dart`：定位、inspect、sha256（Isolate 缓存），删除下载。
- [x] B2 改 `lib/features/localization/application/local_model_controller.dart`：checking/ready/missing/corrupt/failed，移除下载/删除。
- [x] B3 改 `lib/features/localization/presentation/settings_localization_card.dart`：状态 + 重装提示，移除进度/下载/删除。
- [x] B4 改 `lib/data/services/translation/llama_local_translation_engine.dart`：起进程前 inspect（含 digest），失败抛 unavailable。
- [x] B5 改四个 ARB（删 3 键、改 2 键、加 2 键），`flutter gen-l10n`。

## C. 构建与文档

- [x] C1 新增 `tool/prepare_translation.sh`（LFS/指针/大小/sha 校验模型与运行时归档 + 解包 + 可执行校验）。
- [x] C2 改 `tool/package_linux.sh`（调用 prepare，tar 直接追加仓库 `translation/`，不复制模型，打印体积）。
- [x] C3 `README.md` 构建节补 LFS 前置与缺 LFS 的报错表现。
- [x] C4 `docs/updates.md` 产物约定/发布步骤更新（`translation/`、整包替换、LFS 配额与 clone 成本）。
- [x] C5 `THIRD_PARTY_NOTICES.md` 与 `docs/licensing.md` 补 Qwen/llama.cpp 条目与边界。

## D. 测试与实测

- [x] D1 新增 `test/features/localization/translation_assets_test.dart`（缺失/指针/缺二进制/损坏/就绪/定位顺序）。
- [x] D2 `tool/prepare_translation.sh` 实跑；用解包后的 `llama-cli` 跑一次 12 行翻译。
- [x] D3 `flutter build linux --release` + `tool/package_linux.sh`，记录改前/改后体积与归档 `translation/` 清单。
- [x] D4 首帧实测：有/无 `TUNE_TRANSLATION_DIR` 各一次，记录首帧与 llama 冷启动/批次耗时；确认启动不读模型。
- [x] D5 `flutter gen-l10n`、`flutter analyze`、`flutter test`、`dart run tool/check_licenses.dart` 全绿。

## E. 汇报

- [x] E1 汇报节点 1：LFS 规则落地 + 带模型构建跑通（含体积）。
- [x] E2 汇报节点 2：加载时机与首帧实测。
- [x] E3 最终结论：体积、许可、降级、LFS 成本、遗留风险。
