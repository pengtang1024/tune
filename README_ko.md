# Tune - 크로스 플랫폼 음악 플레이어

<p align="center">
  <img src="app.png" width="200" alt="Tune Logo" />
</p>

<p align="center">
  모든 멜로디에게 돌아갈 곳을
</p>

<p align="center">
  <a href="README.md">中文</a> •
  <a href="README_en.md">English</a> •
  <a href="README_ja.md">日本語</a> •
  <a href="README_ko.md">한국어</a> •
  <a href="README_ru.md">Русский</a>
</p>

## 🎵 Tune에 대해

바쁜 일상 속에서 마음속에 살며시 머무는 멜로디가 있습니다 — 아침에 당신을 깨우는 밝은 리듬, 심야에 함께해주는 부드러운 민요, 여행 중 우연히 만나는 서프라이즈 싱글 곡일 수도 있습니다.

Tune은 음악 플레이어 이상으로 당신의 개인적인 「멜로디 수납함」입니다. 여기서 로컬 음악 라이브러리를 쉽게 정리하고, 스타일, 기분, 장면별로 플레이리스트를 커스터마이즈할 수 있습니다. 각 곡이 가장 적합한 위치에서 당신을 기다립니다. 원활한 재생 경험과 섬세한 음향 조정을 통해 헤드폰의 각 음符가 선명하고 풍부하게 울려 퍼져 라이브 공연장에 있는 것처럼 느껴집니다. 심플하면서도 세련된 인터페이스 디자인에는 음악에 대한 순수한 사랑이 담겨 있으며, 불필요한 방해 없이 당신과 음악만의 여유로운 시간을 제공합니다.

수년간 소중히 간직한 클래식 곡이든, 새로 발견한 마이너 명작이든, Tune이 꼼꼼히 보관해주어 매번의 재생이 아름다운 청각의 재회가 됩니다.

Tune으로 음악을 본래의 모습으로 되돌리고, 모든 시간에 멜로디를 함께하세요.

## 🌟 특징

- 🎧 **고품질 오디오 재생** - MP3, FLAC, WAV 등 다양한 오디오 포맷 지원
- 📚 **로컬 음악 관리** - 로컬 음악 라이브러리 자동 스캔 및 정리, 메타데이터 파싱 지원
- 🎨 **멀티 테마 지원** - 8가지 아름다운 테마(트렌디 일렉트로, 미니멀 그레이, 내츄럴 포레스트, 사이버 네온, 웜 힐링 등), 다크/라이트 모드 자동 전환
- 🌍 **다국어 지원** - 중국어, 영어, 일본어, 한국어, 러시아어 지원
- 📱 **크로스 플랫폼 호환성** - Android, iOS, Windows, macOS, Linux, Web 전 플랫폼 지원
- ⚡ **원활한 경험** - 백그라운드 재생, 알림 컨트롤, 빠른 검색
- 🎛️ **개인화** - 폰트, 테마, 언어 등 풍부한 커스터마이즈 옵션
- 🎯 **스마트 추천** - 재생 기록 기반 개인화된 음악 추천
- 📥 **오프라인 캐시** - 온라인 음악 캐시 지원으로 언제든지 음악을 즐길 수 있음
- 📋 **플레이리스트** - 맞춤 플레이리스트 생성 및 관리 지원
- 🔄 **다중 재생 모드** - 리스트 루프, 싱글 루프, 셔플 재생
- ⏩ **재생 컨트롤** - 재생 진행 드래그, 볼륨 조절, 재생 속도 조절(0.5x-2.0x) 지원
- 🎵 **가사 동기화** - LRC 포맷 가사 실시간 표시 지원
- 🔍 **스마트 검색** - 곡명, 아티스트, 앨범별 검색 지원

## 🎨 테마 미리보기

Tune은 선택 가능한 여러 아름다운 테마를 제공합니다:

1. **트렌디 일렉트로** - 보라색을 기반으로 한 현대적인 전자 스타일
2. **미니멀 그레이** - 깔끔한 회색 톤 디자인
3. **내츄럴 포레스트** - 신선한 녹색 자연 스타일
4. **사이버 네온** - 미래지향적인 네온 컬러
5. **웜 힐링** - 따뜻한 오렌지 힐링 스타일
6. **웜 오렌지 그라데이션** - 그라데이션 오렌지 따뜻한 스타일
7. **모노크롬** - 통일된 컬러의 미니멀 디자인
8. **비비드 레드** - 열정적인 빨간 테마

모든 테마는 「라이트 모드에서는 밝고 투명하게, 다크 모드에서는 섬세하고 세련되게」라는 디자인 철학을 따르며, 저채도 컬러 매칭으로 고급스러움을 연출합니다.

## 🛠 기술 아키텍처

Tune은 Clean Architecture + BLoC 패턴을 채택하여 코드의 유지보수성과 확장성을 보장합니다:

```
lib/
├── app/                    # 애플리케이션 코어 설정
│   ├── router/             # 라우팅 관리
│   └── theme/              # 테마 시스템
├── core/                   # 코어 계층
│   ├── bloc/               # 글로벌 상태 관리
│   ├── config/             # 애플리케이션 설정
│   ├── error/              # 에러 핸들링
│   ├── network/            # 네트워크 관련
│   ├── services/           # 코어 서비스
│   ├── storage/            # 데이터 저장소
│   ├── utils/              # 유틸리티 클래스
│   └── widgets/            # 코어 컴포넌트
├── features/               # 기능 모듈
│   ├── audio/              # 오디오 재생 기능
│   ├── home/               # 홈 모듈
│   ├── library/            # 음악 라이브러리 모듈
│   ├── player/             # 플레이어 모듈
│   ├── profile/            # 프로필 모듈
│   ├── search/             # 검색 모듈
│   └── settings/           # 설정 모듈
├── l10n/                   # 국제화 리소스
└── di/                     # 의존성 주입
```

## 🚀 빠른 시작

### 환경 요구사항

- Flutter SDK 3.8.1 이상
- Dart SDK 3.8.1 이상
- 지원 IDE (Android Studio / VS Code)

### 의존성 설치

```bash
flutter pub get
```

### 애플리케이션 실행

```bash
# 개발 모드로 실행
flutter run

# 특정 플랫폼용으로 빌드
flutter build apk      # Android
flutter build ios      # iOS
flutter build web      # Web
flutter build windows  # Windows
flutter build macos    # macOS
flutter build linux    # Linux
```

## 🔧 주요 의존성

- **오디오 재생**: [just_audio](https://pub.dev/packages/just_audio)
- **상태 관리**: [flutter_bloc](https://pub.dev/packages/flutter_bloc)
- **라우팅**: [auto_route](https://pub.dev/packages/auto_route)
- **로컬 저장소**: [hive](https://pub.dev/packages/hive), [shared_preferences](https://pub.dev/packages/shared_preferences)
- **네트워크 요청**: [dio](https://pub.dev/packages/dio)
- **의존성 주입**: [get_it](https://pub.dev/packages/get_it)
- **국제화**: [flutter_localizations](https://flutter.dev/docs/development/accessibility-and-localization/internationalization)

## 📱 플랫폼 지원

| 플랫폼   | 상태     | 비고 |
|----------|----------|------|
| Android  | ✅ 지원   | API 21+ |
| iOS      | ✅ 지원   | iOS 11+ |
| Windows  | ✅ 지원   | Windows 10+ |
| macOS    | ✅ 지원   | macOS 10.15+ |
| Linux    | ✅ 지원   | Ubuntu 20.04+ |
| Web      | ✅ 지원   | 현대 브라우저 |

## 🤝 기여

모든 형태의 기여를 환영합니다! Tune에 기여하고 싶으시다면 다음 단계를 따르세요:

1. 저장소 포크
2. 기능 브랜치 생성 (`git checkout -b feature/AmazingFeature`)
3. 변경 사항 커밋 (`git commit -m 'Add some AmazingFeature'`)
4. 브랜치에 푸시 (`git push origin feature/AmazingFeature`)
5. 풀 리퀘스트 생성

## 📄 라이선스

이 프로젝트는 MIT 라이선스 하에 라이선스됩니다 - 자세한 내용은 [LICENSE](LICENSE) 파일을 참조하세요.

## 🙏 감사의 말

- 오픈소스 커뮤니티에 기여하는 모든 개발자에게 감사
- 우수한 프레임워크를 제공하는 Flutter 팀에게 감사
- 개발 도구 지원을 제공하는 JetBrains에게 감사

---

<p align="center">
  Tune으로 음악을 본래의 모습으로 되돌리고, 모든 시간에 멜로디를 함께하세요.
</p>