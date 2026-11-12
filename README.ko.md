# Pastel it！ — 한국어

macOS 클립보드 기록 및 로컬 OCR 도구입니다. 기본 화면은 입력 커서 옆의 세로 후보 목록(10개)이며 타임라인으로 전환할 수 있습니다.

후보를 오른쪽 클릭하면 붙여넣기, 일반 텍스트로 바로 붙여넣기, 일반 텍스트 복사를 선택할 수 있습니다. 이미지의 텍스트 작업은 클릭할 때 원본 이미지를 OCR로 인식합니다. 자동 OCR이 꺼져 있어도 실행됩니다.

[中文完整说明](README.md) · [Full English guide](README.en.md) · [Download v0.3.0](https://github.com/Haookun/pastel-it/releases/latest)

- Apple Silicon (arm64) DMG; macOS14+ deployment target, modern OCR15+, table OCR26+.
- Ad-hoc signed, **not Apple notarized**. [Open Anyway / installation](docs/distribution.md).
- Independent identity: `io.github.haookun.pastel-it`; fresh data: `~/Library/Application Support/PastelIt/`. No automatic migration from Paste It.
- No usage analytics; local diagnostics only. Automatic updates and MCP are disabled.

Derived from [Paste It](https://github.com/yipeng-git/paste-it) by Yipeng Zhang and contributors. Main derivative additions written and integrated with OpenAI Codex; selected UI work with Kimi Code. [Credits and licenses](THIRD_PARTY_NOTICES.md).

Build instructions and validation limits remain available in the [English README](README.en.md) and [development guide](docs/development.md).
