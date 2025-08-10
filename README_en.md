# Tune - Your Personal Melody Box 🎵

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
  <img src="https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Windows%20%7C%20macOS%20%7C%20Linux%20%7C%20Web-blue" alt="Supported Platforms" />
  <img src="https://img.shields.io/badge/Flutter-%5E3.0-green" alt="Flutter Version" />
  <img src="https://img.shields.io/badge/License-MIT-blue.svg" alt="License" />
</p>

Tune is more than just a music player; it's your personal "melody storage box." Here, you can easily organize your local music library, customize playlists by style, mood, or scene, ensuring each song waits for you in the most suitable place. With smooth playback experience paired with delicate sound adjustment, every note in your headphones becomes clear and full, as if you were at the scene. The simple yet refined interface design hides a pure love for music, without any unnecessary distractions — just you and your music alone.

Whether it's a classic favorite treasured for years or a newly discovered niche masterpiece, Tune can妥善安放 them all, making every opening a beautiful auditory reunion.

With Tune, let music return to its essence, and let every moment be accompanied by melodies.

## 🎵 Key Features

🎵 **Local Music Library Management** - Easily organize your local music files with a clean and intuitive interface

📋 **Custom Playlists** - Create playlists based on genres, moods, or scenes for the perfect listening experience

🔊 **High-Quality Audio Playback** - Integrated with just_audio for high-quality audio playback supporting multiple formats (MP3, FLAC, WAV, etc.)

🎚️ **Equalizer & Sound Control** - Fine-tune audio with customizable sound settings and volume control

🎨 **Multiple Themes** - Choose from 5 beautiful preset themes (Trendy Electro, Minimal Gray, Nature Forest, Cyber Neon, Warm Healing) with light/dark mode support

🌍 **Multi-language Support** - Full support for 5 languages (English, Chinese, Japanese, Korean, Russian) with easy switching

📱 **Cross-Platform** - Beautifully designed for mobile, desktop, and web with responsive layouts

⏯️ **Background Playback** - Continue listening while using other apps with notification controls

## 🏗️ Technical Architecture

This project adopts a layered architecture of Clean Architecture + BLoC pattern to ensure cross-platform consistency and maintainability.

### Architecture Layers

```
lib/
├── config/                 # Configuration files
│   └── theme/              # Theme configuration
├── core/                   # Core layer
│   ├── di/                 # Dependency injection
│   ├── routes/             # Route management
│   ├── services/           # Core services
│   └── utils/              # Utility classes
├── data/                   # Data layer
│   ├── datasources/        # Data sources
│   ├── models/             # Data models
│   └── repositories/       # Repository implementations
├── domain/                 # Domain layer
│   ├── entities/           # Entities
│   ├── repositories/       # Repository interfaces
│   └── usecases/           # Use cases
└── presentation/           # Presentation layer
    ├── bloc/               # State management
    ├── pages/              # Pages
    ├── widgets/            # Generic components
    └── components/         # Business components
```

### Core Modules

- **Audio Playback Core Module** - Implements play, pause, skip, and progress control using just_audio
- **Music Library Module** - Custom implementation for local music retrieval with online streaming support
- **Playlist Module** - Uses Hive for playlist storage
- **User Module** - Third-party login support with shared_preferences for user sessions
- **UI/UX Module** - Responsive design with customizable themes and dark mode

## 📦 Main Technology Stack

- **State Management**: [flutter_bloc](https://pub.dev/packages/flutter_bloc)
- **Route Management**: [auto_route](https://pub.dev/packages/auto_route)
- **Audio Playback**: [just_audio](https://pub.dev/packages/just_audio)
- **Local Music Retrieval**: Custom implementation
- **Permission Management**: [permission_handler](https://pub.dev/packages/permission_handler)
- **Dependency Injection**: [get_it](https://pub.dev/packages/get_it)
- **Internationalization**: [flutter_localizations](https://pub.dev/packages/flutter_localizations)

## 🚀 Getting Started

1. Clone the project:
   ```bash
   git clone <repository-url>
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run the application:
   ```bash
   flutter run
   ```

## 🎯 Platform Adaptation

- **Mobile**: Follows platform design guidelines with background playback, lock screen controls, and notification player controls
- **Desktop**: Windowed layout design with system tray integration, keyboard shortcuts, and multi-window support
- **Web**: Responsive web design handling browser audio restrictions with PWA support

## 🛠️ Useful Commands

### Internationalization

Generate localization files manually:
```bash
flutter gen-l10n
```

### Icons

Auto-generate app icons with flutter_launcher_icons:
```bash
flutter pub run flutter_launcher_icons:main
```

### Code Generation

Run build_runner for code generation:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### Testing

Run all tests:
```bash
flutter test
```

Run tests with coverage:
```bash
flutter test --coverage
```

## 🧪 Testing Strategy

- **Unit Tests**: Testing use cases and repository logic
- **Integration Tests**: Testing data sources and network requests
- **Widget Tests**: Testing UI components
- **End-to-End Tests**: Testing user flows

## 📈 Extensibility Considerations

- Plugin-based architecture
- API version control support
- Configurable themes
- Modular testing for stability assurance

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.