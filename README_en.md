# Tune

[中文](README.md) · [English](README_en.md) · [日本語](README_ja.md) · [한국어](README_ko.md) · [Русский](README_ru.md)

Tune is a compact local and online music player built with Flutter. A persistent player occupies the left pane, while the right pane switches between library, queue, and settings.

## Features

- Scan, search, and persist local music folders
- Online sources: Openverse, Jamendo, Internet Archive, and self-hosted NeteaseCloudMusicApi
- Queue management with reorder, play-at-index, and clear
- Play/pause, previous/next, seek, volume, and repeat modes
- Filter the library by source; remote tracks show source and artwork
- Light / dark / system themes; persistent scan paths and source settings
- 900×600 default window, 760×520 minimum

## Stack

- Flutter, Riverpod, go_router
- just_audio; Linux playback through just_audio_media_kit + system libmpv
- Dio, shared_preferences, file_picker
- flutter_localizations / gen-l10n

## Structure

```text
lib/
├── app/                  # entry, routing, theme, shell
├── features/             # player / library / queue / settings / sources
├── data/services/        # audio, scanning, source adapters, persistence
├── domain/models/        # Song, source config, scan results
├── shared/               # shared UI and utilities
└── l10n/                 # localization resources
```

See [需求/音源设计.md](需求/音源设计.md) for the source model (Chinese).

## Run

```bash
flutter pub get
flutter run -d linux
```

## Build

```bash
flutter build linux --debug
```

## Known limitations

- Linux desktop is the primary target for the current release.
- Remote playback requires a network connection; downloads/offline caching are not implemented.
- Remote stream URLs can expire and must be refreshed by rescanning the source.
- Legacy mobile notifications, lyrics, equalizer, history, and account features are no longer part of the main path.

## License

[MIT License](LICENSE)
