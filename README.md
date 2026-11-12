# Pastel it！

<img src="Resources/AppIcon.png" width="128" alt="Pastel it！蛋挞图标">

**原生 macOS 剪贴板与本地 OCR 工具：按时间浏览，也可以在输入光标旁挑选最近复制的内容。**

[English](README.en.md) · [使用指南](docs/getting-started.md) · [文档导航](docs/README.md) · [开发与 AI 协作](docs/development.md) · [来源及依赖致谢](THIRD_PARTY_NOTICES.md)

> 基于 [Yipeng Zhang 及贡献者的 Paste It](https://github.com/yipeng-git/paste-it)。本派生版本的主要新增代码、修改和整合由 **OpenAI Codex** 完成，维护者负责需求与验收；**Kimi Code** 参与部分界面设计与实现。上游代码及第三方组件分别保留原作者署名和许可证。

## 能做什么

| 功能 | 使用方式 |
| --- | --- |
| 剪贴板历史 | 文字、富文本、链接、图片和文件引用；搜索、筛选、置顶、文件夹与预览 |
| 候选列表 | 输入光标附近显示，纵向每页 10 项；数字选取、Tab 翻页，长内容首行省略 |
| 时间轴 | 屏幕底部横向卡片；鼠标滚轮浏览，沿复制时间定位 |
| 本地文字 OCR | Apple Vision 自动识别中、英、日等系统支持的语言，也可手动选择 |
| 表格 OCR | macOS 26+ 将识别出的表格整理为 Markdown，保留周围文字 |
| 快捷粘贴 | 将**当前系统剪贴板**转为纯文本；可选文字、图片 OCR、文件名，默认关闭 |
| 隐私与日志 | 不收集或上传使用统计；本机日志可单独删除，保留配置和历史 |
| 语言资源恢复 | 缺包时继续以英文运行并提示修复；支持校验后下载或导入语言包 |

两种展示共用同一份历史：**时间轴适合回看和整理，候选列表适合输入时快速取用。** 候选定位需要辅助功能权限与目标应用支持；取不到光标位置时，在鼠标附近显示。

<details>
<summary>查看候选列表示例（合成数据）</summary>

<img src="docs/images/candidate-list.png" width="520" alt="纵向十项候选列表，长文本只显示首行并在末尾省略">

截图来自隔离验证，使用合成文字，不包含用户的真实剪贴板。

</details>

## 开始使用

| 操作 | 默认快捷键 |
| --- | --- |
| 打开剪贴板 | `⇧⌘C` |
| 快捷粘贴 | `⇧⌘V`，需先在设置中开启 |
| 候选列表选取 | 当前页 `1`–`9`、`0` |
| 候选列表翻页 | `Tab` 下一页，`Shift-Tab` 上一页；首尾停止 |

在“设置 → 剪贴板 → 显示样式”选择时间轴或候选栏，默认候选栏。选取条目沿用复制／直接粘贴设置；单击图片仍按图片取用；右键条目可选择“粘贴”“快捷粘贴纯文本”“复制纯文本”，图片纯文本操作会在点击时识别原图（无识别文字或原图不可用时提示失败）。两组全局快捷键可分别修改、清空，并检查冲突。[使用指南](docs/getting-started.md)

## 相比原项目 Paste It 增加了什么

在原版剪贴板历史、搜索和卡片管理基础上，本派生版着重改善输入时的取用与图片转文字：

- **光标旁候选栏（默认）**：纵向10项，数字选取、Tab翻页，长内容单行省略，图片／文件悬停预览。
- **复制时间轴**：横向滚轮浏览，按复制时间定位；可随时切回候选栏。
- **表格 OCR 与快捷粘贴**：本机 Vision 将图片转为文字或 Markdown 表格；当前剪贴板的文字、图片、文件名可按范围转成纯文本。
- **资源与隐私修复**：语言资源缺失不再导致启动崩溃；校验后恢复语言包；移除使用统计，仅保留可清理的本机诊断日志。
- **精简原生设置**：独立快捷键、权限入口与显示样式预览；归档停用 Paste Stack、MCP 和自动更新。

<img src="docs/images/features-overview.svg" width="900" alt="候选栏与时间轴功能示意，两种展示共用历史">

<img src="docs/images/ocr-workflow.svg" width="900" alt="图片经本机 Vision 转为文字或 Markdown 表格的流程示意">

以上为功能示意，非真实剪贴板截图；原版能力与新增能力的来源见 [项目来源](docs/origin.md)。

## 下载安装

从 [GitHub Releases](https://github.com/Haookun/pastel-it/releases/latest) 下载 **v0.3.0 Apple Silicon（arm64）DMG**，打开后将 App 拖入 Applications。首版不提供 Intel 安装包；自动更新停用，后续版本手动下载。

使用 ad-hoc 临时签名，**没有 Developer ID 签名或 Apple 公证**。下载后如被 Gatekeeper 拦截，确认来源可信后，按“系统设置 → 隐私与安全性 → 仍要打开”允许单个应用。不要关闭系统安全保护。[分发与安装说明](docs/distribution.md)

v0.3.0 起为独立应用：标识 `io.github.haookun.pastel-it`，历史存放在 `~/Library/Application Support/PastelIt/`，不会自动读取或迁移原版及旧私人版本的数据，也不会删除它们。辅助功能权限需要为新版单独授权。

## 从源码构建

- 最低部署目标 macOS 14；现代文字 OCR 为 macOS 15+，表格识别 macOS 26+。
- Swift 6.4+、相应 Xcode／Command Line Tools、Python 3；Apple Silicon 为首版验证平台。
- 老系统和 Intel 的完整体验未验收；本机测试不能代替所有第三方应用的权限／粘贴测试。

```sh
git clone https://github.com/Haookun/pastel-it.git
cd pastel-it
swift test --scratch-path /private/tmp/pastel-it-build
PASTEIT_BUILD_PATH=/private/tmp/pastel-it-build \
  ./scripts/package-release.sh --variant arm64 --local-test
# 制作无公证、临时签名 DMG（不自动上传）
PASTEIT_BUILD_PATH=/private/tmp/pastel-it-build \
  ./scripts/package-release.sh --variant arm64 --adhoc-release
```

本机测试 App 在 `dist/local-test/arm64/`，DMG 在 `dist/`；不自动安装。[开发指南](docs/development.md)

## 数据与联网

历史及附件保存在本机 `~/Library/Application Support/PastelIt/`，OCR 由系统 Vision 在设备上执行。没有使用统计 SDK，也不通过 OpenAI／Kimi 服务识别剪贴板。

链接预览可能请求对应网站或图标；点击修复语言资源时会访问 GitHub。私有仓库需浏览器登录下载后导入，公开仓库可直接下载。本地 OCR 和无使用统计不代表整个应用从不联网。[隐私与日志](docs/analytics.md)

## 来源、依赖与边界

- 上游：[Paste It](https://github.com/yipeng-git/paste-it)，基线 0.2.9；保留 [MIT 许可证及版权](LICENSE)。
- 直接依赖：**Sparkle 2.9.4**、**MCP Swift SDK 0.12.1**。当前自动更新和 MCP 服务均停用，依赖仍用于编译保留代码。
- 本机依赖树还包含 **Swift System、SwiftLog、EventSource**；完整署名与许可文本见 [第三方致谢](THIRD_PARTY_NOTICES.md)。
- OCR、界面和存储主要使用 **Vision、SwiftUI、AppKit、SwiftData** 等 macOS 能力；Codex／Kimi 是开发工具，不是 App 的运行时依赖。
- Paste Stack 已归档停用，旧的独立“粘贴为纯文本”命令已移除；快捷粘贴是现行纯文本转换入口。

OCR 受系统模型和图片质量影响；稀疏中英混排、复杂表格可能需要校正。截至 2026-10-28 的 128 项测试保留了 1 项既有 Vision 已知限制，真实权限与跨应用粘贴仍需用户确认。[功能细节](docs/features.md) · [验证记录](docs/validation.md)

## 参与与设计

欢迎提出可复现的问题和建议。[贡献指南](CONTRIBUTING.md)说明反馈和验证方式；截图及测试请使用合成内容。

蛋挞图标来自维护者提供的参考图，经矢量化后用于应用；设置优先采用系统控件，保留时间轴、候选面板等必要自绘。[设计与素材](docs/design.md) · [项目来源](docs/origin.md)
