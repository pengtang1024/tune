# 流派本地化

> 流派名怎么翻、翻哪些、翻不出来怎么办。规范在 [i18n.md](i18n.md)，门禁在 [verification.md](verification.md)。
> 最后更新：2026-10-20。

## 为什么要有

流派是音源写在元数据里的值，音源用什么语言写，界面就显示什么语言：中文界面里出现 `Rock`，英文界面里出现 `流行`。这两种都是漏字。

流派名本身是开放集合，各目录写法不一（`Rock`、`rock music`、`摇滚乐`、`Hip-Hop/Rap`…），所以**不能整段翻译，只能认得出来的才翻**。

## 模块

两个文件，都不依赖别处：

| 文件 | 放什么 |
| --- | --- |
| `lib/core/l10n/genre_dictionary.dart` | 流派枚举（`Genre`）、名字表、认得出的写法 |
| `lib/core/l10n/genre_label.dart` | 对外的两个函数 |

```dart
/// 一个流派在界面语言里的名字。认不出来的流派保持音源给的原样。
String genreLabel(String genre, AppLocalizations strings);

/// 几个流派在界面语言里的名字。
String genresLabel(Iterable<String> genres, AppLocalizations strings);
```

模块只依赖 `AppLocalizations`，不碰 `Song`、不碰存储：模型里存的原值永远不动（搜索、排序、分组靠它）。

## 名字在哪

流派的名字进 ARB（`genreRock`、`genrePop`…），四种语言齐全。这是界面文案，按 [i18n.md](i18n.md) 的规矩走。

**代码里不写一个汉字**（`test/app/localization_test.dart` 守着这条）：中文别名不是硬编码的，而是运行时从目录里读的——

> 每种语言给流派起的名字，本身就是这个流派的另一种写法。

所以中文标签写的 `摇滚`，在英文界面里也能认出是摇滚；英文标签写的 `Rock`，在中文界面里显示 `摇滚`。一份名字，两件事：显示 + 认得。

## 认得出哪些写法

| 写法 | 例子 | 归到 |
| --- | --- | --- |
| 目录里的名字 | `Rock` `摇滚` `搖滾` | 各个流派 |
| 常见的别名 | `rock & roll` `heavy metal` `hip hop` `rap` | 各个流派 |
| 结尾的「音乐」 | `摇滚乐` `电子音乐` `Rock Music` | 去掉后缀后认 |
| 多个流派 | `Rock/Jazz` `Rock, Jazz` | 逐个认，再按 ` / ` 拼 |

认的时候不看大小写，也不管前后空格。结尾那个「音乐」在每种语言里都不一样，所以也放在 ARB 里（`genreMusicWord` / `genreMusicWordShort`），代码运行时读。

## 认不出来怎么办

**原样显示**。比如 `Drum & Bass`、`蒸汽波`、某个自建音乐库的私有标签——这些流派没有公认的中文名，硬翻只会更糟。宁可让读者看到音源的原词，也不要给他一个半懂不懂的译名。

一个都没认出来时，整串保持原样（连分隔符都不动）；认出一部分时，认出的翻、没认出的留原词。

## 接到哪里

曲目详情浮层的「流派」那一条（`lib/shared/ui/track_metadata_facts.dart`）。界面里只有这一处显示流派。

## 测试

`test/app/genre_label_test.dart`：

- 认得出的流派在每种语言里都有名字；
- 大小写、空格、后缀、别名都认得出；
- 认不出的保持原样；
- 多个流派逐个翻、顺序不变；
- 详情浮层里的流派确实是当前界面的语言（真界面，不是只测函数）。
