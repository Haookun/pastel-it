# 分发与安装

2026-11-04，维护者授权首次公开发布 v0.3.0，取代此前“只记录、不分发”的阶段约定。

## 发行范围

- Apple Silicon（arm64）DMG；最低部署目标 macOS14，现代文字OCR macOS15+，表格OCR macOS26+。Intel 暂无安装包。
- ad-hoc 临时签名，无 Developer ID、无 Apple 公证；不需要安装或信任自签名根证书。
- 自动更新保持关闭，从 GitHub Releases 手动下载。Release 提供 SHA-256 校验值，App 内附原项目和第三方许可。
- 构建命令：`./scripts/package-release.sh --variant arm64 --adhoc-release`；不自动提交、上传或创建 Release。旧 `release.sh` 为 Developer ID／Sparkle 工作流，不用于本次发版。

## 安装与首次打开

下载 DMG、打开，将 Pastel it！拖入 Applications，再从 Applications 启动。若被 macOS 拦截，在确认来源可信且文件未被更改后，先尝试打开，再进入“系统设置 → 隐私与安全性 → 仍要打开”并确认。该流程仅为单个应用建立例外，并不表示 Apple 审核通过。系统版本、来源和策略可能影响提示。

参考 [Apple 的单个应用打开说明](https://support.apple.com/zh-cn/102445)。不要关闭 Gatekeeper／SIP／AMFI，不使用全局放行或批量移除隔离标记的脚本。损坏、撤销或恶意内容警告不等同普通未公证提示。

## 独立数据身份

v0.3.0 使用 `io.github.haookun.pastel-it`，新偏好、新权限、新历史：`~/Library/Application Support/PastelIt/`。语言恢复缓存同样在新目录，诊断日志在 `~/Library/Logs/PastelItPublic/`。不自动迁移、删除或读取旧 `PasteIt` 历史及旧版设置。原来的临时私用版本与公开版不是就地升级关系。

如需卸载，退出 App 并删除应用；历史和配置不会自动清除。不要将删日志按钮误认为重置应用。首次授予辅助功能后才能定位光标和直接粘贴；拒绝时仍可复制，位置回退到鼠标附近。

## 验证与限制

发布核验记录见 [发布检查](release-0.3.0.md)。机器测试覆盖代码、资源与签名；真实跨应用粘贴、不同屏幕和旧系统体验仍需要人工反馈。OCR 模型精度不是应用可保证的结果。
