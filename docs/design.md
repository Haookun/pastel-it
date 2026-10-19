# Pastel it！设计说明

## 品牌

显示名为 **Pastel it！**，仓库名为 `pastel-it`。视觉以奶油蛋挞为主题：奶油底、金黄色馅心、橙色酥皮与深褐焦斑。名称与图形用于区分原 Paste It 项目；原项目署名与许可证继续保留。

| 用途 | 源稿 | 生成输出 |
| --- | --- | --- |
| 彩色应用图标 | `design/pastel-tart.svg`、`design/pastel-app-icon.svg` | `design/AppIcon.icon`、`Resources/AppIcon.icns`、`Resources/Assets.car`、`Resources/AppIcon.png` |
| 菜单栏图标 | `design/pastel-menubar.svg` | `Sources/PasteIt/UI/MenuBar/MenuBarTartArtwork.swift` |
| 图片参考 | `design/reference/cream-tart.png`、`design/reference/gold-tart.png` | 用户提供参考的去元数据副本 |

## 应用图标

<img src="../Resources/AppIcon.png" width="256" alt="Pastel it！奶油蛋挞应用图标">

奶油色参考图先去掉黑色外背景与圆角边缘残留，再保留酥皮、焦斑和高光进行路径追踪。色彩层次简化为平面色块，避免缩小时保留过多纹理噪声。矢量前景放入原生 Icon Composer 源包，关闭额外玻璃、镜面与阴影叠加，保留扁平插画特征。

默认背景为 `#FFF7E5`；深色外观采用温暖的深褐底。系统图标蒙版负责正式图标圆角，Markdown 预览使用带圆角的 PNG/SVG。正式资源由 Xcode actool 编译，同时提供旧系统使用的 ICNS 和资产目录。

SVG 是真正的路径文件，没有内嵌原 PNG。生成的 PNG 是矢量源的渲染结果，用于平台图标资源与文档预览。

## 菜单栏

<img src="../design/pastel-menubar.svg" width="128" alt="蛋挞菜单栏模板图案">

极简金色参考图转换为单色模板：保留蛋挞外沿、奶馅留白、焦斑和酥皮竖向分片，清理透明边缘噪点。图案以方形坐标居中，状态图像尺寸为 24×22 pt。

菜单栏不使用固定金色，`isTemplate` 让系统按菜单栏明暗着色。按住 ⌘C 或 ⌘V 时轮廓略加粗，松开恢复；同时按住时加粗更明显。此处不再显示 C/V 字母，避免小尺寸文字拥挤。矢量路径编入应用，启动时不读取外部 SVG。

## 时间轴与设置

沿用原有系统玻璃面板和卡片，不另外叠加装饰性背景。底部增加时间刻度，悬停放大附近刻度、浮现完整时间，点击或拖动定位记录。面板高度增加到 380 pt，为固定高度卡片与时间轴留出空间；预览仍显示在面板上方。

OCR 参数与快捷粘贴同页展示：先决定识别行为，再选择纯文本转换范围。转换范围用复选框；启用功能、语言纠错与表格识别用开关。现有三个全局快捷键仍在通用设置中，新增快捷粘贴独立录入并检查冲突。

## 重新生成

已经提交生成文件，普通 Swift 构建不需要安装追踪工具。修改参考图并重新矢量化时：

```sh
python3 -m venv .venv-artwork
.venv-artwork/bin/pip install -r scripts/artwork-requirements.txt
.venv-artwork/bin/python scripts/vectorize-pastel-artwork.py
python3 scripts/generate-menubar-icon.py
swift scripts/generate-app-icon.swift
```

最后一条需要已安装 Xcode，只编译资源，不签名、不安装、不发布。菜单栏生成脚本只接受当前矢量源使用的绝对路径命令和 translate 变换；不支持的 SVG 特性会明确报错，避免悄悄生成错误图案。
