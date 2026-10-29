# 开发指南与 AI 协作

> 当前维护范围（2026-10-29）：只更新文档，不编译、不安装、不制作对外分发包、不创建 Release；项目公开后再讨论分发。以下构建命令仅为开发参考。[分发约定](distribution.md)

## 项目身份和分工

Pastel it！是在 Paste It 上继续开发的派生项目。**主要新增代码、修改与整合由 OpenAI Codex 编写**；维护者提出需求、决定产品行为并进行手动验收。Kimi Code CLI 参与部分原生界面、控件、布局与交互工作，Codex负责上下文、整合和检查。这一说明不把上游或第三方代码归为 AI 原创。

Codex／Kimi 是开发工具，不是运行时依赖；App 的 OCR 使用系统 Vision，不调用它们处理用户剪贴板。完整来源与许可见 [第三方致谢](../THIRD_PARTY_NOTICES.md) 和 [项目来源](origin.md)。

## 技术栈

| 层 | 实现 |
| --- | --- |
| 窗口与界面 | SwiftUI、AppKit、SF Symbols；自定义时间轴与原生候选表格 |
| 剪贴板与快捷键 | NSPasteboard、Carbon、NSEvent、Core Graphics、Accessibility |
| 识别 | Vision 文字 OCR；macOS 26+ 文档表格识别 |
| 数据 | SwiftData / SQLite，Foundation 文件与附件存储 |
| 完整性 | CryptoKit SHA-256；版本绑定的纯 JSON 语言包 |
| 构建 | Swift Package Manager、Python 生成脚本、macOS 签名与打包工具 |

直接依赖固定为 Sparkle 2.9.4 与 MCP Swift SDK 0.12.1。自动更新及 MCP 运行入口均停用；Paste Stack 保留归档代码但不能运行。间接依赖与许可见 [THIRD_PARTY_NOTICES.md](../THIRD_PARTY_NOTICES.md)。

## 两种依赖模式

### 公共依赖：新克隆的默认路径

[Package.swift](../Package.swift) 默认从公开仓库解析固定的直接依赖。间接版本由 SwiftPM 解析，`Package.resolved` 未提交，因此不承诺所有克隆拥有相同依赖图。

```sh
swift package resolve
swift package show-dependencies
swift test --scratch-path /private/tmp/pastel-it-build
PASTEIT_BUILD_PATH=/private/tmp/pastel-it-build \
  ./scripts/package-release.sh --variant arm64 --local-test
```

截至 2026-10-28，尚未完成一次仅依赖公开来源、全新克隆环境的完整构建验收。请不要把本机修复构建的结果写成这条路径已经通过，也不要假定读者已有隐藏的 `work/` 目录。

### 本机修复副本：现有验证记录使用的路径

维护机器的 `work/dependencies/` 保存过本地修复依赖副本。目录被 Git 忽略，不随克隆提供；仅持有这些副本时才可选择：

```sh
PASTEL_USE_LOCAL_DEPENDENCIES=1 \
  swift test --scratch-path /private/tmp/pastel-it-build
PASTEL_USE_LOCAL_DEPENDENCIES=1 \
  PASTEIT_BUILD_PATH=/private/tmp/pastel-it-build \
  ./scripts/package-release.sh --variant arm64 --local-test
```

这不是公开用户的安装捷径，也不是完整依赖锁文件。当前本机图为 Sparkle、MCP、Swift System、SwiftLog、EventSource；旧缓存目录里出现 PostHog 或其他包不表示它们仍在当前图中。

## 生成翻译与恢复包

```sh
python3 scripts/generate-localizations.py
python3 scripts/generate-language-pack.py --check
```

翻译源表在 `scripts/generate-localizations.py` 和两个 `localization_batch*` 文件中。生成结果包括 `.lproj`、xcstrings、`Resources/LanguagePacks/<SHA256>.json` 和 `LanguagePackManifest.swift`，修改时一并提交。已发布旧语言包保留，避免旧 App 的恢复地址失效。

打包前校验生成清单，签名前逐语言检查真实 App 内的资源。不调用 SwiftPM 的 fatal `Bundle.module` 访问路径；缺包尝试匹配缓存，再用内置英文并提示恢复。[机制说明](language-recovery.md)。

## 验证边界

2026-10-28 的最近代码记录：Apple Silicon、macOS 27.0.1，65 项共享逻辑＋63 项集成测试，共128项通过；保留1项既有稀疏中文 Vision known issue。App 构建为 arm64、本机 ad-hoc 签名，资源完整和缺包副本均做过合成原生检查。

| 已有证据 | 仍不能据此宣称 |
| --- | --- |
| 本机修复依赖的测试和打包 | 公共依赖新克隆构建已通过 |
| 当前 arm64 系统的原生合成检查 | macOS 14/15、Intel 或所有第三方应用均已验收 |
| 临时历史、合成图片和隔离资源缓存 | 用户真实权限、浏览器登录和真实跨应用粘贴已全部通过 |
| 本机 ad-hoc 签名有效 | 已通过 Developer ID 签名或 Apple 公证 |

本次文档更新不改 App 行为，不因改写文档而重跑或扩大上述验收结论。证据与待确认项分别见 [validation.md](validation.md) 和 [manual-validation.md](manual-validation.md)。

## 发布与贡献

普通本机构建用 `package-release.sh --variant arm64 --local-test`，不安装、不发 Release。`scripts/release.sh` 会修改版本、打包、更新发布源、提交与推送，只应在明确准备发版时执行；它不是测试命令。当前没有正式二进制或自动更新渠道。

修改前阅读 [AGENTS.md](../AGENTS.md) 和 [贡献指南](../CONTRIBUTING.md)。保持现有数据身份与隐私边界，真实数据不能成为测试夹具；不要恢复已归档功能或加入使用统计。
