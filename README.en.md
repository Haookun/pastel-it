# Pastel it！

<img src="Resources/AppIcon.png" width="128" alt="Pastel it！ tart icon">

**A native macOS clipboard manager with on-device OCR, a copy-time timeline and a candidate list beside your typing caret.**

[中文](README.md) · [User guide](docs/getting-started.md) · [Documentation](docs/README.md) · [Development & AI workflow](docs/development.md) · [Attribution & dependencies](THIRD_PARTY_NOTICES.md)

> Derived from [Paste It](https://github.com/yipeng-git/paste-it), by Yipeng Zhang and contributors. **OpenAI Codex wrote and integrated the main additions and modifications in this derivative**, with the maintainer defining requirements and accepting behavior. **Kimi Code** contributed selected UI design and implementation. Upstream code and third-party components retain their own attribution and licenses.

## Features at a glance

| Feature | Behavior |
| --- | --- |
| Clipboard history | Text, rich text, links, images and file references; search, filtering, pins, folders and previews |
| Timeline | Horizontal cards at the bottom of the screen, wheel navigation and copy-time selection |
| Candidate list | Up to ten vertical rows beside the caret; number selection, Tab paging and single-line summaries |
| Text OCR | Apple Vision recognition with automatic or selected supported languages, including Chinese, English and Japanese |
| Table OCR | Markdown tables with surrounding text on macOS 26+ |
| Quick Paste | Converts the **current system clipboard** to plain text; selectable text, image OCR and file-name scopes; off by default |
| Privacy & recovery | No usage analytics; separately clearable local logs; English fallback and verified language-pack repair |

Timeline and Candidate List use the same history. Timeline is suited to browsing and organization; Candidate List is suited to inserting recent items while typing. Caret positioning requires Accessibility and support from the target app. Otherwise the list opens beside the pointer.

<details>
<summary>Candidate list example — synthetic records</summary>

<img src="docs/images/candidate-list.png" width="520" alt="Ten vertical clipboard candidates with single-line tail truncation">

This screenshot contains synthetic data from an isolated review, not a user’s clipboard.

</details>

## Everyday controls

- Open history: **⇧⌘C**.
- Quick Paste: **⇧⌘V**, after enabling it in Settings.
- Candidate selection: **1–9 and 0** for the current page.
- Paging: **Tab / Shift-Tab**; paging stops at either end.

Choose Timeline or Candidate Bar under Settings → Clipboard → Display Style. Candidate selection retains the original item type and follows Copy/Direct Paste settings. Image-to-text conversion belongs to Quick Paste. Global shortcuts can be changed or cleared independently, with conflict checks.

## Build and run

**No official binary release or automatic update channel is currently published.** The maintainer’s 2026-10-29 instruction is documentation only: no distribution packaging or releases until the project is public and the plan is revisited. The future reference is ad-hoc / unnotarized distribution with macOS’s per-app **Open Anyway** flow; it is not an Apple approval or a promise of identical alerts on all Macs. See [the deferred distribution plan](docs/distribution.md). Build from source; a private repository requires GitHub access first.

- Deployment target: macOS 14. Modern text OCR uses macOS 15+; table recognition requires macOS 26+.
- Tools: Swift 6.2+, matching Xcode / Command Line Tools, and Python 3.
- Locally verified on Apple Silicon with macOS 27.0.1. Full behavior on older systems and Intel has not been accepted.

The following commands document a manual local build; they are not being executed for this documentation update.

```sh
git clone https://github.com/Haookun/pastel-it.git
cd pastel-it
swift test --scratch-path /private/tmp/pastel-it-build
PASTEIT_BUILD_PATH=/private/tmp/pastel-it-build \
  ./scripts/package-release.sh --variant arm64 --local-test
```

The App is written to `dist/local-test/arm64/Pastel it！.app`. Local packaging uses ad-hoc signing without a Developer ID or notarization. It does not install or publish anything. The adjacent normal-validation launcher extracts the clean signed archive to a temporary directory before launch.

The **128-test record dated 2026-10-28 used local repair dependency copies**. A complete fresh-clone build using only public dependency manifests is still pending verification; the commands above describe that standard path, not a claim that every environment has passed. See [development notes](docs/development.md).

This derivative keeps the original bundle identifier and data directory. Quit the original app and back up existing data before replacement; do not run both versions side by side.

## Privacy and networking

History and attachments stay in `~/Library/Application Support/PasteIt/`. OCR runs through Apple Vision. There is no usage analytics SDK, and runtime OCR does not call OpenAI or Kimi.

Link previews may contact the destination website or fetch its icon. Language repair contacts GitHub only after an explicit request. Private repositories require browser sign-in and file import; public repositories support direct download. On-device OCR does not mean every feature is network-free. [Privacy details](docs/analytics.md).

## Credits and limits

The original [MIT copyright and license](LICENSE) are retained. Direct dependencies are **Sparkle 2.9.4** and **MCP Swift SDK 0.12.1**; their update/server startup is disabled, but retained code still compiles against them. The locally verified graph also includes Swift System, SwiftLog and EventSource. See [full notices and license texts](THIRD_PARTY_NOTICES.md).

SwiftUI, AppKit, Vision and SwiftData provide the core UI, OCR and storage capabilities. Paste Stack is archived and disabled. The standalone legacy plain-paste command is removed; Quick Paste is the current conversion entry.

OCR quality depends on the system model and image. Sparse mixed-language text and complex tables may need correction. The verification record retains one known Vision limitation; real permissions and cross-app pasting still need user acceptance. [Validation](docs/validation.md).

The tart artwork uses maintainer-supplied references. See [design and asset provenance](docs/design.md), [project origin](docs/origin.md) and [contribution guidelines](CONTRIBUTING.md). Detailed user and engineering documents are primarily in Chinese.
