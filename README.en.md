# Pastel it！

<img src="Resources/AppIcon.png" width="144" alt="Pastel it！ cream tart icon">

A private macOS clipboard derivative of [Paste It](https://github.com/yipeng-git/paste-it), with local text/image history, multilingual OCR, optional Markdown table recognition on macOS 26+, a horizontal mouse-wheel card strip, copy-time navigation, and configurable quick plain-text paste.

[中文](README.md) · [Feature details](docs/features.md) · [Design](docs/design.md) · [Validation](docs/validation.md) · [Origin](docs/origin.md)

## Current behavior

- Settings → OCR controls recognition, automatic or selected languages, tables, fast/accurate mode, language correction, and minimum text height. Existing results stay when OCR is disabled; use **Re-run** for older images.
- The bottom ruler navigates original copy times within current filters. Hover magnifies a time; click or drag targets the nearest record. It does not store every repeated-copy event.
- Quick Paste is off by default and reads the **current system clipboard**. Select text without formatting, image OCR, and/or file names. Its initial shortcut is ⇧⌘V; it is separate from Open History and conflicts are rejected without overwriting existing bindings.
- Without Accessibility, converted plain text remains ready for manual ⌘V. Automatic pasting restores the original clipboard unless newer content was copied; conversion cancels if the destination changes.
- History, pinning, folders, configurable/clearable shortcuts, and Paste Stack remain available. Local MCP is off by default.

## Build

Requires macOS 14+ and Swift tools 6.2+. Modern text OCR uses macOS 15+, and table recognition needs macOS 26+. Fresh clones use pinned public dependencies (Sparkle 2.9.4, MCP 0.12.1, PostHog 3.59.3).

```sh
git clone https://github.com/Haookun/pastel-it.git
cd pastel-it
swift build
swift test
```

Existing offline repair copies can be selected with `PASTEL_USE_LOCAL_DEPENDENCIES=1`. They are not committed. Packaging requires your own Developer ID certificate. No installer or release has been published, and upstream automatic updates are disabled for this derivative.

Internal target names, bundle identifier and data directory remain compatible with the original app; do not run the two versions side by side. MIT attribution is retained in [LICENSE](LICENSE).
