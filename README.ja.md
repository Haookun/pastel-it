# Pastel it！

<img src="Resources/AppIcon.png" width="144" alt="Pastel it！">

原生 macOS クリップボード管理ツール。テキスト・画像の履歴、多言語 OCR、macOS 26 以降の表 OCR、横方向のホイール操作、コピー日時のルーラー、現在のクリップボードを変換するクイックペーストを備えます。

[English](README.en.md) · [中文 / 功能说明](README.md) · [Design](docs/design.md) · [Validation](docs/validation.md)

This is a private derivative of [Paste It](https://github.com/yipeng-git/paste-it), not an upstream release. No installer has been published. Automatic updates from the original project are disabled. macOS 14+ and Swift tools 6.2+ are required.

```sh
swift build
swift test
```

Quick Paste starts disabled and attempts ⇧⌘V on first enablement. Its shortcut is separate from Open History; conflicts must be resolved before enabling it. Existing internal identifiers and the data directory are retained for compatibility; do not run both apps side by side. See [LICENSE](LICENSE) for upstream MIT attribution.
