# Tune

[中文](README.md) · [English](README_en.md) · [日本語](README_ja.md) · [한국어](README_ko.md) · [Русский](README_ru.md)

Tune は Flutter で作られたコンパクトなローカル／オンライン音楽プレーヤーです。左側にプレーヤーを常駐させ、右側でライブラリ・再生キュー・設定を切り替えます。

## 機能

- ローカル音楽フォルダのスキャン、検索、永続化
- オンライン音源：Openverse、Jamendo、Internet Archive、自建 NeteaseCloudMusicApi
- キューの追加・削除・ドラッグ並べ替え・クリア
- 再生／一時停止、前へ／次へ、シーク、音量、リピートモード
- ライブラリを音源で絞り込み、リモート曲に音源とカバーを表示
- ライト／ダーク／システムテーマ、スキャン先と音源設定の永続化
- 既定ウィンドウ 900×600、最小 760×520

## 技術スタック

- Flutter、Riverpod、go_router
- just_audio；Linux は just_audio_media_kit + システム libmpv
- Dio、shared_preferences、file_picker
- flutter_localizations / gen-l10n

## 構成

```text
lib/
├── app/                  # エントリ、ルーティング、テーマ、シェル
├── features/             # player / library / queue / settings / sources
├── data/services/        # オーディオ、スキャン、音源アダプター、永続化
├── domain/models/        # Song、音源設定、スキャン結果
├── shared/               # 共通 UI とユーティリティ
└── l10n/                 # ローカライズ
```

音源モデルの詳細は [需求/音源设计.md](需求/音源设计.md)（中国語）を参照してください。

## 実行

```bash
flutter pub get
flutter run -d linux
```

## ビルド

```bash
flutter build linux --debug
```

## 既知の制限

- 現在の主な対象は Linux デスクトップです。
- リモート再生にはネットワークが必要で、ダウンロード／オフラインキャッシュは未実装です。
- リモートの再生 URL は期限切れになる場合があり、音源の再スキャンが必要です。
- 旧モバイル通知、歌詞、イコライザー、履歴、アカウント機能はメイン経路から外れています。

## ライセンス

[MIT License](LICENSE)
