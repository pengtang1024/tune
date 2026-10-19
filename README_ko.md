# Tune

[中文](README.md) · [English](README_en.md) · [日本語](README_ja.md) · [한국어](README_ko.md) · [Русский](README_ru.md)

Tune은 Flutter로 만든 간결한 로컬 및 온라인 음악 플레이어입니다. 왼쪽에는 플레이어가 고정되고, 오른쪽에서 라이브러리·재생 대기열·설정을 전환합니다.

## 기능

- 로컬 음악 폴더 스캔, 검색, 영구 저장
- 온라인 음원: Openverse, Jamendo, Internet Archive, ccMixter, iTunes 미리듣기, 팟캐스트 RSS, Audius, Wikimedia Commons, 인터넷 라디오, 자체 NeteaseCloudMusicApi 또는 Navidrome/Subsonic, Jellyfin
- 재생 대기열 추가·삭제·드래그 정렬·비우기
- 재생/일시정지, 이전/다음, 탐색, 볼륨, 반복 모드
- 음원별 라이브러리 필터, 원격 곡의 음원 표시와 커버
- 라이트/다크/시스템 테마, 스캔 경로와 음원 설정 영구 저장
- 기본 창 900×600, 최소 760×520

## 기술 스택

- Flutter, Riverpod, go_router
- just_audio; Linux는 just_audio_media_kit + 시스템 libmpv
- Dio, shared_preferences, file_picker
- flutter_localizations / gen-l10n

## 구조

```text
lib/
├── app/                  # 진입점, 라우팅, 테마, 셸
├── features/             # player / library / queue / settings / sources
├── data/services/        # 오디오, 스캔, 음원 어댑터, 영구 저장
├── domain/models/        # Song, 음원 설정, 스캔 결과
├── shared/               # 공용 UI와 유틸리티
└── l10n/                 # 다국어 리소스
```

음원 모델은 [需求/音源设计.md](需求/音源设计.md)(중국어)를 참고하세요.

## 실행

```bash
flutter pub get
flutter run -d linux
```

## 빌드

```bash
flutter build linux --debug
```

## 알려진 제한

- 현재 주 대상은 Linux 데스크톱입니다.
- 원격 재생에는 네트워크가 필요합니다. 데스크톱은 먼저 로컬에 캐시하고 웹은 스트리밍으로 재생합니다.
- 원격 스트림 URL은 만료될 수 있습니다. Netease·Subsonic·팟캐스트·Jellyfin은 곡 단위로 주소를 갱신하지만 나머지 음원은 다시 스캔해야 합니다.
- 인터넷 라디오는 라이브 스트림이라 캐시하지 않고 진행 막대도 표시하지 않습니다.
- 기존 모바일 알림, 가사, 이퀄라이저, 기록, 계정 기능은 메인 경로에서 제외되었습니다.

## 라이선스

[MIT License](LICENSE)
