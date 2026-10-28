# Pastel it！

<img src="Resources/AppIcon.png" width="144" alt="Pastel it！">

原生 macOS クリップボード管理ツール。テキスト・画像の履歴、多言語 OCR、macOS 26 以降の表 OCR、横方向のホイール操作、コピー日時のルーラー、現在のクリップボードを変換するクイックペーストを備えます。

[English](README.en.md) · [中文 / 功能说明](README.md) · [Design](docs/design.md) · [Validation](docs/validation.md)

This is a private derivative of [Paste It](https://github.com/yipeng-git/paste-it), not an upstream release. No installer has been published. Automatic updates from the original project are disabled. macOS 14+ and Swift tools 6.2+ are required.

```sh
swift build
swift test
```

Open History defaults to ⇧⌘C; Quick Paste defaults to ⇧⌘V and starts disabled. The standalone legacy plain-paste command is removed. Paste Stack and MCP are archived with all product entries and runtime activation disabled. Existing internal identifiers and the data directory are retained for compatibility; do not run both apps side by side. See [LICENSE](LICENSE) for upstream MIT attribution.

設定の「クリップボード → 表示スタイル」でタイムラインと候補バーを切り替えられます。候補は縦に1ページ10件表示され、1–9と0で選択、Tabで次のページ、Shift-Tabで前のページへ移動します。画像はOCR概要、ファイルは名前を表示し、ホバーで画像やフルパスを確認できます。

候補バーは文字入力カーソル付近に表示され、下側に空きがなければ上側へ移動します。アクセシビリティ権限または位置情報が利用できない場合は、ポインタ付近に表示して案内します。
