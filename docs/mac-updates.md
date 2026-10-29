# Pastel it！更新策略

> 2026-10-29：当前不执行对外打包、发布或自动更新配置。本文是保留的工程参考，不是本轮操作指令；待项目公开后再讨论。[当前分发约定](distribution.md)。

本私人派生版尚未配置自己的签名更新源。`AppBrand.updatesEnabled` 为 false，Sparkle 不会启动；`Info.plist` 已移除原项目的 `SUFeedURL` 和 `SUPublicEDKey`，自动检查与下载均关闭。已有偏好中的上游更新开关不会使本版重新连接原源。

当前仓库没有安装包或 Release。应由维护者先配置自己的 Developer ID、公证凭据、Sparkle 更新签名密钥和经授权的分发方式，再启用更新。不要复用原作者的签名公钥或把私人构建指向公开上游下载地址。

`scripts/package-release.sh` 负责签名打包，默认生成 `Pastel it！.app`。`scripts/release.sh` 会修改版本、创建 GitHub Release、生成更新 feed、提交和推送，属于发布流程；`--dry-run`、`--no-push` 仍可能有本地或外部副作用。未经发布授权不得运行。私人仓库的分发与 GitHub Pages 可见性需另行设计，本次没有创建 Pages。

普通开发使用 `swift build` / `swift test`；现有离线依赖可通过 `PASTEL_USE_LOCAL_DEPENDENCIES=1` 显式选择。资源与 UI 改动仍需正式签名安装后验收，当前安装边界见 [验证记录](validation.md)。
