# Tune - Your Personal Melody Box

Tune is a music player application designed to provide you with a clean and intuitive interface for organizing and playing your local music collection.

## Features

- **Local Music Library Management**: Easily organize your local music files
- **Custom Playlists**: Create playlists based on genres, moods, or scenes
- **Smooth Playback Experience**: Enjoy high-quality audio playback
- **Equalizer**: Fine-tune audio with customizable sound settings
- **Minimalist Interface**: Clean design that focuses on the music experience

## Installation

1. Make sure you have Flutter installed on your machine
2. Clone this repository
3. Run `flutter pub get` to install dependencies
4. Connect a device or start an emulator
5. Run `flutter run` to start the application

## Supported Platforms

- Android
- iOS
- Linux
- macOS
- Windows
- Web

## Project Description

Tune: Let every melody find its home. In the hustle and bustle of daily life, there are always some melodies that quietly settle into our hearts — perhaps the cheerful rhythm that wakes you up in the morning, the gentle folk song that accompanies you late at night, or the surprisingly delightful single encountered by chance on a journey.

Tune is more than just a music player; it's your personal "melody storage box." Here, you can easily organize your local music library, customize playlists by style, mood, or scene, ensuring each song waits for you in the most suitable place. With smooth playback experience paired with delicate sound adjustment, every note in your headphones becomes clear and full, as if you were at the scene. The simple yet refined interface design hides a pure love for music, without any unnecessary distractions — just you and your music alone.

Whether it's a classic favorite treasured for years or a newly discovered niche masterpiece, Tune can妥善安放 them all, making every opening a beautiful auditory reunion.

With Tune, let music return to its essence, and let every moment be accompanied by melodies.

## Technical Architecture

This project adopts a layered architecture of Clean Architecture + BLoC pattern to ensure cross-platform consistency and maintainability.

### Architecture Layers

1. **Presentation Layer**
   - Pages
   - Components
   - BLoC State Management
   - Route Management

2. **Domain Layer**
   - Entities
   - Use Cases
   - Repository Interfaces

3. **Data Layer**
   - Repository Implementations
   - Data Source Interfaces
   - Local Data Sources
   - Remote Data Sources

4. **Core Layer**
   - Services
   - Utilities
   - Constants
   - Global State

### Core Modules

- **Audio Playback Core Module**: Uses just_audio to implement play, pause, switch, and progress control functions
- **Music Library Module**: Gets local music through on_audio_query, supports online streaming resources
- **Playlist Module**: Uses Hive or SQLite to store playlists
- **User Module**: Supports third-party login, uses shared_preferences to store user sessions
- **UI/UX Module**: Responsive design, supports custom themes and dark mode

## 📦 Main Technology Stack

- State Management: [flutter_bloc](https://pub.dev/packages/flutter_bloc)
- Route Management: [auto_route](https://pub.dev/packages/auto_route)
- Audio Playback: [just_audio](https://pub.dev/packages/just_audio)
- Local Music Access: Custom implementation
- Permission Management: [permission_handler](https://pub.dev/packages/permission_handler)
- Dependency Injection: [get_it](https://pub.dev/packages/get_it)
- Internationalization: [flutter_localizations](https://pub.dev/packages/flutter_localizations)

## Cross-Platform Adaptation

- **Mobile**: Follows platform design guidelines, supports background playback, lock screen controls, and notification player controls
- **Desktop**: Designs windowed layout, integrates system tray, supports shortcuts and multiple windows
- **Web**: Implements responsive web design, handles browser audio restrictions, supports PWA

## Directory Structure

```
lib/
├── config/                 # Configuration files
│   └── theme/              # Theme configuration
├── core/                   # Core layer
│   ├── di/                 # Dependency injection
│   ├── routes/             # Route management
│   ├── services/           # Core services
│   └── utils/              # Utilities
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
    ├── widgets/            # Common components
    └── components/         # Business components
```

## Common Commands

### Localization

Generate localization files manually:
```
flutter gen-l10n
```

### Icons

Generate icons automatically with flutter_launcher_icons:
```
flutter pub run flutter_launcher_icons:main
```

### Code Generation

Run build_runner for code generation:
```
flutter pub run build_runner build --delete-conflicting-outputs
```

### Testing

Run all tests:
```
flutter test
```

Run tests with coverage:
```
flutter test --coverage
```

## Testing Strategy

- Unit Testing: Test cases and repository logic
- Integration Testing: Test data sources and network requests
- Widget Testing: Test UI components
- End-to-End Testing: Test user flows

## Extensibility Considerations

- Adopt plugin architecture
- Support API version control
- Provide configurable themes
- Implement modular testing to ensure stability