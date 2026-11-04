# Upstream, AI tooling and third-party notices

## Original project

Pastel it！ is derived from [Paste It](https://github.com/yipeng-git/paste-it), by **Yipeng Zhang and Paste It contributors**. The imported upstream baseline is [`904287f6f80e791ea347938582a3550775627927`](https://github.com/yipeng-git/paste-it/tree/904287f6f80e791ea347938582a3550775627927), version 0.2.9. The original MIT copyright and license remain verbatim in [LICENSE](LICENSE).

This repository contains inherited upstream code and subsequent derivative work. “Written with Codex” describes development of the derivative; it does not attribute the upstream project or third-party libraries to an AI tool.

## AI-assisted development

| Contributor / tool | Role |
| --- | --- |
| Maintainer, [Haookun](https://github.com/Haookun) | Requirements, product choices, supplied artwork references, manual acceptance and repository ownership |
| OpenAI Codex | Primary authoring of added/modified code, integration, fixes, automated checks, packaging and documentation |
| Kimi Code CLI | Selected interface design, native controls, layout and interaction implementation; integrated and reviewed through Codex |

These tools are used during development, not as App runtime SDKs. Runtime OCR does not send images to OpenAI or Kimi. AI assistance does not replace attribution, third-party terms or the [validation limits](docs/development.md).

## Direct Swift package dependencies

Declarations are in [Package.swift](Package.swift).

| Project | Declared version | Role and current status | License text |
| --- | --- | --- | --- |
| [Sparkle](https://github.com/sparkle-project/Sparkle) | 2.9.4 | macOS update framework. Update startup is disabled; packaging still embeds the framework. | [Snapshot](LICENSES/Sparkle-2.9.4.txt) / [upstream](https://github.com/sparkle-project/Sparkle/blob/2.9.4/LICENSE). MIT-style main terms plus additional bundled-component notices; preserve the full text. |
| [MCP Swift SDK](https://github.com/modelcontextprotocol/swift-sdk) | 0.12.1 | Compiles retained MCP source. No running MCP server, listener or product entry. | [Snapshot](LICENSES/MCP-Swift-SDK-0.12.1.txt) / [upstream](https://github.com/modelcontextprotocol/swift-sdk/blob/0.12.1/LICENSE). Apache-2.0 terms and an MIT-to-Apache transition notice; do not label the entire SDK simply MIT. |

## Transitive libraries in the locally verified build

| Project / authors | Role | License / notice |
| --- | --- | --- |
| [Swift System](https://github.com/apple/swift-system) / contributors | System abstractions through MCP | [Apache-2.0 with Runtime Library Exception](LICENSES/SwiftSystem.txt) |
| [SwiftLog](https://github.com/apple/swift-log) / contributors | Logging abstraction through MCP; not usage analytics | [Apache-2.0](LICENSES/SwiftLog.txt) and [NOTICE](LICENSES/SwiftLog-NOTICE.txt) |
| [EventSource](https://github.com/mattt/EventSource) / Mattt and contributors | Event-stream transport support in the retained dependency graph | [MIT terms](LICENSES/EventSource.txt) |

This table describes the local verification graph, not every resolver result. Local repair copies are ignored by Git. Fresh clones use public manifests; the MCP upstream manifest additionally declares SwiftNIO and a DocC plugin for its wider build/documentation targets. For v0.3.0, the public dependency graph is pinned by the committed `Package.resolved`; the local-repair table is retained as historical context. Inspect the selected graph with `swift package show-dependencies`. [Snapshot provenance and hashes](LICENSES/README.md).

PostHog has been removed from dependency declarations and event collection. Old cached checkouts do not imply that a library is linked or running.

## Apple platform capabilities

SwiftUI, AppKit, Vision, SwiftData, Foundation, CryptoKit, Core Graphics, Accessibility, Carbon hotkey registration and ServiceManagement are Apple platform APIs. They provide native UI, OCR, storage, hashing, clipboard integration, caret geometry, shortcuts and login-item support. They are distinct from the third-party packages above. [Implementation map](docs/native-ui-and-architecture.md).

## References and build-only tools

- [Rime / Squirrel](https://github.com/rime/squirrel) informed candidate interaction and positioning. It is not a linked package. The clipboard-specific approach and reference links are in [the architecture notes](docs/native-ui-and-architecture.md).
- Optional disk-image tooling: [dmgbuild](https://github.com/dmgbuild/dmgbuild), ds-store and mac-alias; pins in [scripts/dmg-layout-requirements.txt](scripts/dmg-layout-requirements.txt).
- Optional artwork tooling: [Pillow](https://github.com/python-pillow/Pillow) and [vtracer](https://github.com/visioncortex/vtracer); pins in [scripts/artwork-requirements.txt](scripts/artwork-requirements.txt).
- These optional tools are not App runtime dependencies; their own terms apply. Current ad-hoc distribution is described in the [distribution guide](docs/distribution.md).

## Artwork and documentation images

The maintainer supplied the tart reference images. Vector sources and generated icon assets are listed in [the design notes](docs/design.md). On 2026-11-04 the maintainer confirmed the right to use, adapt and distribute these supplied references with the public project and application.

Documentation screenshots use synthetic records and isolated settings, not user clipboard contents. Source-image provenance is listed in the design notes.

## v0.3.0 public dependency graph

The public build also resolves SwiftNIO, Swift Atomics and Swift Collections (Apache-2.0 terms and their included exceptions/notices). Full public-build snapshots are in [LICENSES](LICENSES/README.md); selected revisions are pinned in [Package.resolved](Package.resolved). The old local-repair graph above is historical. All license files are included in the application Resources/Legal directory.
