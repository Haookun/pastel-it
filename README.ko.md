# Pastel it！

<img src="Resources/AppIcon.png" width="144" alt="Pastel it！">

네이티브 macOS 클립보드 도구입니다. 텍스트·이미지 기록, 다국어 OCR, macOS 26 이상 표 OCR, 가로 휠 탐색, 복사 시간축, 현재 클립보드를 변환하는 빠른 붙여넣기를 제공합니다.

[English](README.en.md) · [中文 / 功能说明](README.md) · [Design](docs/design.md) · [Validation](docs/validation.md)

This is a private derivative of [Paste It](https://github.com/yipeng-git/paste-it), not an upstream release. No installer has been published. Automatic updates from the original project are disabled. macOS 14+ and Swift tools 6.2+ are required.

```sh
swift build
swift test
```

Quick Paste starts disabled and attempts ⇧⌘V on first enablement. Its shortcut is separate from Open History; conflicts must be resolved before enabling it. Existing internal identifiers and the data directory are retained for compatibility; do not run both apps side by side. See [LICENSE](LICENSE) for upstream MIT attribution.
