# 许可证与第三方声明

这份文档说明 Tune 的许可证边界，以及新增依赖或素材时要做什么。目标只有一条：
**Tune 自有代码保持 MIT；随包分发的第三方组件必须允许再分发，并且声明齐全。**

## 1. 边界

- **自有代码**：`lib/`、`test/`、`tool/`、平台 runner 中由本项目编写的部分，采用
  [`LICENSE`](../LICENSE) 的 MIT。
- **第三方字体**：SIL OFL-1.1，不是 MIT。随包分发时必须带 OFL 全文和版权行。
- **Dart/Flutter 依赖**：允许 MIT、BSD-2/3、Apache-2.0、MPL-2.0、Unlicense、ISC、
  Zlib。Flutter 工具会把它们的 LICENSE 收进安装包的 `NOTICES`。
- **Linux 播放后端**：`libmpv` / FFmpeg 是系统组件，Ubuntu 打包为 GPL-3+ / GPL-2+。
  Tune 不打包它们；如果发行版把 Tune 和它们装进同一个自包含包，那个包必须按 GPL
  处理。
- **GPL/AGPL/LGPL/SSPL/BUSL/Commons Clause**：不得进入 Tune 随包分发的代码。
  LGPL 系统库（GTK/GLib）只以动态链接方式使用，不随包分发。

## 2. 当前清单

| 内容 | 位置 | 许可证 | 声明位置 |
| --- | --- | --- | --- |
| Tune 代码 | `lib/` 等 | MIT | `LICENSE` |
| 字体 | `assets/fonts/*/*.ttf` | OFL-1.1 | `assets/fonts/*/OFL.txt`、`THIRD_PARTY_NOTICES.md` |
| Dart 依赖 | `pubspec.lock` | MIT/BSD/Apache/MPL/Unlicense | 安装包内 `NOTICES` |
| Flutter engine | 随 Flutter SDK | BSD-3 | 安装包内 `NOTICES` |
| libmpv / FFmpeg | 系统库 | GPL-3+ / GPL-2+ | `THIRD_PARTY_NOTICES.md`（仅说明，不随包） |
| 应用图标 | `branding/`、`assets/icons/` | 项目自有（推定 MIT） | 来源待补，见 §4 |

`THIRD_PARTY_NOTICES.md` 会作为 asset 打进安装包，并通过
`lib/app/licenses.dart` 注册到应用内许可证页。

## 3. 新增依赖或素材

1. 先看许可证。出现 GPL/AGPL/SSPL/BUSL/Commons Clause 时，默认不引入；确需引入
   时先确认分发方式，不能污染 MIT 代码。
2. LGPL 只接受动态链接的系统库；不要静态链接，也不要把库打进 bundle。
3. 新增字体：把 `OFL.txt` 放到字体目录，登记到 `THIRD_PARTY_NOTICES.md`，并加入
   `pubspec.yaml` 的 `assets:`。
4. 新增图片/音频素材：在 `THIRD_PARTY_NOTICES.md` 记录来源、作者、许可证；没有
   来源的素材不要提交。
5. 新增 Dart 依赖：`flutter pub get` 后确认 `NOTICES` 仍会生成；非 MIT/BSD/Apache
   的依赖要补进 `THIRD_PARTY_NOTICES.md`。
6. 改完运行：

```bash
dart run tool/check_licenses.dart
flutter analyze
flutter test
```

## 4. 已知法律边界

- **libmpv 的动态加载**：Tune 通过 `dlopen` 使用系统 libmpv，不随包分发；是否构成
  衍生作品取决于法域和具体分发方式。发行前需法务确认，尤其是 AppImage/Flatpak。
- **Noto Sans SC 的 Reserved Font Name**：字体元数据声明了 `Source`。不要分发改名后
  的修改版，除非取得书面许可。
- **Flutter 模板/生成文件**：按 BSD-3 处理，`NOTICES` 覆盖引擎和包；模板文件的逐文件
  版权头是否需要保留，属于解释问题。
- **MPL-2.0 的 `dbus`**：未修改；如修改 MPL 文件，需要公开修改后的源文件。
- **图标/截图来源**：`branding/app_icon.png`、`assets/icons/*.png` 推定项目自有，
  尚无外部来源记录；引入第三方素材前先补授权和来源。

## 5. 参考

- [`THIRD_PARTY_NOTICES.md`](../THIRD_PARTY_NOTICES.md)
- [`LICENSE`](../LICENSE)
- [`docs/verification.md`](verification.md)

## 6. 已撤回的版本

2026-10-26 起，`v1.0.0`、`v1.1.0`、`v1.2.0` 的 tag 已从 `origin` 与 `github`
删除，不再提供 tag 归档下载。它们对应的提交仍留在 git 历史中：

| 版本 | 提交 |
| --- | --- |
| v1.0.0 | `9aea9dd` |
| v1.1.0 | `0ebcccf` |
| v1.2.0 | `0d59f11` |

要连同历史一起移除，需要重写 git 历史并 force-push；本次没有做。
