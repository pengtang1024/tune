# Tune - あなたの個人的なメロディボックス 🎵

<p align="center">
  <img src="assets/icons/app_icon.png" alt="Tune Logo" width="120" />
</p>

<p align="center">
  <a href="README_zh.md">中文</a> | 
  <a href="README_en.md">English</a> | 
  <a href="README_ja.md">日本語</a> | 
  <a href="README_ko.md">한국어</a> | 
  <a href="README_ru.md">Русский</a>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/プラットフォーム-Android%20%7C%20iOS%20%7C%20Windows%20%7C%20macOS%20%7C%20Linux%20%7C%20Web-blue" alt="サポートされているプラットフォーム" />
  <img src="https://img.shields.io/badge/Flutter-%5E3.0-green" alt="Flutter バージョン" />
  <img src="https://img.shields.io/badge/ライセンス-MIT-blue.svg" alt="ライセンス" />
</p>

Tuneは音楽プレーヤー以上のもので、あなたの個人的な「旋律収納ボックス」です。ここで、ローカル音楽ライブラリを簡単に整理し、スタイル、ムード、シーン別にプレイリストをカスタマイズして、各楽曲が最も適した場所であなたを待つようにできます。滑らかな再生体験と繊細な音効調整により、ヘッドフォンのすべての音符がクリアで豊かになり、まるで現場にいるかのようです。シンプルで洗練されたインターフェースデザインは、音楽に対する純粋な愛を隠し、余計な気晴らしもなく、あなただけと音楽だけの静かな時間になります。

何年も大切にしているクラシックな名曲であろうと、最近発見したニッチな傑作であろうと、Tuneはすべてを適切に保管し、開くたびに美しい聴覚の再会になります。

Tuneで、音楽を本質に戻し、すべての瞬間を旋律と共に過ごしましょう。

## 🎵 機能

🎵 **ローカル音楽ライブラリ管理** - ローカル音楽ファイルを簡単に整理するクリーンで直感的なインターフェース

📋 **カスタムプレイリスト** - ジャンル、ムード、シーン別にプレイリストを作成し、完璧なリスニング体験を実現

🔊 **高品質オーディオ再生** - just_audioを統合し、複数のフォーマット（MP3、FLAC、WAVなど）をサポートする高品質オーディオ再生

🎚️ **イコライザーとサウンドコントロール** - カスタマイズ可能なサウンド設定と音量コントロールでオーディオを微調整

🎨 **複数のテーマ** - 5つの美しいプリセットテーマ（Trendy Electro、Minimal Gray、Nature Forest、Cyber Neon、Warm Healing）から選択し、ライト/ダークモードをサポート

🌍 **多言語サポート** - 5言語（英語、中国語、日本語、韓国語、ロシア語）の完全サポートと簡単な切り替え

📱 **クロスプラットフォーム** - モバイル、デスクトップ、Web用に美しく設計されたレスポンシブレイアウト

⏯️ **バックグラウンド再生** - 通知コントロールで他のアプリを使用しながらも引き続きリスニング

## 🏗️ 技術アーキテクチャ

このプロジェクトは、Clean Architecture + BLoCパターンの階層化アーキテクチャを採用し、クロスプラットフォームの一貫性と保守性を確保しています。

### アーキテクチャレイヤー

```
lib/
├── config/                 # 設定ファイル
│   └── theme/              # テーマ設定
├── core/                   # コア層
│   ├── di/                 # 依存性注入
│   ├── routes/             # ルート管理
│   ├── services/           # コアサービス
│   └── utils/              # ユーティリティクラス
├── data/                   # データ層
│   ├── datasources/        # データソース
│   ├── models/             # データモデル
│   └── repositories/       # リポジトリ実装
├── domain/                 # ドメイン層
│   ├── entities/           # エンティティ
│   ├── repositories/       # リポジトリインターフェース
│   └── usecases/           # ユースケース
└── presentation/           # 表現層
    ├── bloc/               # ステート管理
    ├── pages/              # ページ
    ├── widgets/            # 汎用コンポーネント
    └── components/         # 業務コンポーネント
```

### コアモジュール

- **オーディオ再生コアモジュール** - just_audioを使用した再生、一時停止、スキップ、進行状況コントロールの実装
- **音楽ライブラリモジュール** - オンラインストリーミングサポート付きのローカル音楽検索のカスタム実装
- **プレイリストモジュール** - プレイリストストレージにHiveを使用
- **ユーザーモジュール** - ユーザーセッションにshared_preferencesを使用したサードパーティログインサポート
- **UI/UXモジュール** - カスタマイズ可能なテーマとダークモードを備えたレスポンシブデザイン

## 📦 主要技術スタック

- **ステート管理**: [flutter_bloc](https://pub.dev/packages/flutter_bloc)
- **ルート管理**: [auto_route](https://pub.dev/packages/auto_route)
- **オーディオ再生**: [just_audio](https://pub.dev/packages/just_audio)
- **ローカル音楽検索**: カスタム実装
- **権限管理**: [permission_handler](https://pub.dev/packages/permission_handler)
- **依存性注入**: [get_it](https://pub.dev/packages/get_it)
- **国際化**: [flutter_localizations](https://pub.dev/packages/flutter_localizations)

## 🚀 クイックスタート

1. プロジェクトをクローン:
   ```bash
   git clone <repository-url>
   ```

2. 依存関係をインストール:
   ```bash
   flutter pub get
   ```

3. アプリケーションを実行:
   ```bash
   flutter run
   ```

## 🎯 プラットフォーム適応

- **モバイル**: バックグラウンド再生、ロック画面コントロール、通知プレーヤーコントロール付きのプラットフォーム設計ガイドラインに従う
- **デスクトップ**: システムトレイ統合、キーボードショートカット、マルチウィンドウサポート付きのウィンドウレイアウト設計
- **Web**: PWAサポート付きのブラウザオーディオ制限を処理するレスポンシブWebデザイン

## 🛠️ 便利なコマンド

### 国際化

手動でローカライズファイルを生成:
```bash
flutter gen-l10n
```

### アイコン

flutter_launcher_iconsでアプリアイコンを自動生成:
```bash
flutter pub run flutter_launcher_icons:main
```

### コード生成

build_runnerを実行してコードを生成:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### テスト

すべてのテストを実行:
```bash
flutter test
```

カバレッジ付きでテストを実行:
```bash
flutter test --coverage
```

## 🧪 テスト戦略

- **ユニットテスト**: ユースケースとリポジトリロジックのテスト
- **インテグレーションテスト**: データソースとネットワークリクエストのテスト
- **ウィジェットテスト**: UIコンポーネントのテスト
- **エンドツーエンドテスト**: ユーザーフローのテスト

## 📈 拡張性の考慮事項

- プラグインベースのアーキテクチャ
- APIバージョンコントロールサポート
- 設定可能なテーマ
- 安定性保証のためのモジュラーテスト

## 📄 ライセンス

このプロジェクトはMITライセンスの下でライセンスされています - 詳細は[LICENSE](LICENSE)ファイルを参照してください。