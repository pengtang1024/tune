# Tune

[中文](README.md) · [English](README_en.md)

Tune is a compact local and online music player built with Flutter. A persistent player occupies the left pane, while the right pane switches between library, queue, and settings.

## Features

- Scan, search, and persist local music folders
- Online sources: Openverse, Jamendo, Internet Archive, ccMixter, iTunes previews, podcast RSS, Audius, Wikimedia Commons, internet radio, and self-hosted NeteaseCloudMusicApi, Navidrome/Subsonic, or Jellyfin
- Add sources of your own: pick a type (direct audio, playlist, …), fill in its parameters, and it becomes a new source; one type can be added more than once
- Queue management with reorder, play-at-index, and clear
- Play/pause, previous/next, seek, volume, and repeat modes
- Filter the library by source; remote tracks show source and artwork
- Track rows mark format, quality and bitrate with icons; hover to read them, open a track for all of its facts and its path
- Likes: a heart in the track rows, the queue and the now playing page; the tracks you mark wait in the Liked page
- Light / dark / system themes; persistent scan paths and source settings
- Interface languages: 简体中文, 繁體中文, 中文（通用）, English — source names, dates and number formats follow the choice
- 900×600 default window, 760×520 minimum
- Linux desktop integration: a tray icon that keeps playback alive after the window closes, MPRIS media controls (media keys, `playerctl`), and Tune can become the default program for audio files

## Stack

- Flutter, Riverpod, go_router
- just_audio; Linux playback through just_audio_media_kit + system libmpv
- Dio, shared_preferences, file_picker
- flutter_localizations / gen-l10n

## Structure

```text
lib/
├── app/                  # entry, routing, theme, shell
├── features/             # player / library / queue / settings / sources / desktop
├── data/services/        # audio, scanning, source adapters, persistence, MPRIS, tray
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

## Desktop icon

- The master image is `branding/app_icon.png`; run `dart run flutter_launcher_icons` to regenerate the platform icons after changing it. The master is not packaged; `assets/` only holds what the app needs at runtime.
- The Linux theme icons follow one extra rule: the art is inset to 13/16 of the canvas so the icon ends up the same size as the other applications. Run `dart run tool/generate_linux_icons.dart` after changing the master.
- On Linux the dock and the taskbar icon come from the desktop entry, and the program carries a window icon of its own.
- The desktop entry has to be installed into the XDG directories of the machine, otherwise the dock falls back to a generic icon (install it once per machine):

```bash
flutter build linux --debug
./linux/install-desktop-entry.sh
```

## Known limitations

- Linux desktop is the primary target for the current release.
- Remote playback requires a network connection; the desktop app plays while it caches, so playback never waits for the download, and the web build streams tracks.
- Remote stream URLs can expire; Netease, Subsonic, podcast RSS, and Jellyfin refresh a single track, other sources need a rescan.
- Internet radio is a live stream: it is never cached and shows no progress bar.
- Legacy mobile notifications, lyrics, equalizer, history, and account features are no longer part of the main path.
- Arbitrary script plugins are not supported: the former MusicFree JS plugin support is gone, custom sources take declarative parameters only.

## License

[MIT License](LICENSE)
