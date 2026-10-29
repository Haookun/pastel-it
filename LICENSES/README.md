# License text snapshots

The original project copyright and MIT terms remain in [../LICENSE](../LICENSE). These files preserve the notices for the direct dependencies and the transitive libraries in the locally verified build. They do not replace any dependency’s applicable license.

Sparkle and MCP snapshots were fetched from their pinned upstream tags on 2026-10-28. EventSource, SwiftLog and SwiftSystem snapshots are copied verbatim from the local dependency trees used for verification; they are not a claim that all fresh clones resolve identical transitive versions.

| File | Upstream source | SHA-256 |
| --- | --- | --- |
| [Sparkle-2.9.4.txt](Sparkle-2.9.4.txt) | [Source](https://github.com/sparkle-project/Sparkle/blob/2.9.4/LICENSE) | `816be66341dd11b22806862dffd8392b240babaced1cdf24da2ff413ef00c3fd` |
| [MCP-Swift-SDK-0.12.1.txt](MCP-Swift-SDK-0.12.1.txt) | [Source](https://github.com/modelcontextprotocol/swift-sdk/blob/0.12.1/LICENSE) | `0382b0057770ca05e9c350a50aa3b1c1fea84da0bc81d723bf00b9aa841be58a` |
| [EventSource.txt](EventSource.txt) | [Source](https://github.com/mattt/EventSource/blob/main/LICENSE.md) | `2f9b695627d569a3ce452b2c03fdd34310df78c8ea94edfafd9ce38381e5b502` |
| [SwiftLog.txt](SwiftLog.txt) | [Source](https://github.com/apple/swift-log/blob/main/LICENSE.txt) | `cfc7749b96f63bd31c3c42b5c471bf756814053e847c10f3eb003417bc523d30` |
| [SwiftLog-NOTICE.txt](SwiftLog-NOTICE.txt) | [Source](https://github.com/apple/swift-log/blob/main/NOTICE.txt) | `879b241d49b407215a0ad8e1c6a71c358d7b29591b090cf379d37a5f50cff918` |
| [SwiftSystem.txt](SwiftSystem.txt) | [Source](https://github.com/apple/swift-system/blob/main/LICENSE.txt) | `2245a990b635558be210fb3eb4f8a6f7a49aebc0fefbf5859146a65ddc7ddcf3` |

The local dependency graph contains Sparkle, MCP, Swift System, SwiftLog and EventSource. A fresh clone uses the public manifests in Package.swift; its resolver may also fetch build/documentation dependencies declared upstream. See [the third-party notices](../THIRD_PARTY_NOTICES.md).

The Sparkle snapshot normalizes trailing spaces only; its copyright and license wording are unchanged. Hashes describe the files stored here. Other verbatim snapshot descriptions above are unchanged.
