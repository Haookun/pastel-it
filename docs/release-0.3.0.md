# v0.3.0 发布检查

日期：2026-11-04。首个公开派生版，构建号12；上游基线为 Paste It 0.2.9。

## 已处理的公开前决定

- 维护者确认蛋挞参考图有权公开使用、改编及分发。
- 独立应用身份 `io.github.haookun.pastel-it`，新历史／配置／权限，不自动读取或迁移旧版数据。
- 候选栏优先并默认，时间轴可选；已有明确保存的时间轴选择仍可持久化。
- 首发仅 Apple Silicon arm64；ad-hoc 签名，无 Developer ID、无公证、无自动更新。
- Git 历史853个文件对象的常见凭据模式和敏感文件名扫描未发现命中；不将模式扫描表述为无遗漏保证。

## 代码验证

验证环境：Apple Silicon、macOS27.0.1、Swift6.4.2（当前锁定Swift Collections要求6.4）。使用公共 GitHub 依赖，非忽略的本机修复副本。根目录 Package.resolved 固定选中修订；完整第三方许可随 App 附带。

- `swift test --scratch-path /private/tmp/pastel-public-20261104`：65项共享测试通过，63项集成测试通过，1项已知系统Vision稀疏中文限制。
- 新配置候选默认、未知值回退及显式时间轴选择持久化已有回归测试。
- `package-release.sh --variant arm64 --adhoc-release`：发行构建、9种语言资源完整性、嵌套签名和DMG检查；已只读挂载核对实际镜像：arm64、0.3.0(12)、独立标识、全部9种语言、完整许可及Applications快捷链接；严格深度签名有效。
- Shell语法、文档链接、SVG比例及许可检查随本次提交完成；不声称已通过Apple审核。

## 保留的验证范围

[人工清单 R01–R05](manual-validation.md) 待维护者反馈：新身份首次授权、真实跨应用粘贴和候选光标定位、DMG下载后的Gatekeeper操作。旧系统、Intel、多显示器及所有第三方输入控件不作完整兼容性保证。本轮不安装或操作维护者真实历史。

这些是已披露的验收范围，不隐瞒为“全部功能验收通过”。可通过Issue报告复现步骤，截图请使用合成内容。

## 发行文件

`Pastel-it-0.3.0-arm64.dmg`，4649614字节。SHA-256：

```text
213e1d4dcae14f8416a787a21169e5ddbc62f487a7be41b9128915dae41b54b7
```
