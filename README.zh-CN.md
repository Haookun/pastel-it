# Pastel it！

<img src="Resources/AppIcon.png" width="144" alt="Pastel it！蛋挞图标">

基于 [Paste It](https://github.com/yipeng-git/paste-it) 的私人 macOS 剪贴板工具。当前重点是历史记录、本地 OCR、表格识别和快捷粘贴。

[English](README.en.md) · [功能说明](docs/features.md) · [原生界面与系统能力](docs/native-ui-and-architecture.md) · [手动确认](docs/manual-validation.md)

## 当前功能

| 功能 | 行为 |
| --- | --- |
| 剪贴板历史 | 文字、富文本、链接、图片和文件引用；搜索、类型筛选、置顶、文件夹及预览 |
| 文字 OCR | Apple Vision 本地识别；自动或指定中、英、日等语言 |
| 表格 OCR | macOS 26+ 使用系统文档识别，输出 Markdown 表格 |
| 时间轴 | 鼠标滚轮横向浏览，悬停查看时间，点击/拖动定位记录 |
| 候选栏 | 可与时间轴切换；纵向每页 10 项、数字选择、Tab 翻页、图片 OCR 摘要与文件名、悬停预览 |
| 快捷粘贴 | 当前系统剪贴板转纯文本；文字、图片 OCR、文件名可多选；默认关闭 |
| 原生界面 | SwiftUI 分组表单、原生菜单和分段控件、SF Symbols；保留必要的浮动面板 |

**默认快捷键：打开剪贴板 `⇧⌘C`，快捷粘贴 `⇧⌘V`。** 可分别修改或清空，冲突时保留原配置并提示。旧版完整默认配置会自动迁移，自定义和明确清空的快捷键保持不变。

在设置 → 剪贴板 → 显示样式中选择时间轴或候选栏，默认时间轴。两者共用 ⇧⌘C 和现有复制／直接粘贴设置。候选栏在文字插入光标旁显示，下方空间不足时翻到上方；无辅助功能权限或应用不提供光标位置时，在鼠标旁显示，位置说明收在信息图标中。候选栏选择后保留原内容类型；图片 OCR 文字用于摘要，转纯文本仍使用快捷粘贴。

独立的旧“粘贴为纯文本”命令、`⌃⌘V`、`⇧Return` 纯文本粘贴及全局默认纯文本选项已移除。历史卡片仍可“复制为纯文本”，只写入选中项，不是另一套全局粘贴命令。

Paste Stack 和 MCP **停用并保留源码**：没有菜单、设置、快捷键或引导入口，启动时不创建队列、不安装队列拦截器，也不启动 MCP 监听器。旧的已启用设置不能恢复它们。MCP Swift SDK 等依赖仍保留以编译归档代码。

## 编译和本机使用

要求 macOS 14+、Swift tools 6.2+。macOS 15+ 使用现代文字 OCR，macOS 14 保留 Vision 兼容路径；表格识别要求 macOS 26+。

```sh
git clone https://github.com/Haookun/pastel-it.git
cd pastel-it
swift test
./scripts/package-release.sh --variant arm64 --local-test
```

本机采用无需账号或证书的 ad-hoc 签名，不做公证或发布。已有 `work/dependencies/` 的本机可显式设置 `PASTEL_USE_LOCAL_DEPENDENCIES=1`，这些依赖副本不进入 Git。固定依赖为 Sparkle 2.9.4、MCP SDK 0.12.1。

代码检查与编译由 agent 负责，实际界面和功能由用户按 [确认清单](docs/manual-validation.md) 验收。测试版可双击 `dist/local-test/arm64/开始合成验证.command`，使用独立合成历史；`开始普通验证.command` 使用真实历史。启动器从干净签名压缩包解压到临时目录，避免文件同步元数据影响签名。

## 数据、设计与来源

保持内部目标 `PasteIt` / `PasteItCore`、bundle ID `app.paste-it.mac` 和数据目录 `~/Library/Application Support/PasteIt/`。本版替代原应用，不能同时独立运行。此前全新安装和项目迁移见 [安装记录](docs/installation.md)，后续功能更新不再清空数据。

蛋挞图标由用户参考图矢量化生成，见 [设计说明](docs/design.md)。上游自动更新已停用；没有配置自己的更新源时不发布。不收集或上传使用信息；仅保留本机诊断日志，可在“设置 → 隐私 → 删除过去日志”清理，配置与剪贴板历史保持不变。见 [日志与隐私说明](docs/analytics.md)。

基于 Yipeng Zhang 及 Paste It contributors 的上游 0.2.9（`904287f6f80e791ea347938582a3550775627927`），保留 [MIT License](LICENSE)。GitHub 仓库为保留上游历史的独立私有派生库，见 [来源](docs/origin.md)。

设置采用标准 macOS 标题栏，分为应用、数据与关于；OCR 和快捷粘贴各有独立栏目。显示样式下的矢量动画演示时间轴与候选列表的差别；候选模式提供辅助功能权限状态与获取权限按钮。候选列表按 1–9、0 选择当前页，Tab 下一页、Shift-Tab 上一页，到首尾停止。

界面语言资源缺失时会回退英文并提示修复；“设置 → 关于 → 语言资源”支持下载或导入校验包。当前私人仓库需在浏览器登录后下载导入，将来公开后可直接下载；不改配置或历史。见 [语言恢复说明](docs/language-recovery.md)。
