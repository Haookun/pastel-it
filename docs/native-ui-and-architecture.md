# 原生界面和 macOS 系统能力

## 原生样式能否同时兼顾美观和工作量

本项目适合优先采用系统组件：设置、菜单、选择器、按钮、侧栏和系统颜色已有成套的尺寸、焦点、禁用状态、键盘导航及辅助功能行为，减少重复绘制和兼容代码。使用系统组件不等于自动完成所有设计，仍需安排信息层级、留白和长文案，并由用户检查明暗外观、最小窗口和交互。

Apple 建议采用系统的 grouped Form；Liquid Glass 用作控件和导航层，内容层保持清楚。因此本轮减少卡片/预览的重复玻璃效果，保留必要的浮动面板材质。参考 [Adopting Liquid Glass](https://developer.apple.com/documentation/technologyoverviews/adopting-liquid-glass)、[Materials](https://developer.apple.com/design/human-interface-guidelines/materials)、[Toolbars](https://developer.apple.com/design/human-interface-guidelines/toolbars)。

工作量收益主要是减少自定义视图、选择绘制和样式维护；没有运行性能基准，不把它写成已证明的耗电、内存或 OCR 速度提升。

## 实际实现对应关系

| 功能 | macOS 接口或能力 | 项目自行实现的部分 |
| --- | --- | --- |
| 文字 OCR | Vision RecognizeTextRequest（macOS 15+），VNRecognizeTextRequest 兼容 macOS 14 | 请求串行、参数与语言选择、搜索索引、失败回退 |
| 表格 OCR | Vision RecognizeDocumentsRequest（macOS 26+） | 单元格文字整理、合并单元格锚点、Markdown 输出与周边文字组合 |
| 读取与写入剪贴板 | AppKit NSPasteboard、NSPasteboardItem、UTType | 定时检查 changeCount、类型归类、去重、忽略敏感类型、自身写入抑制 |
| 文字去格式 | NSAttributedString 解析 HTML/RTF，系统文本/图片表示 | 选择文字、图片 OCR 或文件名的转换规则，暂存与恢复剪贴板 |
| 自动粘贴 | Core Graphics CGEvent 发送 ⌘V，Accessibility 检查权限 | 目标应用和焦点检查、等待时序、剪贴板变化保护；没有通用的一步“向任意应用粘贴纯文本”调用 |
| 全局快捷键 | Carbon RegisterEventHotKey；应用内 NSEvent | 自定义键录入、冲突判断和旧配置迁移。Carbon 是系统接口但属于较老一代 API |
| 历史存储 | SwiftData / SQLite、Foundation 文件系统 | 历史模型、保留期限、附件和缩略图管理 |
| 窗口和设置 | AppKit NSWindow/NSPanel/NSStatusItem、SwiftUI Form/List/Menu/Picker、SF Symbols | 面板布局、选择状态、业务分组 |
| 横向滚动与时间轴 | NSScrollView/NSEvent、SwiftUI 手势和布局 | 滚轮纵向转横向、时间刻度放大、时间到记录的映射；不是调用 Time Machine 的界面 |
| 开机启动 | ServiceManagement SMAppService | 同步应用偏好和系统实际注册状态 |

[Apple 表格识别说明](https://developer.apple.com/documentation/vision/recognize-tables-within-a-document) 描述了系统文档表格能力。OCR 在设备上执行，不捆绑 Tesseract、PaddleOCR 等额外模型，也没有新增云 OCR 依赖；能识别的语言和质量受当前系统 Vision 模型限制。

Sparkle、MCP SDK 是第三方依赖，不属于 macOS 原生能力。当前上游自动更新停用，MCP 不运行。PostHog 依赖和行为统计已移除，仅有本机固定诊断码日志，不上传。保留归档代码仍需保留相应编译依赖，不等于它们在后台执行。

## 候选栏的光标定位

参考 [鼠须管输入控制器](https://github.com/rime/squirrel/blob/a685441add85c87f09affee95621552a61c1bdad/sources/SquirrelInputController.swift#L605) 和 [候选窗定位](https://github.com/rime/squirrel/blob/a685441add85c87f09affee95621552a61c1bdad/sources/SquirrelPanel.swift#L477)：输入法可向自己的 IMKTextInput 客户端直接取得输入行矩形。Pastel it 是独立剪贴板工具，不能直接借用这个输入法客户端。

本项目独立实现：打开前记录目标进程，后台通过 AXFocusedUIElement、AXSelectedTextRange 与 [AXBoundsForRange](https://developer.apple.com/documentation/applicationservices/kaxboundsforrangeparameterizedattribute) 查询范围几何；空范围不被支持时尝试相邻字符的边界。只取坐标，不读取 AXValue 或选中文字；安全输入框直接回退。每次查询设置短消息超时，避免主线程等待目标应用。

AX 全局坐标按主显示器顶部转换为 AppKit 坐标，支持负坐标和上下排列的显示器。面板优先在光标下方，空间不足时翻转并钳制到可见区域；展开沿用缓存的光标矩形，不改为读取本工具面板的焦点。无法取得坐标时在打开时的鼠标附近显示说明，不自动弹权限授权、不重置系统权限。未直接拷贝鼠须管代码或引入它的运行依赖。

## 历史数据与原生列表的边界

macOS 26 起 Spotlight 提供系统剪贴板历史；目前未找到可供第三方读取其历史的公开 API，因此本项目继续通过 NSPasteboard 捕获当前内容，用 SwiftData 与附件文件自行保留历史。NSPasteboard.pasteboardItems 是当前复制操作中的多个项目，不是历次复制记录；不会以系统私有数据库作为依赖。

候选列表采用 AppKit NSTableView／NSScrollView，外层 NSPanel；设置使用标准 NSWindow 与 SwiftUI 分组 Form，OCR 仍使用 Vision。原生 API 负责系统交互，分页、保留期限、去重和样式演示仍由项目实现。
