# 测试与验证

> AGENTS.md 的展开文档。写测试、跑门禁前读这份。

## 提交前门禁

```bash
flutter analyze          # 必须 No issues found
flutter test             # 全绿
flutter gen-l10n         # 改过 ARB 才需要
flutter run -d linux     # 需要看界面时
```

只写测试不算验证：`flutter analyze` 干净 + `flutter test` 全绿 + 亲手跑过界面，三者都要有。

## 测试目录

镜像 lib 结构：

| 目录 | 放什么 |
| --- | --- |
| `test/app/` | controller、界面、设置的测试；替身（fake）也放这里 |
| `test/core/` | l10n、文本方向等核心工具的测试 |
| `test/domain/` | 领域模型的测试 |
| `test/services/` | 服务与适配器的测试，含跨服务的集成用例 |

## 替身与隔离

- service / controller 的替身写成 `test/app/fake_*.dart`（`FakeAudioPlayerService`、`FakeSongDownloadService`、`FakeStreamUrlResolver`）。
- 持久化用 `SharedPreferences.setMockInitialValues({})` 隔离；该 API 只能在 `test/` 下调用。
- controller 的替身继承原类并覆盖 `build()`（见 `layout_shots_test.dart` 里的 `_FakeLibraryController`）。

## 语言守卫

- `test/app/localization_test.dart`：扫源码，比对各 locale 的目录、查硬编码文案、查漏出的其它语言。
- `test/app/localization_render_test.dart`：真正渲染每个页面读树，抓硬编码文案、跨语言漏出和超长标签。
- `test/app/localization_words.dart`：专有名词与格式名的白名单，新增音源名要加进去。
- `test/app/localization_numbers_test.dart`：数字分组格式。

规则细节见 [i18n.md](i18n.md)。

## 截图对比

- `tool/layout_shots_test.dart` 是开发用的截图工具，不是测试套件的一部分。
- 跑法：`flutter test tool/layout_shots_test.dart`，每个页面写一张 PNG 到 `build/layout-shots/`。
- 它在 `tool/` 下，常规 `flutter test` 不会跑到它。
- 改了界面布局后跑一次，和改动前的 PNG 对比，比读代码更快发现布局问题。

## 联网测试

`test/services/` 里有若干访问真实服务的用例（`music_source_e2e_live_test.dart`、`music_source_live_test.dart`）。它们依赖网络与外部服务，跑测试时若失败先确认是不是网络问题，再判断是不是代码问题。
