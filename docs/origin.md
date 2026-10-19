# 来源与私人仓库

Pastel it！基于 [yipeng-git/paste-it](https://github.com/yipeng-git/paste-it)，原作者为 Yipeng Zhang 及 Paste It contributors。原 [MIT 许可证](../LICENSE) 与版权声明保持不变。

- 上游基线：`904287f6f80e791ea347938582a3550775627927`，版本 0.2.9。
- 导入的本机基线：`eb369c2`，包含资源启动与现代 Vision OCR 修复。
- 私人派生仓库：`Haookun/pastel-it`，显示名 **Pastel it！**。
- 新增的功能、交互与验证边界见 [功能说明](features.md) 和 [验证记录](validation.md)。

GitHub 不允许将公开上游的 fork 单独改为私有。因此本项目采用独立私有仓库，不属于 GitHub 的公开 fork 网络。通过 Git 保留上游历史与派生基线，并保留 upstream remote，便于后续人工比较原项目变更。没有将本轮代码推送到先前的公开 fork，也没有向上游提交 PR。

内部可执行文件和 Swift 目标继续叫 `PasteIt` / `PasteItCore`。bundle ID `app.paste-it.mac`、偏好设置域与 `~/Library/Application Support/PasteIt/` 保持兼容。本版应替代现有安装，不能与原版作为两个独立实例并行运行。

此仓库没有发布二进制、签名密钥、公证凭据、统计 token、剪贴板数据库或本机依赖副本。`work/`、`dist/`、`.build/` 与凭据路径均被忽略。图标参考由用户提供，项目内保留相应图片与矢量源。
