# 项目来源与开发分工

Pastel it！基于 [Paste It](https://github.com/yipeng-git/paste-it)，原作者为 **Yipeng Zhang 及 Paste It contributors**。上游的 [MIT 许可证与版权原文](../LICENSE)保持不变。

| 项目 | 记录 |
| --- | --- |
| 上游基线 | `904287f6f80e791ea347938582a3550775627927`，版本0.2.9 |
| 导入的本机基线 | `eb369c2`，已有资源启动与现代Vision OCR修复 |
| 派生项目 | `Haookun/pastel-it`，显示名 Pastel it！ |
| 维护者 | Haookun：需求、产品决定、素材参考与手动验收 |
| 主要新增／修改代码 | OpenAI Codex：编写、修复、整合、自动验证、构建与文档 |
| 部分界面协作 | Kimi Code CLI：原生控件、布局和交互设计实现，由Codex整合检查 |

“Codex编写”描述派生部分的开发过程，不表示上游代码、第三方库或系统API由Codex原创，也不表示OpenAI或Kimi对本项目提供官方背书。运行时OCR不调用这些开发工具。

本仓库最初为独立私人派生库，保留上游 Git 历史，并非 GitHub fork 网络中的子仓库。2026-11-04 维护者授权公开并发布 v0.3.0，见 [分发说明](distribution.md)。

内部可执行文件和Swift目标仍名为 `PasteIt` / `PasteItCore`。v0.3.0 的 bundle ID 与偏好域为 `io.github.haookun.pastel-it`，数据位于 `~/Library/Application Support/PastelIt/`，与原版及早期私人版本独立，不自动迁移旧数据。

当前能力、停用功能和验证范围分别见 [功能](features.md)、[开发指南](development.md)和 [验证记录](validation.md)。第三方依赖各自保留许可，见 [完整致谢](../THIRD_PARTY_NOTICES.md)；图标参考由维护者提供，来源记录见 [设计](design.md)。

`work/`、`dist/`、`.build/`和本机凭据不提交。历史数据库、真实日志、用户附件、私钥与登录凭据不应成为开源内容。
