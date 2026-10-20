# Tune

[中文](README.md) · [English](README_en.md) · [日本語](README_ja.md) · [한국어](README_ko.md) · [Русский](README_ru.md)

Tune is a compact local and online music player built with Flutter. A persistent player occupies the left pane, while the right pane switches between library, queue, and settings.

## Features

- Scan, search, and persist local music folders
- Online sources: Openverse, Jamendo, Internet Archive, ccMixter, iTunes previews, podcast RSS, Audius, Wikimedia Commons, internet radio, and self-hosted NeteaseCloudMusicApi, Navidrome/Subsonic, or Jellyfin
- Queue management with reorder, play-at-index, and clear
- Play/pause, previous/next, seek, volume, and repeat modes
- Filter the library by source; remote tracks show source and artwork
- Light / dark / system themes; persistent scan paths and source settings
- Interface languages: 简体中文, 繁體中文, English, 日本語, 한국어, Deutsch, Français, Español, Русский — source names, dates and number formats follow the choice
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
- Remote playback requires a network connection; the desktop app caches tracks locally first, the web build streams them.
- Remote stream URLs can expire; Netease, Subsonic, podcast RSS, and Jellyfin refresh a single track, other sources need a rescan.
- Internet radio is a live stream: it is never cached and shows no progress bar.
- Legacy mobile notifications, lyrics, equalizer, history, and account features are no longer part of the main path.

## License

[MIT License](LICENSE)
