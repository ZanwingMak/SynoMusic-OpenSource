# SynoMusic

> Synology NAS를 위한 아름다운 네이티브 iOS 음악 클라이언트 — Audio Station 기반.

[English](README.md) · [简体中文](README.zh.md) · [日本語](README.ja.md) · [한국어](README.ko.md)

SynoMusic은 DSM의 Audio Station Web API를 통해 깨끗하고 빠른 iOS 네이티브 경험을 제공합니다: 라이브러리 탐색, 검색, 재생, 로컬 플레이리스트, 전 세계 라디오, 잠금 화면과 다이내믹 아일랜드에서의 완전한 컨트롤.

## 스크린샷

|  라이브러리  |  둘러보기  |  설정  |
| :---: | :---: | :---: |
| ![Library](docs/screenshots/01-library.png) | ![Browse](docs/screenshots/02-browse.png) | ![Settings](docs/screenshots/03-settings.png) |

|  플레이어  |  서버 편집  |
| :---: | :---: |
| ![Player](docs/screenshots/04-player.png) | ![Editor](docs/screenshots/05-editor.png) |

## 최신 릴리스: 1.2.8

- 전체 화면 플레이어 하단에 미다운로드 / 다운로드 중 / 다운로드 완료 상태를 보여주는 다운로드 버튼을 추가했습니다.
- 플레이어 메뉴, 가사 이동, 앨범 커버 펼침/접기, QuickConnect 릴레이 후보 처리를 개선했습니다.
- 자세한 내용은 [`CHANGELOG.md`](CHANGELOG.md)를 참고하세요.

## 기능

- **NAS 우선**: 다중 서버 프로파일, Keychain, 2단계 인증(OTP), 자체 서명 인증서 신뢰, HTTPS / QuickConnect
- **스트리밍**: AVQueuePlayer, 원음 실패 시 MP3 자동 폴백, AirPlay, CarPlay
- **라이브러리**: 앨범 / 아티스트 / 장르 / 폴더 / 서버 플레이리스트 / *모든 곡*
- **로컬 플레이리스트**: 여러 개의 사용자 정의, 기본 내장 "좋아요", 일괄 편집
- **라디오**: Radio-Browser API 기반 30,000+ 글로벌 방송국
- **플레이어**: 전체 화면, 동기화된 가사, 대기열 편집, 슬립 타이머, 커버 ↔ 가사 전환
- **시스템 통합**: 잠금 화면 Now Playing, 다이내믹 아일랜드 Live Activity, 원격 명령
- **테마**: 8가지 강조색 + 시스템 / 라이트 / 다크
- **다국어**: 중국어 간체/번체, 영어, 일본어, 한국어, 독일어, 프랑스어

## 시스템 요구 사항

- **iOS 17 이상** iPhone
- Synology NAS에 **Audio Station** 설치 및 대상 사용자에게 권한 부여
- 다이내믹 아일랜드: iPhone 14 Pro 이상

## 소스에서 빌드

```bash
brew install xcodegen
git clone https://github.com/ZanwingMak/SynoMusic.git
cd SynoMusic
xcodegen generate
open SynoMusic.xcodeproj
```

## 후원

- **PayPal** — [paypal.me/zanwing](https://paypal.me/zanwing)
- **Buy Me a Coffee** — [buymeacoffee.com/zanwing](https://buymeacoffee.com/zanwing)
- **Wise** — [wise.com/pay/me/zhenyingm1](https://wise.com/pay/me/zhenyingm1)
- **WeChat / Alipay** — 앱 내 "설정 → 후원하기"에서 QR

## 라이선스

본 프로젝트는 **GNU GPL v3.0** 라이선스를 따릅니다. 자세한 내용은 [`LICENSE`](LICENSE)를 참조하세요.

> SynoMusic은 비공식 Audio Station 클라이언트입니다. *Synology*, *DSM*, *Audio Station*은 Synology Inc.의 상표입니다.
