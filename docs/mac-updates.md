# Pastel it！更新策略

v0.3.0 从 [GitHub Releases](https://github.com/Haookun/pastel-it/releases) 手动下载 Apple Silicon DMG，采用 ad-hoc 签名，无公证。详见 [分发说明](distribution.md)。

## 自动更新继续关闭

`AppBrand.updatesEnabled` 为 false，Sparkle 不启动；Info.plist 不含上游 SUFeedURL 或 SUPublicEDKey。旧偏好不能恢复上游更新。不要因为仓库公开就自动启用 Sparkle，不复用原作者的更新密钥或下载源。

v0.3.0 使用新应用标识和全新数据目录，不迁移原版／旧私人版本数据。此后的公开版升级应保持新身份，并在替换应用前退出运行中的版本；不要为了更新删除用户历史。

## 发布工具边界

当前打包路径是 `package-release.sh --variant arm64 --adhoc-release`，制作后单独提交、打tag、上传Release。版本变更需递增 CFBundleVersion 并重新生成语言资源恢复清单；上传 SHA-256 校验文件，附完整许可。

旧 `scripts/release.sh` 保留 Developer ID、公证和 Sparkle feed 的自动发布工作流，不用于本版。其 `--dry-run` 和 `--no-push` 都不表示无副作用；如未来采用，需另行确认签名、更新密钥与发布范围。没有创建 GitHub Pages 或自动更新源。
