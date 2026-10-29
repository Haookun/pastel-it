# Pastel it！

macOS용 클립보드 기록 및 기기 내 OCR 도구입니다. [Paste It](https://github.com/yipeng-git/paste-it)을 기반으로 **OpenAI Codex**가 주요 추가·수정 코드를 작성하고 통합했으며, **Kimi Code**가 일부 UI 설계와 구현에 참여했습니다. 원본 프로젝트와 라이브러리의 저작권 및 라이선스는 유지됩니다.

[English](README.en.md) · [中文](README.md) · [문서 안내](docs/README.md) · [출처와 의존성](THIRD_PARTY_NOTICES.md)

- 텍스트, 이미지, 링크와 파일 참조의 기록을 검색하고 정리합니다.
- 화면 아래 시간축 또는 입력 커서 근처의 세로 후보 목록을 선택합니다.
- 후보는 페이지당 10개이며 `1`–`9`, `0`으로 선택하고 `Tab`／`Shift-Tab`으로 넘깁니다.
- Vision으로 기기 내 OCR을 수행하며 macOS 26 이상에서는 Markdown 표를 출력할 수 있습니다.
- 빠른 붙여넣기는 현재 시스템 클립보드를 변환하며 기본적으로 꺼져 있습니다.
- 사용 통계를 전송하지 않고 로컬 로그만 따로 지울 수 있습니다. 링크 미리보기와 직접 요청한 언어 복구는 네트워크를 사용할 수 있습니다.

기록 열기는 `⇧⌘C`, 빠른 붙여넣기는 `⇧⌘V`입니다. 최소 배포 대상은 macOS 14, 빌드 도구는 Swift 6.2 이상입니다. 실제 검증은 Apple Silicon／macOS 27.0.1에서 수행했으며 다른 환경은 미검증입니다.

공식 바이너리와 자동 업데이트는 없습니다. 2026-10-29에는 문서만 정리하며 외부 배포용 패키지는 프로젝트 공개 후 다시 논의합니다. 향후 앱별 Open Anyway 방안은 [분发约定](docs/distribution.md)에 기록했습니다. 빌드 절차와 로컬 의존성 사본의 검증 범위는 [개발 안내](docs/development.md)를 참고하세요.

직접 의존성은 Sparkle 2.9.4와 MCP Swift SDK 0.12.1이며 업데이트와 MCP 서비스 시작은 비활성화되어 있습니다. 원본 앱과 데이터 식별자를 공유하므로 동시에 실행하지 마세요. [LICENSE](LICENSE) · [전체 라이선스 기록](LICENSES/README.md)
