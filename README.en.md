# Pastel it！

<img src="Resources/AppIcon.png" width="144" alt="Pastel it！ cream tart icon">

A private macOS clipboard derivative of [Paste It](https://github.com/yipeng-git/paste-it), with local text/image history, multilingual OCR, optional Markdown table recognition on macOS 26+, a horizontal mouse-wheel card strip, copy-time navigation, and configurable quick plain-text paste.

[中文](README.md) · [Feature details](docs/features.md) · [Design](docs/design.md) · [Validation](docs/validation.md) · [Manual checklist](docs/manual-validation.md) · [Origin](docs/origin.md)

## Current behavior

- Settings → OCR controls recognition, automatic or selected languages, tables, fast/accurate mode, language correction, and minimum text height. Existing results stay when OCR is disabled; use **Re-run** for older images.
- The bottom ruler navigates original copy times within current filters. Hover magnifies a time; click or drag targets the nearest record. It does not store every repeated-copy event.
- Quick Paste is off by default and reads the **current system clipboard**. Select text without formatting, image OCR, and/or file names. Defaults are ⇧⌘C for Open History and ⇧⌘V for Quick Paste. Conflicts are rejected without overwriting existing bindings.
- Without Accessibility, converted plain text remains ready for manual ⌘V. Automatic pasting restores the original clipboard unless newer content was copied; conversion cancels if the destination changes.
- History, pinning, folders and configurable shortcuts remain available. The legacy standalone plain-paste command is removed. Paste Stack and MCP code are retained but have no runtime wiring, listeners or UI entries.

## Build

Requires macOS 14+ and Swift tools 6.2+. Modern text OCR uses macOS 15+, and table recognition needs macOS 26+. Fresh clones use pinned public dependencies (Sparkle 2.9.4, MCP 0.12.1).

```sh
git clone https://github.com/Haookun/pastel-it.git
cd pastel-it
swift build
swift test
```

Existing offline repair copies can be selected with `PASTEL_USE_LOCAL_DEPENDENCIES=1`. They are not committed. For local use, run `./scripts/package-release.sh --variant arm64 --local-test`: it uses ad-hoc signing without a certificate or notarization. Launch with `--validation-session` to use synthetic in-memory history and isolated preferences. Developer ID signing is an optional future distribution path. No installer or release has been published, and upstream automatic updates are disabled for this derivative.

Internal target names, bundle identifier and data directory remain compatible with the original app; do not run the two versions side by side. MIT attribution is retained in [LICENSE](LICENSE).

### Clipboard presentation

Settings → Clipboard → Display Style switches between Timeline (default) and Candidate Bar. The vertical native list shows up to ten clips per page; 1–9 and 0 select, Tab goes forward, Shift-Tab goes back, arrows browse, Return confirms and Escape closes. Paging stops at either end. Images show OCR summaries, files show names, and hover previews show images or full file paths. Selection keeps the original content type and follows the existing Copy/Direct Paste preference. Both presentations use the same configured clipboard shortcut (default ⇧⌘C).

The candidate bar opens beside the text insertion caret, flips above it when needed, and stays within the active display. It reads geometry through macOS Accessibility; when permission or caret geometry is unavailable, it falls back beside the pointer with a notice.

Settings use a standard macOS title bar with App, Data and About groups. OCR and Quick Paste have separate pages. A vector animation previews both display styles; candidate mode includes an explicit Accessibility permission button.

No usage analytics are collected or uploaded. Local diagnostic logs can be cleared in Settings → Privacy → Delete Past Logs without deleting settings, history, or attachments. See [local diagnostics](docs/analytics.md).

Missing interface resources fall back to built-in English and show a repair prompt. Settings → About provides verified language-pack download/import. Private repositories require browser sign-in and import; public repositories support direct download. Settings and history stay intact. See [language recovery](docs/language-recovery.md).
