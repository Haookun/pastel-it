# Agent notes — Pastel it！ (macOS)

适用于整个仓库。优先遵循用户当前任务要求；以下约定用于避免破坏剪贴板行为、用户数据和 macOS 签名身份。

当前项目目录：`/Users/haoo/Documents/Codex/Pastel it`。旧目录 `Paste It` 已迁移，不在旧路径创建副本或软链接。

剪贴板展示可选择时间轴或候选栏（默认时间轴）；候选栏在文字插入光标旁显示，纵向每页最多10项，Tab下一页、Shift-Tab上一页，首尾停止，数字仅在面板内处理。候选定位只读取辅助功能范围坐标，不读取输入正文；不可用时在鼠标旁回退并提示。翻页沿用原光标矩形，时间轴保持底部位置。

当前仅保留两个全局操作：打开剪贴板默认 ⇧⌘C，快捷粘贴默认 ⇧⌘V。旧独立“粘贴为纯文本”及相关快捷键已移除，历史卡片的“复制为纯文本”仅为复制操作。

## 项目与代码入口

- 原生 macOS 菜单栏剪贴板管理器，使用 SwiftUI、AppKit、SwiftData，通过 Swift Package Manager 构建；不是 Web 项目，也不依赖 Xcode 工程文件。
- Swift tools version 为 **6.2**，最低支持 **macOS 14**。使用较新系统 API 时保留 availability 检查与旧系统回退；玻璃样式统一复用 `Utilities/LiquidGlass.swift`。
- `Package.swift` 定义应用 `PasteIt`、共享库 `PasteItCore`、测试 `PasteItTests`；外部依赖包括 Sparkle、MCP Swift SDK、PostHog。

| 路径（相对于仓库根目录） | 职责 |
| --- | --- |
| `Sources/PasteIt/App/` | 启动、依赖组装（`AppRuntime`）、应用状态、偏好设置和更新 |
| `Sources/PasteIt/Core/` | 剪贴板监听、内容写入、模拟粘贴、全局快捷键 |
| `Sources/PasteIt/Models/`、`Storage/` | SwiftData 模型、历史记录、文件和缩略图存储 |
| `Sources/PasteIt/Search/` | 搜索、OCR、链接元数据 |
| `Sources/PasteIt/UI/` | AppKit 面板控制器、SwiftUI 时间线、卡片与预览 |
| `Sources/PasteIt/Features/PasteStack/` | 粘贴队列及其面板 |
| `Sources/PasteIt/Settings/`、`Onboarding/` | 设置与引导界面 |
| `Sources/PasteIt/AgentAPI/`、`Analytics/` | 本地 MCP 服务、匿名统计 |
| `Sources/PasteItCore/`、`Tests/PasteItTests/` | 可独立测试的类型解析、文本处理、分类、本地化辅助及测试 |
| `Resources/`、`scripts/`、`docs/` | 资源、生成与打包脚本、专题文档 |

表中 `Storage/` 等缩写路径与同一行的完整路径具有相同父目录。

## 修改原则

- 开始先看 `git status --short` 和相关实现，保留已有的用户改动；避免无关重构、全仓格式化和顺带升级依赖。
- 沿用现有分层：共享解析逻辑优先放入 `PasteItCore`；系统交互留在应用目标；不要为了测试把面板或应用单例引入共享库。
- 遵守现有 `@MainActor` 隔离。UI 和 SwiftData 上下文操作留在所属 actor；图片解码、OCR、磁盘读取等耗时工作避免阻塞 UI。不要用新增 `@unchecked Sendable` 或 `nonisolated(unsafe)` 掩盖并发问题。
- 修改交互前先追踪控制器、状态和视图之间的调用链；复用现有面板、选中状态、焦点恢复和快捷键处理路径。
- 新的核心逻辑或缺陷修复，按需在现有 Swift Testing 测试中增加有意义的边界或回归用例（`import Testing`、`@Test`、`#expect`）；纯文档、文案或低风险样式改动不必硬加测试。

## 剪贴板、数据与隐私约束

- 区分“写入系统剪贴板”和“向前台应用自动粘贴”：前者无需 Accessibility，后者需要。保持无权限时的可用路径和提示。
- 应用自己写入剪贴板时，保留 `onPasteboardMutation` → `PasteboardMonitor.suppress(changeCount:)` 链路，避免把自身写入重复采集进历史或 Paste Stack。
- 保留暂停采集、忽略应用和受保护 pasteboard 类型过滤；测试使用合成内容，不使用真实密码或敏感剪贴板内容。
- 持久化目录为 `~/Library/Application Support/PasteIt/`，数据库为 `history.store`，附件在 `Blobs/` 和 `Thumbnails/`。**不要改用 SwiftData 默认的 `Application Support/default.store`**，它可能与其他未沙盒化应用冲突。
- 不要通过删除真实历史、附件、偏好设置或重置系统权限来让测试通过。模型、清理或迁移改动需考虑现有数据兼容性；测试优先使用临时目录和内存存储，复用已有 ephemeral 支持。
- 日志、测试快照和提交内容不得包含真实剪贴板正文、OCR、文件内容或私人路径。统计仅发送允许的元数据，不上传搜索词、剪贴板内容或 MCP payload；新增事件时同步 `AnalyticsCatalog` 与 [统计说明](docs/analytics.md)，并保留退出统计的行为。
- MCP 在当前私人派生版中完全停用，保留源码；启动不创建监听器，也不提供开关或 URL 入口，旧设置不得恢复运行。归档实现仅绑定 `127.0.0.1:17321`，不暴露主时间线、采集或设置的修改能力。截图工具使用临时历史；保持其与真实存储隔离。接口变化同步 [MCP 文档](docs/mcp.md)。
- 不打印或提交 `Secrets/posthog.env`、签名私钥、公证凭据；沿用脚本的凭据注入方式。

## 本地化与资源

- 用户可见文案使用现有 `L10n.tr` 模式与稳定 key，保留英文默认值；格式参数（如 `%@`、`%lld`）在各语言中必须匹配。
- 翻译源在 `scripts/generate-localizations.py`、`scripts/localization_batch2.py`、`scripts/localization_batch_cjk.py`。修改对应源表后，从仓库根目录运行：

  ```sh
  python3 scripts/generate-localizations.py
  ```

- 一并检查并提交生成的 `Resources/Localization/Localizable.xcstrings` 和 `Resources/*.lproj/Localizable.strings`；不要只修改会被生成脚本覆盖的输出。检查 diff，避免夹带无关翻译重写。
- 新增语言时同步 `Info.plist` 的 `CFBundleLocalizations`；新增或更新文案时检查长文本和中日韩字符的截断、换行。
- 用户可见功能或快捷键发生变化时，同步受影响的 README 语言版本和专题文档。

## 按改动范围验证

所有命令默认在仓库根目录执行。

| 改动 | 验证要求 |
| --- | --- |
| 仅文档 | 核对路径、命令与现有实现，运行 `git diff --check`；无需构建或安装 |
| Swift 核心逻辑 | `swift test`，并用 `swift build` 验证应用目标集成 |
| UI、面板、手势、选择、快捷键、粘贴、Accessibility | agent 做代码检查、相关自动测试和 App 编译；真实功能验收交给用户，提供编号清单并记录反馈 |
| 本地化、资源 | agent 核对生成 diff、占位符和资源打包；实际显示由用户按清单确认 |
| Shell 脚本 | `bash -n scripts/<changed-script>.sh`，再执行与任务相关的安全验证；不能把语法通过当作签名或发布成功 |

共享逻辑测试依赖 `PasteItCore`，应用集成测试还依赖 `PasteIt`；`swift test` 不能代替真实的系统权限和跨应用粘贴验证。`swift run PasteIt` / `./scripts/run-app.sh` 供临时调试；完整本机应用使用下述流程。

## 验证分工：agent 验证代码，用户确认功能

- **agent 负责**相关代码检查、单元/集成测试、编译、组装 `.app`、资源完整性及签名校验；自动测试使用合成数据和临时存储。
- **用户负责**启动应用后的实际功能、UI、滚轮/手势、快捷键、粘贴、焦点、权限、图标与持久化体验确认。除非用户后续明确要求 agent 代测，不主动进行桌面自动操作、功能点击、截屏验收或跨应用粘贴。
- 每次功能变更后更新 [手动确认清单](docs/manual-validation.md)，按本次范围提供稳定编号、操作步骤、预期结果和当前状态。默认状态为“待用户确认”，不能用代码测试通过代替用户确认。
- 用户依次反馈“编号 + 通过/有问题/未测”；只更新其明确确认的项目。问题要记录现象和期望，修复后标为“待复测”，由用户再次确认。不要自行勾选、推定未反馈项通过，或要求一次完成整份清单。
- 交付时区分“代码验证通过”“App 已编译/签名”“用户功能已确认”。只要还有未确认项，就明确列出待确认范围。

**本项目默认无 Apple Developer 账号、无 Developer ID 证书。** 本机开发和个人使用采用 ad-hoc 临时签名（`codesign --sign -`），不需要证书或公证；不要为缺少 Developer ID 阻塞本机验证，也不必重复征求临时签名许可。Developer ID 和公证仅是以后对外分发时的可选流程。无需创建或信任自签名根证书。

agent 在仓库内生成并校验本机 arm64 应用：

```sh
./scripts/package-release.sh --variant arm64 --local-test
codesign --verify --deep --strict --verbose=2 "dist/local-test/arm64/Pastel it！.app"
codesign -dv "dist/local-test/arm64/Pastel it！.app"
```

用户双击 `dist/local-test/arm64/开始合成验证.command` 手动启动隔离验证：使用临时内存历史、合成记录和独立偏好，不改真实历史或开机启动项，退出后清理测试附件和偏好。它仍会响应系统剪贴板变化；只复制合成内容，日志和截图不得记录真实内容。`开始普通验证.command` 使用原有真实历史；不要把隔离模式下的重启清空误判为持久化问题。启动器先把干净签名压缩包解压到系统临时目录并校验，再启动，避免同步目录的 Finder 元数据影响签名；不安装应用。

只编译组装时可用 `--build-only`，输出到 `dist/build-only/`，但未签名产物不能作为启动和交互已通过的证据。Apple Silicon 本机运行优先使用 ad-hoc 签名。

用户未明确要求安装时，交付产物留在项目目录，可由手动启动器在系统临时目录解压运行，**不替换 `/Applications` 下的现有应用**。用户明确要求安装时，可安装已校验的本机临时签名版本；先备份现有应用，保持 bundle ID，不在打包失败时删除原安装。签名身份或路径变化可能影响辅助功能授权，需提示用户检查，不擅自重置权限。

不关闭系统 Gatekeeper、SIP 或 AMFI，不添加宽泛信任规则。若下载的未公证应用被拦截，按 Apple 的单个应用允许打开流程处理，不全局降低系统保护。若系统权限或环境阻止验证，完成其他检查，明确未验证行为，不把 ad-hoc 签名说成 Developer ID 签名或公证通过。

以下场景供编写用户手动清单时按需选取，**不是要求 agent 执行桌面验证**：

- 采集与粘贴：复制合成文本、富文本、图片或文件，检查类型与去重；Return 粘贴到目标应用、⇧⌘V 快捷粘贴，并确认焦点恢复及没有再次采集自身写入。
- 时间线与预览：⇧⌘C 打开/关闭、搜索与过滤、键盘选择、⌘-click 多选、Space 预览、⌘E 编辑；检查面板关闭和焦点切换。
- Paste Stack 与 MCP 已归档停用；不要重新接入运行时、快捷键、菜单、设置、教程或剪贴板监听。保留源码不代表允许恢复入口。
- 存储与设置：相关设置生效，重启后历史、置顶和文件夹保持正确；权限相关改动验证对应授权状态，不擅自重置已有授权。
- 视觉改动：由用户检查相关浅色/深色界面、长文案和窗口位置。仅在用户另行要求时才使用桌面工具做截图与交互检查，不为此恢复已停用的 MCP。

本机临时签名与可选的对外分发流程见 [mac-packaging.md](docs/mac-packaging.md)。

## 打包、发布与交付

- 日常本地验证使用 `package-release.sh --variant arm64 --local-test`；不需要 Developer ID、提升版本、生成 appcast 或发布。`--build-only` 仅用于不启动的组装检查。
- 发布按 [mac-updates.md](docs/mac-updates.md) 和 `scripts/release.sh` 执行；版本由脚本管理，保持 `CFBundleVersion` 单调递增，不手工拼装更新签名。
- **`release.sh` 是有副作用的发布流程，不是构建检查命令。** 默认会改版本、签名、公证、创建 GitHub Release、更新 `docs/appcast.xml`、提交、打 tag 和 push，仅在任务已授权发布时使用。
- `--dry-run` 仍会修改 `Info.plist`、打包/公证和更新本地 appcast；`--no-push` 仍会创建 GitHub Release、提交和 tag。不要把这些选项当成只读或仅本地构建的保证。
- 保持现有 bundle ID；本机默认 ad-hoc，未来具备证书时才使用 Developer ID 发布流程。`PasteIt.entitlements` 不添加 XML 注释。签名、Sparkle 嵌套组件和资源拷贝沿用打包脚本，不用临时命令替代发布实现。
- 不提交 `.build/`、`dist/`、`updates/` 下的发布二进制、`.tools/` 或本地凭据；生成的本地化资源是需要提交的项目资源。
- 结束前检查 `git diff --check`、`git diff --stat` 和 `git status --short`，确认没有无关修改。交付时简要说明代码检查结果、本机签名类型、App 路径和待用户确认的功能；用户反馈前不声称实际功能验收通过。

## 显式原生 UI 复验

用户本轮明确授权代做界面确认时，可从干净临时签名包启动 `--validation-session --ui-review /absolute/temporary-output`。该开发检查模式只创建临时合成历史和独立偏好；启动分支不注册全局快捷键、不监听系统剪贴板、不启动统计或登录项同步。候选选择测试使用 uniquely named pasteboard，不使用系统剪贴板。

该模式在真实 App 窗口内走原生控件操作并输出本应用的 AppKit 渲染图；不能将其等同于跨应用粘贴或全局快捷键验收。`candidate-page1-light` 与 `candidate-page2-light` 阶段最多等待20秒，输出目录中同名 `.continue` 文件可继续。它只在显式命令行参数下启用，不作为产品入口或后台服务。

同步目录的 Finder/FileProvider 元数据可能破坏 SwiftPM 测试包签名。测试使用非同步临时构建目录，例如 `swift test --scratch-path /private/tmp/pastel-it-build`；打包可设置 `PASTEIT_BUILD_PATH`。不要为绕过测试而清理真实历史、权限或全局同步配置。

只复查显示样式动画时，可在上述显式 `--ui-review` 合成流程中追加 `--ui-review-preview-only`，仅输出两种动画在窄／标准／宽设置窗口及深色外观中的截图；不进入剪贴板选择与鼠标交互检查。动画使用固定480×300画布和统一比例缩放，不按宽高分别重排图形。

候选摘要回归可在显式合成 `--ui-review` 流程追加 `--ui-review-summary-only`，仅检查10行合成多行文本／OCR与长首行在420pt、280pt及深色外观中的单行边界；不得用真实历史截图复现。摘要只改变展示，不截断存储与复制内容。
