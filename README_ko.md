# Tune - 당신의 개인 멜로디 상자 🎵

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
  <img src="https://img.shields.io/badge/플랫폼-Android%20%7C%20iOS%20%7C%20Windows%20%7C%20macOS%20%7C%20Linux%20%7C%20Web-blue" alt="지원되는 플랫폼" />
  <img src="https://img.shields.io/badge/Flutter-%5E3.0-green" alt="Flutter 버전" />
  <img src="https://img.shields.io/badge/라이선스-MIT-blue.svg" alt="라이선스" />
</p>

Tune은 단순한 음악 플레이어가 아니라 당신의 개인적인 "멜로디 보관함"입니다. 여기서 로컬 음악 라이브러리를 쉽게 정리하고, 스타일, 분위기, 상황별로 재생목록을 사용자 정의하여 각 곡이 가장 적합한 위치에서 당신을 기다리도록 할 수 있습니다. 매끄러운 재생 경험과 섬세한 음향 조절을 통해 헤드폰의 모든 음표가 선명하고 풍부해지며, 마치 현장에 있는 것처럼 느껴집니다. 심플하면서도 세련된 인터페이스 디자인은 음악에 대한 순수한 사랑을 숨기고, 불필요한 산만함 없이 당신과 음악만의 고요한 시간을 제공합니다.

수년간 간직한 클래식한 명곡이든, 최근 발견한 니치한 걸작이든, Tune은 모두를 적절히 보관하여 매번 열 때마다 아름다운 청각적 재회가 되도록 합니다.

Tune과 함께 음악을 본질로 되돌리고, 모든 순간을 멜로디와 함께 보내세요.

## 🎵 주요 기능

🎵 **로컬 음악 라이브러리 관리** - 로컬 음악 파일을 쉽게 정리할 수 있는 깨끗하고 직관적인 인터페이스

📋 **사용자 정의 재생목록** - 장르, 분위기, 상황별로 재생목록을 만들어 완벽한 청취 경험 제공

🔊 **고품질 오디오 재생** - just_audio를 통합하여 MP3, FLAC, WAV 등 여러 형식을 지원하는 고품질 오디오 재생

🎚️ **이퀄라이저 및 사운드 제어** - 사용자 정의 가능한 사운드 설정과 볼륨 조절로 오디오 미세 조정

🎨 **다양한 테마** - Trendy Electro, Minimal Gray, Nature Forest, Cyber Neon, Warm Healing 등 5가지 아름다운 프리셋 테마와 라이트/다크 모드 지원

🌍 **다국어 지원** - 영어, 중국어, 일본어, 한국어, 러시아어 등 5개 언어의 완전한 지원과 쉬운 전환

📱 **크로스 플랫폼** - 모바일, 데스크톱, 웹을 위한 아름답게 설계된 반응형 레이아웃

⏯️ **백그라운드 재생** - 알림 제어를 통해 다른 앱을 사용하는 동안에도 계속 듣기

## 🏗️ 기술 아키텍처

이 프로젝트는 Clean Architecture + BLoC 패턴의 계층화 아키텍처를 채택하여 크로스 플랫폼 일관성과 유지보수성을 보장합니다.

### 아키텍처 계층

```
lib/
├── config/                 # 설정 파일
│   └── theme/              # 테마 설정
├── core/                   # 코어 계층
│   ├── di/                 # 의존성 주입
│   ├── routes/             # 라우트 관리
│   ├── services/           # 코어 서비스
│   └── utils/              # 유틸리티 클래스
├── data/                   # 데이터 계층
│   ├── datasources/        # 데이터 소스
│   ├── models/             # 데이터 모델
│   └── repositories/       # 리포지토리 구현
├── domain/                 # 도메인 계층
│   ├── entities/           # 엔티티
│   ├── repositories/       # 리포지토리 인터페이스
│   └── usecases/           # 유스케이스
└── presentation/           # 표현 계층
    ├── bloc/               # 상태 관리
    ├── pages/              # 페이지
    ├── widgets/            # 일반 컴포넌트
    └── components/         # 비즈니스 컴포넌트
```

### 핵심 모듈

- **오디오 재생 코어 모듈** - just_audio를 사용하여 재생, 일시정지, 건너뛰기 및 진행 상황 제어 구현
- **음악 라이브러리 모듈** - 온라인 스트리밍 지원이 포함된 로컬 음악 검색을 위한 사용자 정의 구현
- **재생목록 모듈** - 재생목록 저장을 위해 Hive 사용
- **사용자 모듈** - 사용자 세션에 shared_preferences를 사용한 타사 로그인 지원
- **UI/UX 모듈** - 사용자 정의 가능한 테마와 다크 모드를 갖춘 반응형 디자인

## 📦 주요 기술 스택

- **상태 관리**: [flutter_bloc](https://pub.dev/packages/flutter_bloc)
- **라우트 관리**: [auto_route](https://pub.dev/packages/auto_route)
- **오디오 재생**: [just_audio](https://pub.dev/packages/just_audio)
- **로컬 음악 검색**: 사용자 정의 구현
- **권한 관리**: [permission_handler](https://pub.dev/packages/permission_handler)
- **의존성 주입**: [get_it](https://pub.dev/packages/get_it)
- **국제화**: [flutter_localizations](https://pub.dev/packages/flutter_localizations)

## 🚀 빠른 시작

1. 프로젝트 클론:
   ```bash
   git clone <repository-url>
   ```

2. 의존성 설치:
   ```bash
   flutter pub get
   ```

3. 애플리케이션 실행:
   ```bash
   flutter run
   ```

## 🎯 플랫폼 적응

- **모바일**: 백그라운드 재생, 잠금 화면 제어, 알림 플레이어 제어가 포함된 플랫폼 디자인 지침 준수
- **데스크톱**: 시스템 트레이 통합, 키보드 단축키, 다중 창 지원이 포함된 창 레이아웃 디자인
- **Web**: PWA 지원이 포함된 브라우저 오디오 제한을 처리하는 반응형 웹 디자인

## 🛠️ 유용한 명령어

### 국제화

수동으로 로컬라이제이션 파일 생성:
```bash
flutter gen-l10n
```

### 아이콘

flutter_launcher_icons를 사용하여 앱 아이콘 자동 생성:
```bash
flutter pub run flutter_launcher_icons:main
```

### 코드 생성

build_runner 실행하여 코드 생성:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 테스트

모든 테스트 실행:
```bash
flutter test
```

커버리지와 함께 테스트 실행:
```bash
flutter test --coverage
```

## 🧪 테스트 전략

- **단위 테스트**: 유스케이스 및 리포지토리 로직 테스트
- **통합 테스트**: 데이터 소스 및 네트워크 요청 테스트
- **위젯 테스트**: UI 컴포넌트 테스트
- **엔드투엔드 테스트**: 사용자 흐름 테스트

## 📈 확장성 고려사항

- 플러그인 기반 아키텍처
- API 버전 제어 지원
- 구성 가능한 테마
- 안정성 보장을 위한 모듈식 테스트

## 📄 라이선스

이 프로젝트는 MIT 라이선스에 따라 라이선스가 부여됩니다 - 자세한 내용은 [LICENSE](LICENSE) 파일을 참조하세요.