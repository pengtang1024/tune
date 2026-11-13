# 实施清单

## T0 文档
- [x] `AGENTS.md` 文档地图加一行 → `docs/local-components.md`

## T1 组件层
- [x] `lib/data/services/components/local_component.dart`（模型与状态数据）
- [x] `local_component_registry.dart`（10 个组件，字节数 + sha256 钉死）
- [x] `local_component_installer.dart`（下载 → 校验 → 解压 → chmod → 原子替换 → 删除/占用）
- [x] `local_components.dart`（系统 → 旧目录 → 组件的解析）
- [x] `lib/data/services/providers/local_components_provider.dart`

## T2 状态层
- [x] `lib/features/local_components/application/local_components_controller.dart`（按 id 的状态、下载/取消/删除/刷新）
- [x] 删除 `local_model_controller.dart`、`local_model_installer.dart` 并改引用

## T3 翻译
- [x] `translation_assets.dart` 改为门面，保留 `resolve/inspect/installedSize`
- [x] `localization_providers.dart` 可用性改读组件状态
- [x] `settings_localization_local_block.dart` 复用统一状态与动作

## T4 歌词
- [x] `whisper_assets.dart` 可选注入 `LocalComponents`，系统优先
- [x] `whisper_model_store.dart` 委托统一 installer，校验值来自 registry
- [x] `smart_lyrics_controller.dart` 的 Sherpa / Whisper 资产解析走统一入口
- [x] `smart_lyrics_service.dart` 的 ffmpeg 运行时解析
- [x] `settings_smart_lyrics_local_section.dart` 去掉本地下载状态

## T5 设置页
- [x] catalog / pane / customize sheet 增加 `SettingsSection.components`
- [x] `settings_local_components_card.dart`（三组、每行状态/占用/操作、删除确认）

## T6 文案
- [x] 4 个 arb + `flutter gen-l10n`

## T7 测试
- [x] 新增 installer / resolver / controller 测试
- [x] 更新 translation_assets、whisper_assets、whisper_model_store、translation_availability、settings_smart_lyrics_card 测试
- [x] `flutter analyze`、`flutter test` 全绿（联网用例按 docs/verification.md 单独判断）

## T8 提交
- [x] 只暂存本线文件，提交 `refactor(components): 本地能力收敛为统一组件注册与安装器`，不 push
