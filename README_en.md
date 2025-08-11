# Tune - Cross-Platform Music Player

<p align="center">
  <img src="assets/icons/app_icon.png" width="200" alt="Tune Logo" />
</p>

<p align="center">
  Let every melody find its home
</p>

<p align="center">
  <a href="README.md">中文</a> •
  <a href="README_en.md">English</a> •
  <a href="README_ja.md">日本語</a> •
  <a href="README_ko.md">한국어</a> •
  <a href="README_ru.md">Русский</a>
</p>

## 🎵 About Tune

In the hustle and bustle of daily life, there are always some melodies that quietly find their way into your heart - perhaps the cheerful rhythm that wakes you up in the morning, the gentle folk song that accompanies you late at night, or the surprise single you encounter on a journey.

Tune is more than just a music player; it's your personal "melody organizer." Here, you can easily organize your local music library, customize playlists by style, mood, or scene, ensuring each song is in its perfect place waiting for you. With smooth playback experience paired with delicate audio adjustments, every note in your headphones sounds clear and full, as if you were at the live performance. The simple yet sophisticated interface design embodies pure love for music, free from distractions, offering only you and your music alone.

Whether it's classic songs treasured for years or newly discovered niche gems, Tune can妥善 store them all, making every opening a beautiful auditory reunion.

With Tune, let music return to its essence, and let every moment be accompanied by melodies.

## 🌟 Features

- 🎧 **High-quality Audio Playback** - Supports multiple audio formats including MP3, FLAC, WAV
- 📚 **Local Music Management** - Automatically scans and organizes local music library with metadata parsing
- 🎨 **Multi-theme Support** - 8 beautiful themes (Trendy Electro, Minimal Gray, Nature Forest, Cyber Neon, Warm Healing, etc.) with automatic dark/light mode switching
- 🌍 **Multi-language Support** - Supports Chinese, English, Japanese, Korean, Russian
- 📱 **Cross-platform Compatibility** - Full support for Android, iOS, Windows, macOS, Linux, Web
- ⚡ **Smooth Experience** - Background playback, notification controls, quick search
- 🎛️ **Personalization** - Rich customization options for fonts, themes, languages
- 🎯 **Smart Recommendations** - Personalized music recommendations based on playback history
- 📥 **Offline Caching** - Supports caching online music for offline enjoyment
- 📋 **Playlists** - Supports creating and managing custom playlists
- 🔄 **Multiple Play Modes** - List loop, single loop, shuffle play
- ⏩ **Playback Control** - Supports playback progress dragging, volume adjustment, playback speed adjustment (0.5x-2.0x)
- 🎵 **Lyrics Synchronization** - Supports real-time display of LRC format lyrics
- 🔍 **Smart Search** - Supports searching by song name, artist, album

## 🎨 Theme Preview

Tune offers multiple beautiful themes for you to choose from:

1. **Trendy Electro** - Purple-toned modern electronic style
2. **Minimal Gray** - Clean gray-scale design
3. **Nature Forest** - Fresh green natural style
4. **Cyber Neon** - Futuristic neon colors
5. **Warm Healing** - Warm orange healing style
6. **Warm Orange Gradient** - Gradient orange warm style
7. **Monochrome** - Minimalist design with unified colors
8. **Vibrant Red** - Passionate red theme

All themes follow the design concept of "bright and transparent in light mode, delicate and refined in dark mode" with low-saturation color matching to create a sense of sophistication

## 🛠 Technical Architecture

Tune is built using Clean Architecture + BLoC pattern to ensure code maintainability and scalability:

```
lib/
├── app/                    # Application core configuration
│   ├── router/             # Routing management
│   └── theme/              # Theme system
├── core/                   # Core layer
│   ├── bloc/               # Global state management
│   ├── config/             # Application configuration
│   ├── error/              # Error handling
│   ├── network/            # Network related
│   ├── services/           # Core services
│   ├── storage/            # Data storage
│   ├── utils/              # Utility classes
│   └── widgets/            # Core components
├── features/               # Feature modules
│   ├── audio/              # Audio playback functionality
│   ├── home/               # Home module
│   ├── library/            # Music library module
│   ├── player/             # Player module
│   ├── profile/            # Profile module
│   ├── search/             # Search module
│   └── settings/           # Settings module
├── l10n/                   # Internationalization resources
└── di/                     # Dependency injection
```

## 🚀 Quick Start

### Requirements

- Flutter SDK 3.8.1 or higher
- Dart SDK 3.8.1 or higher
- Supported IDE (Android Studio / VS Code)

### Install Dependencies

```bash
flutter pub get
```

### Run the Application

```bash
# Run in development mode
flutter run

# Build for specific platforms
flutter build apk      # Android
flutter build ios      # iOS
flutter build web      # Web
flutter build windows  # Windows
flutter build macos    # macOS
flutter build linux    # Linux
```

## 🔧 Main Dependencies

- **Audio Playback**: [just_audio](https://pub.dev/packages/just_audio)
- **State Management**: [flutter_bloc](https://pub.dev/packages/flutter_bloc)
- **Routing**: [auto_route](https://pub.dev/packages/auto_route)
- **Local Storage**: [hive](https://pub.dev/packages/hive), [shared_preferences](https://pub.dev/packages/shared_preferences)
- **Network Requests**: [dio](https://pub.dev/packages/dio)
- **Dependency Injection**: [get_it](https://pub.dev/packages/get_it)
- **Internationalization**: [flutter_localizations](https://flutter.dev/docs/development/accessibility-and-localization/internationalization)


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