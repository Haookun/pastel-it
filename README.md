# Pastel it！

<img src="Resources/AppIcon.png" width="144" alt="Pastel it！奶油蛋挞图标">

一个原生 macOS 菜单栏剪贴板工具：保存文字与图片，用多语言 OCR 找回截图里的信息，通过横向卡片和复制时间轴查看历史，把当前剪贴板快速转换为纯文本。

**状态：私人开发版本。** 本仓库为 [Paste It](https://github.com/yipeng-git/paste-it) 的 MIT 派生项目，保留原作者署名和上游历史；应用显示名为 **Pastel it！**。尚未发布安装包，也没有启用原项目的自动更新。源码已验证与安装后真实操作验收的范围见 [验证记录](docs/validation.md)。

[功能说明](docs/features.md) · [图标与交互设计](docs/design.md) · [来源与兼容性](docs/origin.md) · [English](README.en.md) · [日本語](README.ja.md) · [한국어](README.ko.md)

## 功能

| 功能 | 行为 |
| --- | --- |
| 剪贴板历史 | 保存文字、富文本、链接、图片及文件引用，支持搜索、固定、文件夹和忽略应用/类型 |
| 图片 OCR | 自动识别常见语言，也可指定中文、英文、日文等语言；设置精确/快速模式、语言纠错、最小文字高度 |
| 表格 OCR | macOS 26+ 检测表格后输出 Markdown，保留表格前后文字；检测失败回退文字 OCR |
| 横向浏览 | 卡片区域内纵向鼠标滚轮转为横向浏览，保留横向手势与内部纵向滚动区域 |
| 复制时间轴 | 底部时间刻度悬停放大，点击/拖动跳到当前筛选结果中最接近时间的记录 |
| 快捷粘贴 | 可勾选文字去格式、图片转 OCR、文件转文件名；读取当前系统剪贴板 |
| 粘贴队列 | Paste Stack 支持顺序粘贴，保留原有的 FIFO/LIFO 操作 |
| 本地 MCP | 默认关闭，仅绑定 `127.0.0.1:17321`；接口说明见 [MCP 文档](docs/mcp.md) |

**快捷键：** 打开历史默认 `⇧⌘V`，粘贴队列默认 `⇧⌘C`，原有纯文本粘贴默认 `⌃⌘V`。三个组合可在“通用”中录入、清空和恢复默认。新增“快捷粘贴”默认关闭，首次开启尝试 `⇧⌘V`；它与打开历史独立设置，冲突时会提示，**不会覆盖现有快捷键**。可在“通用”修改打开历史的组合，或在“OCR 与快捷粘贴”给快捷粘贴录入另一个组合。

OCR 关闭后保留已有文字；旧图片需点击 **Re-run** 才应用新参数。表格首行作为 Markdown 表头，合并单元格仅保留左上角内容。时间轴使用记录的**首次复制时间**，不新增逐次重复复制的时间日志。细节见 [功能说明](docs/features.md)。

## 系统与构建

- macOS 14+，Swift tools 6.2+；现代 Vision OCR 使用 macOS 15+ API，结构化表格识别需要 macOS 26+。
- 原生 SwiftUI、AppKit、SwiftData；通过 Swift Package Manager 构建。
- 当前依赖固定为 Sparkle 2.9.4、MCP Swift SDK 0.12.1、PostHog 3.59.3。没有新增 OCR 云服务。

```sh
git clone https://github.com/Haookun/pastel-it.git
cd pastel-it
swift build
swift test
```

以上生成编译产物，不会安装到应用程序目录。需要临时调试应用窗口时，可运行 `./scripts/run-app.sh`；调试构建不能代替正式签名安装验收。

若本机已有 `work/dependencies/` 下的离线修复依赖，可显式选择它们；这些本机依赖不进入仓库：

```sh
PASTEL_USE_LOCAL_DEPENDENCIES=1 swift build
PASTEL_USE_LOCAL_DEPENDENCIES=1 swift test
```

正式打包沿用 `scripts/package-release.sh`，需要自己的 Developer ID 证书；没有配置私人更新源前不发布。`scripts/release.sh` 有创建 Release、改版本和推送的副作用，不能用作普通构建检查。参见 [macOS 打包](docs/mac-packaging.md) 和 [更新策略](docs/mac-updates.md)。

## 设计与数据

应用图标来自用户提供的奶油蛋挞参考图，经去背景、降噪和路径矢量化后生成正式 `AppIcon.icns` 与 `Assets.car`。菜单栏图标来自极简蛋挞参考图，使用系统模板着色适配明暗菜单栏。SVG 源稿与生成方式在 [设计说明](docs/design.md)。

为保留已有历史和偏好，本版继续使用内部目标 `PasteIt` / `PasteItCore`、bundle ID `app.paste-it.mac` 及 `~/Library/Application Support/PasteIt/`。这是对现有安装的替代版本，**不支持与原应用同时独立运行**。本次未安装或迁移真实数据。

统计接口沿用上游设计，可在“隐私”关闭；本仓库的 `PostHogProjectToken` 为空，没有 token 的构建不发送统计。详见 [统计说明](docs/analytics.md)。

## 来源与许可证

基于 Yipeng Zhang 及 Paste It contributors 的 [Paste It](https://github.com/yipeng-git/paste-it)，上游基线为 `904287f6f80e791ea347938582a3550775627927`（0.2.9）。保留原 [MIT License](LICENSE)。本派生版新增功能、设计和验证边界单独记录，未宣称已发布或完成安装验收。
