# Third-party notices

Tune's own source code is licensed under the [MIT License](LICENSE). The
components below are **not** covered by that MIT grant; each one keeps its own
license. This file is shipped with the application and is also shown from the
in-app license page.

## Fonts

Tune bundles the fonts listed below. They are unmodified and are licensed under
the **SIL Open Font License, Version 1.1** (OFL-1.1). The full OFL text is
reproduced at the end of this file, and each font directory also contains its
own `OFL.txt`.

| Font | Copyright |
| --- | --- |
| Fraunces | Copyright 2018 The Fraunces Project Authors (https://github.com/undercasetype/Fraunces) |
| Instrument Sans | Copyright 2022 The Instrument Sans Project Authors (https://github.com/Instrument/instrument-sans) |
| JetBrains Mono | Copyright 2020 The JetBrains Mono Project Authors (https://github.com/JetBrains/JetBrainsMono) |
| Noto Sans SC | Copyright © 2014-2021 Adobe (http://www.adobe.com/), with Reserved Font Name 'Source'. |
| Noto Serif SC | Copyright © 2017-2024 Adobe (http://www.adobe.com/). |

Noto Sans SC declares the Reserved Font Name `Source`; do not distribute a
modified version under that name without written permission. The other fonts do
not declare a Reserved Font Name in their metadata.

## Dart and Flutter packages

Tune uses Dart and Flutter packages. The Flutter tool collects their license
texts into the `NOTICES` file that is shipped inside the application bundle.
The packages that are not MIT are:

| Package | Version | License | Notes |
| --- | --- | --- | --- |
| `dbus` | 0.7.15 | Mozilla Public License 2.0 (MPL-2.0) | Used for MPRIS and the desktop tray. Unmodified. Source: https://pub.dev/packages/dbus |
| `charset` | 2.0.1 | Apache License 2.0 | Text decoding. |
| `rxdart` | 0.28.0 | Apache License 2.0 | Transitive dependency. |
| `material_color_utilities` | 0.13.0 | Apache License 2.0 | Transitive dependency. |
| `clock` | 1.1.3 | Apache License 2.0 | Transitive dependency. |
| `just_audio_media_kit` | 2.1.0 | The Unlicense | Linux audio bridge. Public domain. |
| Flutter and Dart SDK packages | see `pubspec.lock` | BSD-3-Clause | Copyright The Flutter Authors. |

The full texts of the MPL-2.0, Apache-2.0, BSD-3-Clause and Unlicense are in
the generated `NOTICES` file. `dbus` is not modified by Tune; its source is the
pub.dev release linked above.

## Vendored and modified packages

| Package | Version | License | Notes |
| --- | --- | --- | --- |
| `audio_metadata_reader` | 1.8.1 | MIT | Vendored under `vendor/audio_metadata_reader` with a local patch: `Buffer.read` clamps declared sizes to the bytes the file actually holds, so one corrupt tag header cannot trigger a gigabyte allocation. MIT, Copyright (c) 2023 Clément Béal, kept in the vendored `LICENSE`. The patch list and upgrade steps live in `vendor/audio_metadata_reader/VENDORED.md`. |

## Linux audio backend: libmpv and FFmpeg

On Linux, Tune uses `just_audio_media_kit` → `media_kit` → the **system**
`libmpv`. Tune does **not** bundle libmpv or FFmpeg. The Ubuntu packages are
declared as follows:

| Component | Version | License | Notes |
| --- | --- | --- | --- |
| `libmpv2` | 0.41.0-2ubuntu4 | GPL-3+ | See `/usr/share/doc/libmpv2/copyright`. Loaded at runtime with `dlopen`. |
| FFmpeg (`libavcodec`, `libavformat`, `libavutil`) | 7:8.0.1-3ubuntu2 | GPL-2+ | Ubuntu default build; pulled in by libmpv. See `/usr/share/doc/libavcodec62/copyright`. |

These are separate system components, not part of Tune's MIT-licensed code.
If you redistribute Tune together with libmpv/FFmpeg (for example in an
AppImage or Flatpak that includes those libraries), you must comply with the
GPL for that combined distribution. Tune's MIT license does not cover them.

* mpv source: https://github.com/mpv-player/mpv
* FFmpeg source: https://ffmpeg.org/

## Flutter engine

The Flutter engine is distributed under the BSD-3-Clause license. Its
third-party notices, including ICU, FreeType and IJG, are collected in the
same `NOTICES` file.

## Removed third-party JavaScript

The former MusicFree-compatible JavaScript plugin bundle that lived under
`assets/js/` has been removed. Tune no longer ships or loads that bundle.

---

## SIL Open Font License, Version 1.1

This Font Software is licensed under the SIL Open Font License, Version 1.1.

This license is copied below, and is also available with a FAQ at:
http://scripts.sil.org/OFL

-----------------------------------------------------------
SIL OPEN FONT LICENSE Version 1.1 - 26 February 2007
-----------------------------------------------------------

PREAMBLE
The goals of the Open Font License (OFL) are to stimulate worldwide
development of collaborative font projects, to support the font
creation efforts of academic and linguistic communities, and to
provide a free and open framework in which fonts may be shared and
improved in partnership with others.

The OFL allows the licensed fonts to be used, studied, modified and
redistributed freely as long as they are not sold by themselves. The
fonts, including any derivative works, can be bundled, embedded,
redistributed and/or sold with any software provided that any reserved
names are not used by derivative works. The fonts and derivatives,
however, cannot be released under any other type of license. The
requirement for fonts to remain under this license does not apply to
any document created using the fonts or their derivatives.

DEFINITIONS
"Font Software" refers to the set of files released by the Copyright
Holder(s) under this license and clearly marked as such. This may
include source files, build scripts and documentation.

"Reserved Font Name" refers to any names specified as such after the
copyright statement(s).

"Original Version" refers to the collection of Font Software
components as distributed by the Copyright Holder(s).

"Modified Version" refers to any derivative made by adding to,
deleting, or substituting -- in part or in whole -- any of the
components of the Original Version, by changing formats or by porting
the Font Software to a new environment.

"Author" refers to any designer, engineer, programmer, technical
writer or other person who contributed to the Font Software.

PERMISSION & CONDITIONS
Permission is hereby granted, free of charge, to any person obtaining
a copy of the Font Software, to use, study, copy, merge, embed,
modify, redistribute, and sell modified and unmodified copies of the
Font Software, subject to the following conditions:

1) Neither the Font Software nor any of its individual components, in
Original or Modified Versions, may be sold by itself.

2) Original or Modified Versions of the Font Software may be bundled,
redistributed and/or sold with any software, provided that each copy
contains the above copyright notice and this license. These can be
included either as stand-alone text files, human-readable headers or
in the appropriate machine-readable metadata fields within text or
binary files as long as those fields can be easily viewed by the user.

3) No Modified Version of the Font Software may use the Reserved Font
Name(s) unless explicit written permission is granted by the
corresponding Copyright Holder. This restriction only applies to the
primary font name as presented to the users.

4) The name(s) of the Copyright Holder(s) or the Author(s) of the Font
Software shall not be used to promote, endorse or advertise any
Modified Version, except to acknowledge the contribution(s) of the
Copyright Holder(s) and the Author(s) or with their explicit written
permission.

5) The Font Software, modified or unmodified, in part or in whole,
must be distributed entirely under this license, and must not be
distributed under any other license. The requirement for fonts to
remain under this license does not apply to any document created using
the Font Software.

TERMINATION
This license becomes null and void if any of the above conditions are
not met.

DISCLAIMER
THE FONT SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO ANY WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT
OF COPYRIGHT, PATENT, TRADEMARK, OR OTHER RIGHT. IN NO EVENT SHALL THE
COPYRIGHT HOLDER BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
INCLUDING ANY GENERAL, SPECIAL, INDIRECT, INCIDENTAL, OR CONSEQUENTIAL
DAMAGES, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF THE USE OR INABILITY TO USE THE FONT SOFTWARE OR FROM
OTHER DEALINGS IN THE FONT SOFTWARE.
