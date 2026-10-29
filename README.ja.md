# Pastel it！

macOS向けのクリップボード履歴・端末内OCRツールです。[Paste It](https://github.com/yipeng-git/paste-it)を基に、主な追加・変更コードを **OpenAI Codex** が作成・統合し、**Kimi Code** が一部UIの設計と実装に参加しました。上流プロジェクトと依存ライブラリの著作権・ライセンスは保持します。

[English](README.en.md) · [中文](README.md) · [文書一覧](docs/README.md) · [出典・依存関係](THIRD_PARTY_NOTICES.md)

- テキスト、画像、リンク、ファイル参照の履歴を検索・整理。
- 画面下のタイムライン、または入力カーソル付近の縦候補リストを選択。
- 候補は1ページ10件。`1`–`9`・`0`で選択、`Tab`／`Shift-Tab`でページ移動。
- Visionで端末内OCR。macOS 26以降ではMarkdown表として出力可能。
- クイックペーストは現在のクリップボードを変換し、初期状態は無効。
- 使用統計を送信せず、ローカルログのみ個別削除可能。リンクプレビューや明示的な言語修復は通信する場合があります。

履歴を開く既定キーは `⇧⌘C`、クイックペーストは `⇧⌘V`。最低配置先はmacOS 14、ビルドにはSwift 6.2以降が必要です。実機確認はApple Silicon／macOS 27.0.1で行われ、他の環境は未確認です。

正式なバイナリ配布と自動更新はありません。2026-10-29の方針は文書整備のみで、配布パッケージ作成は公開後に再検討します。将来の単一Appに対するOpen Anyway方式は [分发约定](docs/distribution.md) に記録しています。ビルド手順とローカル依存コピーの検証範囲は [開発ガイド](docs/development.md) を参照してください。

直接依存はSparkle 2.9.4とMCP Swift SDK 0.12.1で、更新・MCPサービスの起動は無効です。原版と同じデータ識別子を使うため、並行起動は避けてください。[LICENSE](LICENSE) · [完全なライセンス記録](LICENSES/README.md)
