# Pastel it！

<img src="Resources/AppIcon.png" width="144" alt="Pastel it！">

네이티브 macOS 클립보드 도구입니다. 텍스트·이미지 기록, 다국어 OCR, macOS 26 이상 표 OCR, 가로 휠 탐색, 복사 시간축, 현재 클립보드를 변환하는 빠른 붙여넣기를 제공합니다.

[English](README.en.md) · [中文 / 功能说明](README.md) · [Design](docs/design.md) · [Validation](docs/validation.md)

This is a private derivative of [Paste It](https://github.com/yipeng-git/paste-it), not an upstream release. No installer has been published. Automatic updates from the original project are disabled. macOS 14+ and Swift tools 6.2+ are required.

```sh
swift build
swift test
```

Open History defaults to ⇧⌘C; Quick Paste defaults to ⇧⌘V and starts disabled. The standalone legacy plain-paste command is removed. Paste Stack and MCP are archived with all product entries and runtime activation disabled. Existing internal identifiers and the data directory are retained for compatibility; do not run both apps side by side. See [LICENSE](LICENSE) for upstream MIT attribution.

설정의 클립보드 → 표시 스타일에서 타임라인과 후보 막대를 선택할 수 있습니다. 페이지당 10개 항목을 세로로 표시하며 1–9와 0으로 선택하고 Tab으로 다음 페이지, Shift-Tab으로 이전 페이지로 이동합니다. 이미지 OCR 요약과 파일 이름을 표시하고 마우스를 올리면 이미지나 전체 경로를 미리 봅니다.

후보 막대는 텍스트 커서 옆에 표시되고 아래 공간이 부족하면 위로 이동합니다. 손쉬운 사용 권한이나 커서 위치를 사용할 수 없으면 안내와 함께 포인터 근처에 표시합니다.
