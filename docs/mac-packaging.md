# macOS 本机打包与可选发布签名

默认用于本机编译和个人使用，不需要 Apple Developer 账号、Developer ID 或公证。
采用不带开发者身份的 ad-hoc 签名，不创建自签名证书，也不关闭 macOS 安全保护。

一键脚本：[`scripts/package-release.sh`](../scripts/package-release.sh)  
更新发版：[`mac-updates.md`](mac-updates.md)

## 本机编译和运行（默认）

```sh
./scripts/package-release.sh --variant arm64 --local-test
codesign --verify --deep --strict --verbose=2 "dist/local-test/arm64/Pastel it！.app"
"dist/local-test/arm64/开始合成验证.command"
```

`--local-test` 使用 `codesign --sign -`，按由内到外的顺序签名 Sparkle 和主应用；
不生成 DMG、不公证、不安装、不发布。文件同步可能为 Documents 下的文件补充 Finder 元数据，
因此先在临时目录签名，再复制回项目，等待同步元数据落定后清理并严格校验，其他 `dist/` 产物保持不变。
同时保留 `dist/local-test/Pastel-it-arm64-local.zip` 中的干净签名副本，方便存放到不受文件同步影响的位置。
双击 `dist/local-test/arm64/开始合成验证.command` 可进入下述合成模式；启动器会解压干净签名副本到系统临时目录，校验后再启动，避免文件同步在校验后重新添加元数据。`开始普通验证.command` 使用真实历史。两个入口均不安装应用。

`--validation-session` 启动真实应用界面，但历史使用内存数据库、48 条合成记录、临时附件和独立偏好；
不修改真实历史或开机启动项，退出后清理测试附件和偏好。它仍使用系统剪贴板和快捷键，只复制合成内容进行验证。
不带该参数启动则使用原有真实历史。未明确要求安装时，应用留在项目目录。
按用户约定，agent 只做代码、编译、资源和签名校验，实际功能由用户按 [手动确认清单](manual-validation.md) 验收。

ad-hoc 用于本机运行，不是 Apple 开发者身份认证；复制给其他人或下载后，Gatekeeper 仍可能要求对这个应用单独允许打开。
参见 [Apple 的单应用打开流程](https://support.apple.com/en-us/102445)。不要全局关闭 Gatekeeper、SIP、AMFI 或重置系统权限。

本机编译采用临时签名也是开源项目的常见选择之一，例如 [Ghostty 本机构建配置](https://github.com/ghostty-org/ghostty/blob/c7cbc9bfd44cb11a9c7eae00f1166624671e363b/macos/Ghostty.xcodeproj/project.pbxproj#L543)
将签名身份设为 `-` 并留空开发团队。开源许可与代码签名是独立事项，其他项目仍可能为公开安装包使用 Developer ID。
[Apple 对 Apple Silicon 代码签名的说明](https://support.apple.com/en-au/guide/security/secebb113be1/web) 说明本机 arm64 代码需要有效签名，ad-hoc 可以满足基础签名要求。

## 可选：对外分发前置条件

以下 Developer ID、公证和 DMG 流程仅在以后决定使用这些分发方式时启用；缺少证书不阻塞以上本机流程。

本机 Keychain 需具备：

| 项 | 用途 |
| --- | --- |
| **Developer ID Application** 证书 | 签名 `.app` / Sparkle / DMG 内应用 |
| **notarytool** 凭据（Apple ID + App-specific password + Team ID） | 公证 |
| Sparkle EdDSA 私钥（Keychain） | `generate_appcast` 给更新签名 |

确认本机身份：

```sh
security find-identity -v -p codesigning | grep "Developer ID Application"
```

## 公证凭据（一次）

```sh
xcrun notarytool store-credentials "paste-it-notary" \
  --apple-id "your-apple-id@example.com" \
  --team-id "YOURTEAMID" \
  --password "xxxx-xxxx-xxxx-xxxx"
```

可选环境变量：

```sh
export PASTEIT_CODESIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)"
export PASTEIT_NOTARY_PROFILE="paste-it-notary"
```

## 打包

```sh
./scripts/package-release.sh
```

默认产出两份 DMG：`dist/PasteIt-{ver}-arm64.dmg` 与 `dist/PasteIt-{ver}-universal.dmg`。

DMG 使用 UDZO（zlib）压缩，显式设置 `compression_level = 9`，避免使用系统默认的低压缩等级。应用图标 `Assets.car` 和 `AppIcon.icns` 仅放在主应用的 `Contents/Resources/`；SwiftPM 资源包仅声明各语言的 `.lproj` 目录，不打入重复图标、宣传 PNG 或 `Localizable.xcstrings` 源表。新增语言时同步 `Package.swift` 的资源列表。打包和调试脚本在构建前清理旧的 SwiftPM 资源包，避免增量构建残留已删除的安装盘背景等资源。

常用选项：

```sh
./scripts/package-release.sh --skip-notarize
./scripts/package-release.sh --skip-dmg
./scripts/package-release.sh --variant arm64
```

没有 Developer ID 证书时，可以只编译并组装应用包：

```sh
./scripts/package-release.sh --variant arm64 --build-only
```

输出为 `dist/build-only/arm64/Pastel it！.app`，包含语言包、图标和依赖资源。
此选项不做应用签名、公证、DMG、安装或发布，也不替代签名安装与真实交互验收；
不要将该未签名应用安装到 `/Applications`。它只清理 `dist/build-only/`，保留其他打包产物。
如需复用已有 SwiftPM 构建目录，设置 `PASTEIT_BUILD_PATH`；本机离线依赖仍需显式设置
`PASTEL_USE_LOCAL_DEPENDENCIES=1`。

DMG 使用紧凑的左右拖拽安装布局：应用在左、Applications 快捷方式在右，540 × 320 pt 窗口、96 pt 图标，隐藏侧栏和工具栏。不嵌入背景图或箭头。使用固定版本的 `dmgbuild` 直接生成 Finder 布局元数据；配置见 `scripts/dmg-settings.py`，工具安装在忽略的 `.tools/dmg-layout/`。

布局参考 [VLC 的公开配置](https://github.com/videolan/vlc/blob/master/extras/package/macosx/dmg/dmg_settings.py) 与 [IINA 的打包脚本](https://github.com/iina/iina/blob/develop/other/generate_dmg.sh)：保留固定窗口和同高的左右图标，去掉项目自己的装饰背景。540 × 320 是本项目选择的尺寸。

仅重新封装现有版本的安装盘时，可运行 `./scripts/package-release.sh --repack-dmg`。它会先验证 `dist/arm64` 和 `dist/universal` 中应用的版本、Developer ID 签名及公证票据，再重新生成并签名 DMG；应用本体与版本号保持不变。替换已发布附件时必须重新签署 Sparkle 更新并同步更新源的签名和大小。

## 发版衔接

```sh
./scripts/release.sh 0.2.0
```

细节见 [`mac-updates.md`](mac-updates.md)。Sparkle 工具链由 `generate-appcast.sh` 下载到 `.tools/sparkle/`（已 gitignore）。

## 常见问题

| 现象 | 处理 |
| --- | --- |
| 找不到 Developer ID Application | 证书未下到本机 |
| `notarytool` 认证失败 | App 专用密码过期或 Team ID 错 |
| 公证被拒 Invalid signature | Sparkle 内层组件需按官方顺序重签；勿盲目 `--deep` |
| Gatekeeper 仍拦 | 检查 staple；`spctl -a -vv` / `stapler validate` |
| `codesign` 报 entitlements XML 语法错 | `PasteIt.entitlements` 禁止 XML 注释 |

## 检查命令

```sh
security find-identity -v -p codesigning
codesign -dv --verbose=4 "dist/Pastel it！.app"
codesign --verify --deep --strict --verbose=2 "dist/Pastel it！.app"
xcrun stapler validate "dist/Pastel it！.app"
spctl -a -vv "dist/Pastel it！.app"
```
