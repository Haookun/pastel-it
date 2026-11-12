#!/usr/bin/env python3
"""Generate Resources/Localization/Localizable.xcstrings from the translation table."""

from __future__ import annotations

import json
import sys
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

from localization_batch2 import BATCH2_LANGS, merge_batch2
from localization_batch_cjk import merge_batch_cjk

OUT = ROOT / "Resources" / "Localization" / "Localizable.xcstrings"
LPROJ_ROOT = ROOT / "Resources"

SUPPORTED_LANGS = ("en", "zh-Hans", "zh-Hant", "ja", "ko", *BATCH2_LANGS)

# key -> { en, zh-Hans, ja, ... }
STRINGS: dict[str, dict[str, str]] = {
    # Filter categories
    "filter.all": {"en": "All types", "zh-Hans": "全部类型", "ja": "すべての種類"},
    "filter.text": {"en": "Text", "zh-Hans": "文本", "ja": "テキスト"},
    "filter.number": {"en": "Number", "zh-Hans": "数字", "ja": "数値"},
    "filter.link": {"en": "Link", "zh-Hans": "链接", "ja": "リンク"},
    "filter.image": {"en": "Image", "zh-Hans": "图片", "ja": "画像"},
    "filter.file": {"en": "File", "zh-Hans": "文件", "ja": "ファイル"},
    "filter.byType": {"en": "Filter by type", "zh-Hans": "按类型筛选", "ja": "種類で絞り込み"},
    "filter.clear": {"en": "Clear type filter", "zh-Hans": "清除类型筛选", "ja": "種類フィルタを解除"},
    # Timeline tabs
    "tab.default": {"en": "Default", "zh-Hans": "默认", "ja": "デフォルト"},
    "tab.pinned": {"en": "Pinned", "zh-Hans": "已固定", "ja": "ピン留め"},
    "tab.folder": {"en": "Folder", "zh-Hans": "文件夹", "ja": "フォルダ"},
    # Clip types
    "clipType.text": {"en": "Text", "zh-Hans": "文本", "ja": "テキスト"},
    "clipType.richText": {"en": "Rich Text", "zh-Hans": "富文本", "ja": "リッチテキスト"},
    "clipType.html": {"en": "HTML", "zh-Hans": "HTML", "ja": "HTML"},
    "clipType.image": {"en": "Image", "zh-Hans": "图片", "ja": "画像"},
    "clipType.file": {"en": "File", "zh-Hans": "文件", "ja": "ファイル"},
    "clipType.url": {"en": "Link", "zh-Hans": "链接", "ja": "リンク"},
    "clipType.mixed": {"en": "Mixed", "zh-Hans": "混合", "ja": "混合"},
    "clipType.folder": {"en": "Folder", "zh-Hans": "文件夹", "ja": "フォルダ"},
    "clipType.empty": {"en": "Empty", "zh-Hans": "空", "ja": "空"},
    "clipPreview.oneCharacter": {"en": "1 character", "zh-Hans": "1 个字符", "ja": "1 文字"},
    "clipPreview.characters": {"en": "%lld characters", "zh-Hans": "%lld 个字符", "ja": "%lld 文字"},
    # Keep history
    "keepHistory.oneDay": {"en": "1 Day", "zh-Hans": "1 天", "ja": "1 日"},
    "keepHistory.oneWeek": {"en": "1 Week", "zh-Hans": "1 周", "ja": "1 週間"},
    "keepHistory.oneMonth": {"en": "1 Month", "zh-Hans": "1 个月", "ja": "1 か月"},
    "keepHistory.forever": {"en": "Forever", "zh-Hans": "永久", "ja": "無期限"},
    # Paste stack
    "stack.fifo": {"en": "First in, first out", "zh-Hans": "先进先出", "ja": "先入れ先出し"},
    "stack.lifo": {"en": "Last in, first out", "zh-Hans": "后进先出", "ja": "後入れ先出し"},
    "stack.fifoHelp": {
        "en": "Copy order. Click to reverse.",
        "zh-Hans": "按复制顺序。点击切换方向。",
        "ja": "コピー順。クリックで反転。",
    },
    "stack.lifoHelp": {
        "en": "Newest first. Click for copy order.",
        "zh-Hans": "最新优先。点击切换为复制顺序。",
        "ja": "新しい順。クリックでコピー順に。",
    },
    "stack.paste": {"en": "Paste", "zh-Hans": "粘贴", "ja": "ペースト"},
    "stack.open": {"en": "Open Paste Stack", "zh-Hans": "打开粘贴堆栈", "ja": "ペーストスタックを開く"},
    "stack.close": {"en": "Close Paste Stack", "zh-Hans": "关闭粘贴堆栈", "ja": "ペーストスタックを閉じる"},
    "stack.title": {"en": "Stack", "zh-Hans": "堆栈", "ja": "スタック"},
    "stack.statusWithCount": {"en": "Stack · %lld", "zh-Hans": "堆栈 · %lld", "ja": "スタック · %lld"},
    "stack.collecting": {"en": "Collecting", "zh-Hans": "收集中", "ja": "収集中"},
    "stack.closeHelp": {"en": "Close Paste Stack (⇧⌘C)", "zh-Hans": "关闭粘贴堆栈 (⇧⌘C)", "ja": "ペーストスタックを閉じる (⇧⌘C)"},
    "stack.pasteNext": {"en": "⌘V pastes next", "zh-Hans": "⌘V 粘贴下一项", "ja": "⌘V で次をペースト"},
    "stack.emptyTitle": {"en": "Copy to fill the stack", "zh-Hans": "复制内容以填充栈", "ja": "コピーしてスタックを埋める"},
    "stack.emptySubtitle": {"en": "Then ⌘V in any app", "zh-Hans": "然后在任意应用中按 ⌘V", "ja": "その後、任意のアプリで ⌘V"},
    "stack.accessibilityHint": {
        "en": "Grant Accessibility so ⌘V can advance the stack",
        "zh-Hans": "请允许辅助功能权限，以便 ⌘V 可推进堆栈",
        "ja": "⌘V でスタックを進めるにはアクセシビリティを許可してください",
    },
    "stack.resizeHelp": {"en": "Drag to resize height", "zh-Hans": "拖动以调整高度", "ja": "ドラッグで高さを変更"},
    "stack.moveToNext": {"en": "Move to Next", "zh-Hans": "移到下一项", "ja": "次へ移動"},
    "stack.delete": {"en": "Delete", "zh-Hans": "删除", "ja": "削除"},
    # Menu bar
    "menu.openPaste": {"en": "Open Paste", "zh-Hans": "打开剪贴板", "ja": "クリップボードを開く"},
    "menu.clearStack": {"en": "Clear Paste Stack", "zh-Hans": "清空粘贴堆栈", "ja": "ペーストスタックをクリア"},
    "menu.pastePlain": {"en": "Paste Without Formatting", "zh-Hans": "粘贴为纯文本", "ja": "書式なしでペースト"},
    "menu.pauseCapture": {"en": "Pause Capture", "zh-Hans": "暂停捕获", "ja": "キャプチャを一時停止"},
    "menu.resumeCapture": {"en": "Resume Capture", "zh-Hans": "恢复捕获", "ja": "キャプチャを再開"},
    "menu.mcp": {"en": "MCP", "zh-Hans": "MCP", "ja": "MCP"},
    "menu.copyMcpURL": {"en": "Copy MCP URL", "zh-Hans": "复制 MCP 地址", "ja": "MCP URL をコピー"},
    "menu.preferences": {"en": "Preferences…", "zh-Hans": "偏好设置…", "ja": "環境設定…"},
    "menu.checkUpdates": {"en": "Check for Updates…", "zh-Hans": "检查更新…", "ja": "アップデートを確認…"},
    "menu.quit": {"en": "Quit Pastel it！", "zh-Hans": "退出 Pastel it！", "ja": "Pastel it！ を終了"},
    "menu.more": {"en": "More", "zh-Hans": "更多", "ja": "その他"},
    "menu.statusTooltip": {
        "en": "Pastel it！ — hold ⌘C / ⌘V to press the keys",
        "zh-Hans": "Pastel it！ — 按住 ⌘C / ⌘V 查看按键",
        "ja": "Pastel it！ — ⌘C / ⌘V を押し続けてキーを表示",
    },
    "menu.statusClickHint": {
        "en": "Left-click: timeline · Right-click: menu",
        "zh-Hans": "左键：时间线 · 右键：菜单",
        "ja": "左クリック：タイムライン · 右クリック：メニュー",
    },
    # Timeline
    "timeline.clearFilter": {"en": "Clear filter", "zh-Hans": "清除筛选", "ja": "フィルタを解除"},
    "timeline.selectedCount": {
        "en": "%lld selected — Return to paste",
        "zh-Hans": "已选 %lld 项 — 按 Return 键粘贴",
        "ja": "%lld 件選択 — Return でペースト",
    },
    "timeline.newFolder": {"en": "New Folder", "zh-Hans": "新建文件夹", "ja": "新規フォルダ"},
    "timeline.newFolderHelp": {"en": "New Folder", "zh-Hans": "新建文件夹", "ja": "新規フォルダ"},
    "timeline.search": {"en": "Search (⌘F)", "zh-Hans": "搜索 (⌘F)", "ja": "検索 (⌘F)"},
    "timeline.searchHistory": {"en": "Search history", "zh-Hans": "搜索历史", "ja": "履歴を検索"},
    "timeline.noMatch": {"en": "No matching clips", "zh-Hans": "没有匹配的剪贴项", "ja": "一致する項目がありません"},
    "timeline.noTypeInPinned": {
        "en": "No %@ clips in Pinned",
        "zh-Hans": "已固定中没有 %@ 类型的剪贴项",
        "ja": "ピン留めに %@ の項目はありません",
    },
    "timeline.noTypeInFolder": {
        "en": "No %@ clips in this folder",
        "zh-Hans": "此文件夹中没有 %@ 类型的剪贴项",
        "ja": "このフォルダに %@ の項目はありません",
    },
    "timeline.noType": {
        "en": "No %@ clips",
        "zh-Hans": "没有 %@ 类型的剪贴项",
        "ja": "%@ の項目はありません",
    },
    "timeline.emptyDefault": {
        "en": "Copy something to build your clipboard history",
        "zh-Hans": "复制一些内容以建立剪贴板历史",
        "ja": "コピーしてクリップボード履歴を作成",
    },
    "timeline.emptyPinned": {
        "en": "Pin clips to keep them here permanently",
        "zh-Hans": "固定剪贴项以永久保留在此",
        "ja": "ピン留めしてここに常に表示",
    },
    "timeline.emptyFolder": {
        "en": "Add clips to this folder from the context menu",
        "zh-Hans": "从右键菜单将剪贴项添加到此文件夹",
        "ja": "コンテキストメニューからこのフォルダに追加",
    },
    "timeline.unpin": {"en": "Unpin", "zh-Hans": "取消固定", "ja": "ピン留めを解除"},
    "timeline.pin": {"en": "Pin", "zh-Hans": "固定", "ja": "ピン留め"},
    "timeline.addToFolder": {"en": "Add to Folder", "zh-Hans": "添加到文件夹", "ja": "フォルダに追加"},
    "timeline.removeFromFolder": {"en": "Remove from Folder", "zh-Hans": "从文件夹移除", "ja": "フォルダから削除"},
    "timeline.delete": {"en": "Delete", "zh-Hans": "删除", "ja": "削除"},
    "timeline.removeFromFolderAction": {"en": "Remove from Folder", "zh-Hans": "从文件夹移除", "ja": "フォルダから削除"},
    "timeline.copy": {"en": "Copy to Clipboard", "zh-Hans": "复制到剪贴板", "ja": "クリップボードにコピー"},
    "timeline.copyPlain": {"en": "Copy as Plain Text", "zh-Hans": "复制为纯文本", "ja": "プレーンテキストでコピー"},
    "timeline.edit": {"en": "Edit", "zh-Hans": "编辑", "ja": "編集"},
    "timeline.cancel": {"en": "Cancel", "zh-Hans": "取消", "ja": "キャンセル"},
    "timeline.create": {"en": "Create", "zh-Hans": "创建", "ja": "作成"},
    # Settings tabs
    "settings.tab.about": {"en": "About", "zh-Hans": "关于", "ja": "このアプリについて"},
    "settings.tab.general": {"en": "General", "zh-Hans": "通用", "ja": "一般"},
    "settings.tab.privacy": {"en": "Privacy", "zh-Hans": "隐私", "ja": "プライバシー"},
    "settings.tab.folders": {"en": "Folders", "zh-Hans": "文件夹", "ja": "フォルダ"},
    "settings.tab.stack": {"en": "Stack", "zh-Hans": "粘贴堆栈", "ja": "スタック"},
    "settings.tab.storage": {"en": "Storage", "zh-Hans": "存储", "ja": "ストレージ"},
    "settings.version": {"en": "Pastel it！ %@ (%@)", "zh-Hans": "Pastel it！ %@ (%@)", "ja": "Pastel it！ %@ (%@)"},
    "settings.aboutBlurb": {
        "en": "Pastel it！ is a local-first clipboard manager. History stays on this Mac.",
        "zh-Hans": "Pastel it！ 是一款本地优先的剪贴板管理器。历史记录仅保存在本 Mac。",
        "ja": "Pastel it！ はローカル優先のクリップボードマネージャーです。履歴はこの Mac にのみ保存されます。",
    },
    "settings.versionLabel": {"en": "Version", "zh-Hans": "版本", "ja": "バージョン"},
    "settings.showTutorial": {"en": "Show Tutorial…", "zh-Hans": "显示教程…", "ja": "チュートリアルを表示…"},
    "settings.whatsNew": {"en": "What's New…", "zh-Hans": "新功能…", "ja": "新機能…"},
    "settings.checkingUpdates": {"en": "Checking for updates…", "zh-Hans": "正在检查更新…", "ja": "アップデートを確認中…"},
    "settings.pauseCapture": {"en": "Pause clipboard capture", "zh-Hans": "暂停剪贴板捕获", "ja": "クリップボードのキャプチャを一時停止"},
    "settings.pastePlainDefault": {
        "en": "Paste as plain text by default",
        "zh-Hans": "默认粘贴为纯文本",
        "ja": "デフォルトでプレーンテキストとしてペースト",
    },
    "settings.plainTextFootnote": {
        "en": "⌃⌘V pastes once as plain text, then restores the original clipboard (Accessibility required to auto-paste). In the timeline, ⇧↩ pastes the selection as plain text.",
        "zh-Hans": "⌃⌘V 会粘贴一次纯文本，然后恢复原来的剪贴板内容（自动粘贴需要辅助功能权限）。在时间轴中，⇧↩ 会将所选内容粘贴为纯文本。",
        "ja": "⌃⌘V で一度プレーンテキストをペーストし、元のクリップボードを復元します（自動ペーストにはアクセシビリティが必要）。タイムラインでは ⇧↩ で選択項目をプレーンテキストとしてペーストします。",
    },
    "settings.launchAtLogin": {"en": "Launch at login", "zh-Hans": "登录时启动", "ja": "ログイン時に起動"},
    "settings.keepHistory": {"en": "Keep history", "zh-Hans": "保留历史", "ja": "履歴の保持"},
    "settings.maxHistoryItems": {"en": "Max history items", "zh-Hans": "最大历史条数", "ja": "履歴の最大件数"},
    "settings.clipboardPolling": {"en": "Clipboard polling", "zh-Hans": "剪贴板轮询", "ja": "クリップボードのポーリング"},
    "settings.seconds": {"en": "s", "zh-Hans": "秒", "ja": "秒"},
    "settings.stackDirection": {"en": "Default paste direction", "zh-Hans": "默认粘贴方向", "ja": "デフォルトのペースト方向"},
    "settings.stackFootnote": {
        "en": "⇧⌘C opens or closes Paste Stack. While the stack has items, ⌘V in any app pastes the next one (Accessibility required). Runtime controls live in the Stack panel and the ⋯ menu.",
        "zh-Hans": "⇧⌘C 可打开或关闭粘贴堆栈。堆栈中有内容时，在任意应用中按 ⌘V 可粘贴下一项（需辅助功能权限）。运行时控制位于堆栈面板和 ⋯ 菜单。",
        "ja": "⇧⌘C でペーストスタックを開閉。スタックに項目がある間、任意のアプリで ⌘V が次をペーストします（アクセシビリティが必要）。実行時の操作はスタックパネルと ⋯ メニューにあります。",
    },
    "settings.maxBinaryStorage": {
        "en": "Max binary storage: %lld MB",
        "zh-Hans": "最大二进制存储：%lld MB",
        "ja": "最大バイナリ容量：%lld MB",
    },
    "settings.pruneNow": {"en": "Prune Now", "zh-Hans": "立即清理", "ja": "今すぐ整理"},
    "settings.clearKeepPinned": {
        "en": "Clear History, Keep Pinned",
        "zh-Hans": "清除历史，保留已固定",
        "ja": "履歴を消去（ピン留めは保持）",
    },
    "settings.clearAllHistory": {"en": "Clear All History", "zh-Hans": "清除全部历史", "ja": "履歴をすべて消去"},
    # Folders settings
    "folders.pinnedFooter": {
        "en": "The Pinned tab cannot be renamed or deleted. Use Pin / Unpin on clips to manage its contents.",
        "zh-Hans": "「已固定」标签无法重命名或删除。在剪贴项上使用固定/取消固定来管理内容。",
        "ja": "「ピン留め」タブは名前変更・削除できません。項目のピン留め/解除で内容を管理します。",
    },
    "folders.noCustom": {"en": "No custom folders", "zh-Hans": "没有自定义文件夹", "ja": "カスタムフォルダはありません"},
    "folders.rename": {"en": "Rename…", "zh-Hans": "重命名…", "ja": "名前を変更…"},
    "folders.addHelp": {"en": "Add Folder", "zh-Hans": "添加文件夹", "ja": "フォルダを追加"},
    "folders.renameHelp": {"en": "Rename Folder", "zh-Hans": "重命名文件夹", "ja": "フォルダ名を変更"},
    "folders.deleteHelp": {"en": "Delete Folder", "zh-Hans": "删除文件夹", "ja": "フォルダを削除"},
    "folders.footer": {
        "en": "Create up to %lld custom folders. They appear as tabs next to Default and Pinned. Clips in folders are kept when history is pruned.",
        "zh-Hans": "最多创建 %lld 个自定义文件夹。它们会显示在「默认」和「已固定」旁的标签中。清理历史时文件夹中的剪贴项会保留。",
        "ja": "カスタムフォルダは最大 %lld 個。デフォルトとピン留めの隣のタブに表示されます。履歴整理時もフォルダ内の項目は保持されます。",
    },
    "folders.renameTitle": {"en": "Rename Folder", "zh-Hans": "重命名文件夹", "ja": "フォルダ名を変更"},
    "folders.namePlaceholder": {"en": "Folder name", "zh-Hans": "文件夹名称", "ja": "フォルダ名"},
    "folders.renameConfirm": {"en": "Rename", "zh-Hans": "重命名", "ja": "名前を変更"},
    # Privacy
    "privacy.noIgnoredApps": {"en": "No ignored apps", "zh-Hans": "没有忽略的应用", "ja": "無視するアプリはありません"},
    "privacy.addApp": {"en": "Add App", "zh-Hans": "添加应用", "ja": "アプリを追加"},
    "privacy.removeApp": {"en": "Remove App", "zh-Hans": "移除应用", "ja": "アプリを削除"},
    "privacy.ignoredApps": {"en": "Ignored Apps", "zh-Hans": "忽略的应用", "ja": "無視するアプリ"},
    "privacy.ignoredAppsFooter": {
        "en": "Copies made in these apps are never saved to history. Use this for password managers and other sensitive apps.",
        "zh-Hans": "这些应用中的复制内容不会保存到历史。适用于密码管理器等敏感应用。",
        "ja": "これらのアプリでのコピーは履歴に保存されません。パスワードマネージャーなどに使用してください。",
    },
    "privacy.protectedContent": {"en": "Protected Content", "zh-Hans": "受保护内容", "ja": "保護されたコンテンツ"},
    "privacy.protectedBlurb": {
        "en": "Sensitive clipboard markers from apps — such as password fields and temporary clips — are ignored automatically.",
        "zh-Hans": "来自应用的敏感剪贴板标记（如密码字段和临时剪贴）会自动忽略。",
        "ja": "パスワード欄や一時クリップなど、アプリの機密クリップボードマーカーは自動的に無視されます。",
    },
    "privacy.protectedFooter": {
        "en": "Ignored Apps skip everything from a whole app. Protected Content skips only marked sensitive pasteboard data, from any app.",
        "zh-Hans": "忽略的应用会跳过整个应用的所有内容。受保护内容仅跳过任何应用中标记为敏感的剪贴板数据。",
        "ja": "無視するアプリはアプリ全体をスキップします。保護されたコンテンツは、任意のアプリで機密とマークされたペーストボードデータのみをスキップします。",
    },
    "privacy.addIgnoredApp": {"en": "Add Ignored App", "zh-Hans": "添加忽略的应用", "ja": "無視するアプリを追加"},
    "privacy.chooseApp": {"en": "Choose…", "zh-Hans": "选择…", "ja": "選択…"},
    "privacy.search": {"en": "Search", "zh-Hans": "搜索", "ja": "検索"},
    "privacy.loadingApps": {"en": "Loading apps…", "zh-Hans": "正在加载应用…", "ja": "アプリを読み込み中…"},
    "privacy.chooseAppPanel": {"en": "Choose an app to ignore", "zh-Hans": "选择要忽略的应用", "ja": "無視するアプリを選択"},
    # Onboarding
    "onboarding.capture.title": {"en": "Copy to save", "zh-Hans": "复制即保存", "ja": "コピーして保存"},
    "onboarding.paste.title": {"en": "Pick from the timeline", "zh-Hans": "从时间线选取", "ja": "タイムラインから選択"},
    "onboarding.browse.title": {"en": "Preview & edit", "zh-Hans": "预览与编辑", "ja": "プレビューと編集"},
    "onboarding.organize.title": {"en": "Multi-select paste", "zh-Hans": "多选粘贴", "ja": "複数選択してペースト"},
    "onboarding.stack.title": {"en": "Paste Stack", "zh-Hans": "粘贴堆栈", "ja": "ペーストスタック"},
    "onboarding.capture.caption": {
        "en": "Copy anything — Pastel it！ saves it and flashes ⌘C in the menu bar.",
        "zh-Hans": "复制任意内容 — Pastel it！ 会保存并在菜单栏闪烁 ⌘C。",
        "ja": "何でもコピー — Pastel it！ が保存し、メニューバーで ⌘C を点滅させます。",
    },
    "onboarding.paste.caption": {
        "en": "⇧⌘V opens history. Double-click a clip, then ⌘V — or ⌃⌘V to paste without formatting.",
        "zh-Hans": "⇧⌘V 打开历史。双击剪贴项后按 ⌘V — 或 ⌃⌘V 无格式粘贴。",
        "ja": "⇧⌘V で履歴を開く。項目をダブルクリックして ⌘V — または ⌃⌘V で書式なしペースト。",
    },
    "onboarding.browse.caption": {
        "en": "Press Space to preview above the timeline. Click the text to edit.",
        "zh-Hans": "按空格键在时间线上方预览。点击文本可编辑。",
        "ja": "スペースでタイムライン上にプレビュー。テキストをクリックして編集。",
    },
    "onboarding.organize.caption": {
        "en": "⌘-click several clips, then press Return to paste them in order.",
        "zh-Hans": "⌘-点击多个剪贴项，然后按 Return 按顺序粘贴。",
        "ja": "⌘-クリックで複数選択し、Return で順にペースト。",
    },
    "onboarding.stack.caption": {
        "en": "⇧⌘C opens a queue on the right. Copy several things, then ⌘V in the target app to paste them one by one.",
        "zh-Hans": "⇧⌘C 在右侧打开队列。复制多项后，在目标应用中按 ⌘V 逐一粘贴。",
        "ja": "⇧⌘C で右にキューを開く。複数コピー後、対象アプリで ⌘V を押して順にペースト。",
    },
    "onboarding.step.copy": {"en": "Copy", "zh-Hans": "复制", "ja": "コピー"},
    "onboarding.step.saved": {"en": "Saved", "zh-Hans": "已保存", "ja": "保存済み"},
    "onboarding.step.open": {"en": "Open", "zh-Hans": "打开", "ja": "開く"},
    "onboarding.step.doubleClick": {"en": "Double-click", "zh-Hans": "双击", "ja": "ダブルクリック"},
    "onboarding.step.paste": {"en": "Paste", "zh-Hans": "粘贴", "ja": "ペースト"},
    "onboarding.step.plain": {"en": "Plain", "zh-Hans": "纯文本", "ja": "プレーン"},
    "onboarding.step.space": {"en": "Space", "zh-Hans": "空格", "ja": "スペース"},
    "onboarding.step.preview": {"en": "Preview", "zh-Hans": "预览", "ja": "プレビュー"},
    "onboarding.step.edit": {"en": "Edit", "zh-Hans": "编辑", "ja": "編集"},
    "onboarding.step.cmdClick": {"en": "⌘-click", "zh-Hans": "⌘-点击", "ja": "⌘-クリック"},
    "onboarding.step.order": {"en": "Order", "zh-Hans": "顺序", "ja": "順序"},
    "onboarding.step.return": {"en": "Return", "zh-Hans": "Return", "ja": "Return"},
    "onboarding.demo.next": {"en": "NEXT", "zh-Hans": "下一步", "ja": "次へ"},
    "onboarding.demo.clickToEdit": {"en": "Click to edit", "zh-Hans": "点击编辑", "ja": "クリックして編集"},
    "onboarding.demo.copyToCollect": {"en": "Copy to collect", "zh-Hans": "复制以收集", "ja": "コピーして収集"},
    "onboarding.demo.doubleClick": {"en": "Double-click", "zh-Hans": "双击", "ja": "ダブルクリック"},
    # Misc
    "common.cancel": {"en": "Cancel", "zh-Hans": "取消", "ja": "キャンセル"},
    "common.delete": {"en": "Delete", "zh-Hans": "删除", "ja": "削除"},
    "common.create": {"en": "Create", "zh-Hans": "创建", "ja": "作成"},
}


# Product experience: primary actions, permission recovery, and removal undo.
STRINGS.update({
    "removal.undoShort": {
        "en": "Undo",
        "zh-Hans": "撤销",
        "ja": "取り消す"
    },
    "removal.namedFolder": {
        "en": "Remove from “%@”",
        "zh-Hans": "从「%@」移除",
        "ja": "「%@」から取り除く"
    },
    "removal.removedFolder": {
        "en": "Removed from “%@”",
        "zh-Hans": "已从「%@」移除",
        "ja": "「%@」から取り除きました"
    },
    "removal.removedHistory": {
        "en": "Removed from History",
        "zh-Hans": "已从历史移除",
        "ja": "履歴から取り除きました"
    },
    "removal.unpinned": {
        "en": "Unpinned",
        "zh-Hans": "已取消置顶",
        "ja": "ピン留めを解除しました"
    },
    "removal.restored": {
        "en": "Removal undone",
        "zh-Hans": "已撤销移除",
        "ja": "取り除きを取り消しました"
    }
})

STRINGS.update({
    "action.paste": {
        "en": "Direct Paste",
        "zh-Hans": "直接粘贴",
        "ja": "直接ペースト"
    },
    "action.copyOnly": {
        "en": "Copy Only",
        "zh-Hans": "仅复制",
        "ja": "コピーのみ"
    },
    "action.cannotEdit": {
        "en": "Editing is not available for this clip",
        "zh-Hans": "此剪贴项不支持编辑",
        "ja": "この項目は編集できません"
    },
    "removal.everywhere": {
        "en": "Delete Everywhere",
        "zh-Hans": "从所有位置删除",
        "ja": "すべての場所から削除"
    },
    "removal.everywhereDetail": {
        "en": "Delete this clip from history, Pinned, and all folders? This cannot be undone.",
        "zh-Hans": "从历史、置顶和所有文件夹中删除此项？此操作无法撤销。",
        "ja": "履歴、ピン留め、すべてのフォルダからこの項目を削除しますか？取り消しできません。"
    },
    "action.dismiss": {
        "en": "Dismiss message",
        "zh-Hans": "关闭提示",
        "ja": "メッセージを閉じる"
    },
    "action.retry": {
        "en": "Retry",
        "zh-Hans": "重试",
        "ja": "再試行"
    },
    "action.returnToApp": {
        "en": "Return to App",
        "zh-Hans": "返回目标应用",
        "ja": "アプリに戻る"
    },
    "action.selectionCount": {
        "en": "%lld selected",
        "zh-Hans": "已选 %lld 项",
        "ja": "%lld 件選択"
    },
    "removal.undo": {
        "en": "Undo Removal",
        "zh-Hans": "撤销移除",
        "ja": "取り除きを取り消す"
    },
    "removal.undoHelp": {
        "en": "Undo recent removals for 30 seconds (⌘Z).",
        "zh-Hans": "30 秒内可撤销最近的移除（⌘Z）。",
        "ja": "30秒以内の取り除きを取り消します（⌘Z）。"
    },
    "action.enablePaste": {
        "en": "Enable Direct Paste",
        "zh-Hans": "启用直接粘贴",
        "ja": "直接ペーストを有効にする"
    },
    "removal.stillSaved": {
        "en": "Removed from History; still saved in Pinned or folders",
        "zh-Hans": "已从历史移除，仍保存在置顶或文件夹中",
        "ja": "履歴から取り除きました。ピン留めまたはフォルダには残っています"
    },
    "removal.history": {
        "en": "Remove from History",
        "zh-Hans": "从历史移除",
        "ja": "履歴から取り除く"
    },
    "action.copySingle": {
        "en": "Select one clip to copy. Use ⇧Return to paste multiple clips as plain text.",
        "zh-Hans": "请选择一项进行复制。多项可用 ⇧Return 按纯文本粘贴。",
        "ja": "コピーする項目を1つ選択してください。複数項目は ⇧Return でプレーンテキストとしてペーストできます。"
    },
    "action.writeFailed": {
        "en": "Could not copy this clip. Its content or attachment may be unavailable. Restore the file, then retry.",
        "zh-Hans": "无法复制此项，内容或附件可能不可用。请恢复文件后重试。",
        "ja": "内容または添付ファイルを利用できないためコピーできませんでした。ファイルを復元して再試行してください。"
    },
    "action.copiedManual": {
        "en": "Copied. Return to your app and press ⌘V. Enable Accessibility for direct paste.",
        "zh-Hans": "已复制。返回目标应用后按 ⌘V。开启辅助功能即可直接粘贴。",
        "ja": "コピーしました。対象アプリに戻って ⌘V を押してください。直接ペーストにはアクセシビリティを許可してください。"
    },
    "action.copied": {
        "en": "Copied to Clipboard",
        "zh-Hans": "已复制到剪贴板",
        "ja": "クリップボードにコピーしました"
    },
    "action.multiPermission": {
        "en": "Enable Accessibility to paste multiple clips, or select one clip to copy manually.",
        "zh-Hans": "请启用辅助功能以粘贴多项，或选择一项复制后手动粘贴。",
        "ja": "複数項目のペーストにはアクセシビリティを許可するか、1項目を選んで手動でコピー・ペーストしてください。"
    },
    "action.focusChanged": {
        "en": "Paste stopped because the destination or permission changed. Focus your destination and try the remaining clips again.",
        "zh-Hans": "目标应用或权限已变化，粘贴已停止。请聚焦目标位置后重试剩余项。",
        "ja": "対象アプリまたは権限が変わったため停止しました。対象にフォーカスして残りの項目を再試行してください。"
    },
    "action.pasteSent": {
        "en": "Paste request sent",
        "zh-Hans": "已发送粘贴请求",
        "ja": "ペースト要求を送信しました"
    },
    "removal.confirmTitle": {
        "en": "Review History Cleanup",
        "zh-Hans": "确认历史清理范围",
        "ja": "履歴の整理内容を確認"
    },
    "removal.confirmCount": {
        "en": "%lld clips will be permanently deleted. This cannot be undone and ends removal undo.",
        "zh-Hans": "将永久删除 %lld 项。此操作无法撤销，并会结束之前的移除撤销。",
        "ja": "%lld 件を完全に削除します。この操作と以前の項目の削除を取り消せなくなります。"
    },
    "removal.keepSaved": {
        "en": "Pinned clips and clips in folders will be kept.",
        "zh-Hans": "置顶和文件夹中的内容将保留。",
        "ja": "ピン留めとフォルダ内の項目は保持されます。"
    },
    "removal.includeSaved": {
        "en": "This includes Pinned and every folder. The folders themselves will remain.",
        "zh-Hans": "包括置顶和所有文件夹中的内容，文件夹本身将保留。",
        "ja": "ピン留めとすべてのフォルダ内の項目を含みます。フォルダ自体は保持されます。"
    },
    "removal.newRetention": {
        "en": "New retention period: %@",
        "zh-Hans": "新的保留期限：%@",
        "ja": "新しい保存期間：%@"
    },
    "removal.confirmDelete": {
        "en": "Delete Reviewed Clips",
        "zh-Hans": "删除已确认的记录",
        "ja": "確認した項目を削除"
    },
    "removal.failedTitle": {
        "en": "History Was Not Changed",
        "zh-Hans": "历史记录未更改",
        "ja": "履歴は変更されませんでした"
    },
    "action.setting": {
        "en": "Timeline primary action",
        "zh-Hans": "时间线主要操作",
        "ja": "タイムラインの主操作"
    },
    "action.settingDetail": {
        "en": "Double-click, Return, and ⌘1–9 use the selected action. Direct Paste is the default. ⇧Return always pastes plain text.",
        "zh-Hans": "双击、Return 和 ⌘1–9 统一执行所选操作，默认直接粘贴。⇧Return 始终按纯文本粘贴。",
        "ja": "ダブルクリック・Return・⌘1–9は選択した操作を実行します。既定は直接ペーストです。⇧Returnは常にプレーンテキストでペーストします。"
    },
    "removal.clearKeepSaved": {
        "en": "Clear History, Keep Pinned & Folders…",
        "zh-Hans": "清空历史，保留置顶和文件夹…",
        "ja": "履歴を消去し、ピン留めとフォルダを保持…"
    },
    "action.permissionReady": {
        "en": "Direct paste is enabled",
        "zh-Hans": "已启用直接粘贴",
        "ja": "直接ペーストは有効です"
    },
    "action.permissionNeeded": {
        "en": "Direct paste needs Accessibility",
        "zh-Hans": "直接粘贴需要辅助功能权限",
        "ja": "直接ペーストにはアクセシビリティが必要です"
    },
    "action.permissionDetail": {
        "en": "Accessibility lets Pastel it！ send ⌘V to your destination app. You can still copy clips and paste them manually without granting access.",
        "zh-Hans": "辅助功能允许 Pastel it！ 向目标应用发送 ⌘V。未授权也可以复制内容后手动粘贴。",
        "ja": "アクセシビリティを許可すると対象アプリに ⌘V を送信できます。許可しなくてもコピーして手動でペーストできます。"
    },
    "removal.saveFailed": {
        "en": "Could not save the change. Your history has been restored; try again.",
        "zh-Hans": "无法保存更改，已恢复历史记录，请重试。",
        "ja": "変更を保存できませんでした。履歴を復元しました。再試行してください。"
    },
    "action.tutorial": {
        "en": "Select a clip, ⌘C to copy, then ⌘V in your app. Choose Direct Paste in Settings for one-step reuse.",
        "zh-Hans": "选中一项，按 ⌘C 复制，再到目标应用按 ⌘V。可在设置中选择直接粘贴以一步完成。",
        "ja": "項目を選んで ⌘C でコピーし、対象アプリで ⌘V。設定で直接ペーストを選ぶと一度の操作で再利用できます。"
    }
})


def escape_strings_value(value: str) -> str:
    return value.replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n")


def write_strings_files(strings: dict[str, dict[str, str]], out_dir: Path) -> None:
    for lang in SUPPORTED_LANGS:
        lproj = out_dir / f"{lang}.lproj"
        lproj.mkdir(parents=True, exist_ok=True)
        lines = []
        for key, locs in sorted(strings.items()):
            value = locs.get(lang, locs["en"])
            lines.append(f'"{escape_strings_value(key)}" = "{escape_strings_value(value)}";')
        (lproj / "Localizable.strings").write_text("\n".join(lines) + "\n", encoding="utf-8")


def build_catalog(strings: dict[str, dict[str, str]]) -> dict:
    catalog_strings: dict = {}
    for key, locs in strings.items():
        entry: dict = {
            "localizations": {
                lang: {
                    "stringUnit": {
                        "state": "translated",
                        "value": value,
                    }
                }
                for lang, value in locs.items()
            }
        }
        catalog_strings[key] = entry
    return {
        "sourceLanguage": "en",
        "strings": catalog_strings,
        "version": "1.0",
    }


# Native settings navigation and grouped forms.
STRINGS.update({
    "settings.windowTitle": {
        "en": "Pastel it！ Settings",
        "zh-Hans": "Pastel it！ 设置",
        "ja": "Pastel it！ 設定"
    },
    "settings.sidebar.clipboard": {"en": "Clipboard", "zh-Hans": "剪贴板", "ja": "クリップボード"},
    "settings.tab.clipboard": {
        "en": "Clipboard & History",
        "zh-Hans": "剪贴板与历史",
        "ja": "クリップボードと履歴"
    },
    "settings.group.startup": {
        "en": "Startup",
        "zh-Hans": "启动",
        "ja": "起動"
    },
    "settings.group.pasting": {
        "en": "Pasting",
        "zh-Hans": "粘贴行为",
        "ja": "ペースト"
    },
    "settings.group.shortcuts": {
        "en": "Keyboard Shortcuts",
        "zh-Hans": "键盘快捷键",
        "ja": "キーボードショートカット"
    },
    "settings.group.capture": {
        "en": "Capture",
        "zh-Hans": "剪贴板采集",
        "ja": "キャプチャ"
    },
    "settings.group.history": {
        "en": "History",
        "zh-Hans": "历史记录",
        "ja": "履歴"
    },
    "settings.group.advanced": {
        "en": "Advanced",
        "zh-Hans": "高级设置",
        "ja": "詳細設定"
    },
    "settings.group.permissions": {
        "en": "System Permissions",
        "zh-Hans": "系统权限",
        "ja": "システム権限"
    },
    "settings.group.cleanup": {
        "en": "History Cleanup",
        "zh-Hans": "清理历史",
        "ja": "履歴の削除"
    },
    "settings.group.updates": {
        "en": "Updates",
        "zh-Hans": "应用更新",
        "ja": "アップデート"
    },
    "settings.automaticallyCheckUpdates": {
        "en": "Automatically check for updates",
        "zh-Hans": "自动检查更新",
        "ja": "アップデートを自動的に確認"
    },
    "settings.automaticallyDownloadUpdates": {
        "en": "Automatically download updates",
        "zh-Hans": "自动下载更新",
        "ja": "アップデートを自動的にダウンロード"
    },
    "settings.automaticUpdatesHelp": {
        "en": "Updates download in the background. When an update is ready, you’ll be asked to restart Pastel it！. You can also install when you quit.",
        "zh-Hans": "更新会在后台下载，准备就绪后提示重启 Pastel it！。你也可以选择退出时安装。",
        "ja": "アップデートはバックグラウンドでダウンロードされ、準備ができると Pastel it！ の再起動を求める通知が表示されます。アプリの終了時にインストールすることもできます。"
    },
    "settings.group.help": {
        "en": "Help",
        "zh-Hans": "帮助",
        "ja": "ヘルプ"
    }
})


# Local settings and permission improvements.
STRINGS.update({
    "shortcuts.invalid": {
        "en": "Use a key with Command, Control, or Option. Standard editing and app commands are reserved.",
        "zh-Hans": "请使用 Command、Control 或 Option 加其他按键；常用编辑与应用快捷键不能覆盖。"
    },
    "shortcuts.duplicate": {
        "en": "This shortcut is already assigned to another action.",
        "zh-Hans": "此快捷键已用于其他操作，请换一个组合。"
    },
    "shortcuts.unavailable": {
        "en": "macOS could not register this shortcut. It may be in use. Your previous shortcuts were kept.",
        "zh-Hans": "macOS 无法注册此快捷键，可能已被占用。已保留原快捷键。"
    },
    "shortcuts.registrationFailed": {
        "en": "Some shortcuts could not be registered. Choose another combination; all actions remain available from the menu.",
        "zh-Hans": "部分快捷键注册失败，请更换组合。仍可从菜单使用所有功能。"
    },
    "shortcuts.edit": {
        "en": "Click to change this shortcut",
        "zh-Hans": "点击修改快捷键"
    },
    "shortcuts.reset": {
        "en": "Reset All Shortcuts to Defaults",
        "zh-Hans": "恢复所有默认快捷键"
    },
    "shortcuts.help": {
        "en": "Click a shortcut, then press a new combination. Changes take effect immediately and are saved on this Mac.",
        "zh-Hans": "点击快捷键后按下新的组合，修改立即生效，并会在重启后保留。"
    },
    "shortcuts.recordTitle": {
        "en": "Change Shortcut",
        "zh-Hans": "修改快捷键"
    },
    "shortcuts.recordHelp": {
        "en": "Press a key with Command, Control, or Option. Press Backspace to clear, or Escape to cancel.",
        "zh-Hans": "按下 Command、Control 或 Option 加其他按键。按退格键清除，按 Esc 取消。"
    },
    "shortcuts.listening": {
        "en": "Waiting for shortcut…",
        "zh-Hans": "请按下新的快捷键…"
    },
    "shortcuts.plainFootnote": {
        "en": "The plain-text shortcut pastes once without formatting, then restores the original clipboard (Accessibility required). In the timeline, ⇧↩ pastes the selection as plain text.",
        "zh-Hans": "纯文本快捷键会按无格式文本粘贴一次，再还原原始剪贴板（需要辅助功能权限）。时间线中按 ⇧↩ 可粘贴所选纯文本。"
    },
    "shortcuts.stackFootnote": {
        "en": "The Paste Stack shortcut opens or closes the queue. While it has items, ⌘V in any app pastes the next one (Accessibility required).",
        "zh-Hans": "队列快捷键用于打开或关闭粘贴队列。有待粘贴内容时，在目标应用按 ⌘V 可依次粘贴（需要辅助功能权限）。"
    },
    "shortcuts.stackTutorial": {
        "en": "%@ opens a queue on the right. Copy several things, then ⌘V in the target app to paste them one by one.",
        "zh-Hans": "%@ 打开右侧队列。连续复制多项后，在目标应用按 ⌘V 逐个粘贴。"
    },
    "permissions.restartTitle": {
        "en": "Restart Pastel it！ After Granting Access",
        "zh-Hans": "授权完成，请重启 Pastel it！"
    },
    "permissions.restartDetail": {
        "en": "Accessibility permission is now enabled. Please quit and reopen Pastel it！ so automatic pasting and Paste Stack can use the updated permission. Your clipboard history will be kept.",
        "zh-Hans": "辅助功能权限已开启。请退出并重新打开 Pastel it！，让自动粘贴和队列监听使用新权限。剪贴板历史会保留。"
    },
    "permissions.restartHint": {
        "en": "Permission updated. Quit and reopen Pastel it！ to finish applying it.",
        "zh-Hans": "权限已更新，请退出并重新打开 Pastel it！，使新权限完整生效。"
    },
    "permissions.understood": {
        "en": "Got It",
        "zh-Hans": "知道了"
    }
})


STRINGS.update({
    "shortcuts.unassigned": {
        "en": "Not assigned",
        "zh-Hans": "未设置"
    },
    "shortcuts.stackTutorialWithoutBinding": {
        "en": "Open Paste Stack from the menu. Copy several things, then ⌘V in the target app to paste them one by one.",
        "zh-Hans": "从菜单打开粘贴队列。连续复制多项后，在目标应用按 ⌘V 逐个粘贴。"
    }
})


# OCR preferences, quick paste, and copy-time navigation.
STRINGS.update({
    "settings.tab.ocr": {
        "en": "OCR",
        "zh-Hans": "OCR 与快捷粘贴"
    },
    "ocr.recognition": {
        "en": "Image Recognition",
        "zh-Hans": "图片文字识别"
    },
    "ocr.enabled": {
        "en": "Enable OCR",
        "zh-Hans": "启用 OCR"
    },
    "ocr.enabledHelp": {
        "en": "Recognize new images in the background. Existing results are kept when OCR is off. Re-run an image to apply changed settings.",
        "zh-Hans": "在后台识别新图片。关闭 OCR 不会删除已有结果；修改参数后，可对图片点击 Re-run 重新识别。"
    },
    "ocr.tables": {
        "en": "Recognize tables",
        "zh-Hans": "识别表格"
    },
    "ocr.tablesHelp": {
        "en": "On macOS 26 or later, output detected tables as Markdown and keep surrounding text.",
        "zh-Hans": "macOS 26 及以上可将检测到的表格输出为 Markdown，并保留表格前后的文字。"
    },
    "ocr.automaticLanguage": {
        "en": "Detect languages automatically",
        "zh-Hans": "自动检测语言"
    },
    "ocr.accuracy": {
        "en": "Recognition mode",
        "zh-Hans": "识别模式"
    },
    "ocr.accurate": {
        "en": "Accurate",
        "zh-Hans": "精确"
    },
    "ocr.fast": {
        "en": "Fast",
        "zh-Hans": "快速"
    },
    "ocr.correction": {
        "en": "Language correction",
        "zh-Hans": "语言纠错"
    },
    "ocr.minimumHeight": {
        "en": "Minimum text height",
        "zh-Hans": "最小文字高度"
    },
    "ocr.parametersHelp": {
        "en": "Text height is a fraction of image height; 0% keeps small text. Fast mode supports fewer languages; selected languages use accurate mode when needed. Document table detection uses its own system model.",
        "zh-Hans": "按图片高度的比例过滤文字；0% 保留小字。快速模式支持的语言较少，必要时为指定语言使用精确模式；表格检测使用独立的系统模型。"
    },
    "ocr.reset": {
        "en": "Reset OCR Settings",
        "zh-Hans": "恢复 OCR 默认设置"
    },
    "quickPaste.title": {
        "en": "Quick Paste",
        "zh-Hans": "快捷粘贴"
    },
    "quickPaste.enabled": {
        "en": "Enable quick paste",
        "zh-Hans": "启用快捷粘贴"
    },
    "quickPaste.help": {
        "en": "Convert the current system clipboard to plain text and paste it. This shortcut is separate from Open Paste. The default is ⇧⌘V; change either shortcut if they conflict.",
        "zh-Hans": "将当前系统剪贴板内容转为纯文本并粘贴。与打开剪贴板使用独立快捷键，默认 ⇧⌘V；如有冲突，请修改其中一个快捷键。"
    },
    "quickPaste.text": {
        "en": "Text → plain text",
        "zh-Hans": "文字 → 纯文本"
    },
    "quickPaste.images": {
        "en": "Images → OCR text",
        "zh-Hans": "图片 → OCR 文字"
    },
    "quickPaste.files": {
        "en": "Files → file names",
        "zh-Hans": "文件 → 文件名"
    },
    "quickPaste.scopeHelp": {
        "en": "Only selected types are converted. Images follow the OCR settings above. Without Accessibility, plain text is prepared for manual ⌘V. Automatic pasting restores the original clipboard unless you copy something newer.",
        "zh-Hans": "仅转换勾选的类型。图片遵循上方 OCR 设置；无辅助功能权限时，先准备纯文本，再手动按 ⌘V。自动粘贴后恢复原剪贴板；期间复制了新内容则保留新内容。"
    },
    "quickPaste.emptyScope": {
        "en": "Select at least one content type to use quick paste.",
        "zh-Hans": "请至少选择一种需要转换的类型。"
    },
    "quickPaste.noContent": {
        "en": "No enabled content to convert; clipboard unchanged",
        "zh-Hans": "没有可转换的已选类型，剪贴板保持不变"
    },
    "quickPaste.changed": {
        "en": "Clipboard or destination changed; quick paste cancelled",
        "zh-Hans": "剪贴板或目标应用已变化，已取消快捷粘贴"
    },
    "quickPaste.manual": {
        "en": "Plain text ready. Press ⌘V, or enable Accessibility for automatic pasting.",
        "zh-Hans": "纯文本已准备好。请按 ⌘V，或开启辅助功能以自动粘贴。"
    },
    "quickPaste.done": {
        "en": "Pasted as plain text",
        "zh-Hans": "已粘贴为纯文本"
    },
    "timeline.timeRuler": {
        "en": "Copy time navigation",
        "zh-Hans": "复制时间轴"
    },
    "timeline.timeRulerHelp": {
        "en": "Hover to magnify copy time. Click or drag to jump to the nearest visible clip.",
        "zh-Hans": "悬停放大查看复制时间；点击或拖动，跳转到当前筛选结果中最接近该时间的记录。"
    }
})


STRINGS.update({"settings.privateUpdates": {"en": "Automatic updates are not configured for this private derivative. Get builds from your own repository.", "zh-Hans": "此私人派生版尚未配置自动更新，请从自己的项目仓库获取构建。"}})

STRINGS["menu.statusTooltip"].update({"en": "Pastel it！ — Clipboard history", "zh-Hans": "Pastel it！ — 剪贴板历史", "ja": "Pastel it！ — クリップボード履歴"})


# Native UI simplification and active shortcut wording.
STRINGS.update({
    "shortcuts.timelineFootnote": {
        "en": "Open clipboard history with ⇧⌘C. Configure Quick Paste separately in OCR & Quick Paste.",
        "zh-Hans": "⇧⌘C 打开剪贴板；快捷粘贴在“OCR 与快捷粘贴”中单独设置。",
        "ja": "⇧⌘Cで履歴を開きます。クイックペーストはOCR設定で変更できます。"
    },
    "ocr.languages": {
        "en": "Languages",
        "zh-Hans": "识别语言",
        "ja": "認識言語"
    },
    "shortcuts.binding": {
        "en": "Keyboard Shortcut",
        "zh-Hans": "快捷键",
        "ja": "キーボードショートカット"
    },
    "timeline.folders": {
        "en": "Collections",
        "zh-Hans": "收藏分类",
        "ja": "コレクション"
    },
    "quickPaste.help": {
        "en": "Convert the current system clipboard to plain text and paste it. Default: ⇧⌘V. Open clipboard history separately with ⇧⌘C.",
        "zh-Hans": "将当前系统剪贴板转换为纯文本并粘贴，默认 ⇧⌘V。打开剪贴板的默认快捷键为 ⇧⌘C。",
        "ja": "システムクリップボードをプレーンテキストに変換してペーストします（⇧⌘V）。履歴を開く既定キーは⇧⌘Cです。"
    },
    "action.settingDetail": {
        "en": "Double-click, Return, and ⌘1–9 use the selected action. Direct Paste is the default.",
        "zh-Hans": "双击、Return 和 ⌘1–9 统一执行所选操作，默认直接粘贴。",
        "ja": "ダブルクリック、Return、⌘1–9は選択した操作を実行します。既定は直接ペーストです。"
    },
    "action.copySingle": {
        "en": "Select one clip to copy, or press Return to paste the selected clips in order.",
        "zh-Hans": "请选择一项复制，或按 Return 按顺序粘贴所选项目。",
        "ja": "コピーする項目を1つ選択するか、Returnで選択項目を順にペーストします。"
    },
    "onboarding.paste.caption": {
        "en": "⇧⌘C opens history. Select a clip, then copy or paste it.",
        "zh-Hans": "⇧⌘C 打开剪贴板，选中记录后复制或直接粘贴。",
        "ja": "⇧⌘Cで履歴を開き、項目をコピーまたはペーストします。"
    }
})

# Accessible label for the native image/text preview picker.
STRINGS.update({
    "preview.content": {
        "en": "Preview content",
        "zh-Hans": "预览内容",
        "ja": "プレビュー内容"
    }
})

# Settings sidebar and onboarding native layout refinement.
STRINGS.update({
    "settings.sidebar.ocr": {
        "en": "OCR",
        "zh-Hans": "OCR",
        "ja": "OCR"
    },
    "onboarding.skip": {
        "en": "Skip",
        "zh-Hans": "跳过",
        "ja": "スキップ"
    },
    "onboarding.back": {
        "en": "Back",
        "zh-Hans": "上一步",
        "ja": "戻る"
    },
    "onboarding.continue": {
        "en": "Continue",
        "zh-Hans": "继续",
        "ja": "続ける"
    },
    "onboarding.done": {
        "en": "Done",
        "zh-Hans": "完成",
        "ja": "完了"
    },
    "onboarding.getStarted": {
        "en": "Get Started",
        "zh-Hans": "开始使用",
        "ja": "使い始める"
    }
})

# Clipboard candidate-bar presentation.
STRINGS.update({
    "settings.group.displayStyle": {
        "en": "Display Style",
        "zh-Hans": "显示样式",
        "ja": "表示スタイル"
    },
    "clipboard.style.picker": {
        "en": "Presentation",
        "zh-Hans": "展示方式",
        "ja": "表示方法"
    },
    "clipboard.style.timeline": {
        "en": "Timeline",
        "zh-Hans": "时间轴",
        "ja": "タイムライン"
    },
    "clipboard.style.candidateBar": {
        "en": "Candidate Bar",
        "zh-Hans": "候选栏",
        "ja": "候補バー"
    },
    "clipboard.style.help": {
        "en": "Choose a timeline or a compact bar of recent clips. Open either with your clipboard shortcut.",
        "zh-Hans": "选择时间轴或最近记录候选栏，均使用“打开剪贴板”快捷键。",
        "ja": "タイムラインまたは最近の項目の候補バーを選べます。どちらも履歴のショートカットで開きます。"
    },
    "candidateBar.collapse": {
        "en": "Show less",
        "zh-Hans": "收起",
        "ja": "折りたたむ"
    },
    "candidateBar.expand": {
        "en": "Show more",
        "zh-Hans": "展开更多",
        "ja": "さらに表示"
    },
    "candidateBar.close": {
        "en": "Close",
        "zh-Hans": "关闭",
        "ja": "閉じる"
    },
    "candidateBar.empty": {
        "en": "No Recent Clips",
        "zh-Hans": "暂无剪贴板记录",
        "ja": "最近の項目はありません"
    },
    "candidateBar.emptyDetail": {
        "en": "Copy text, images, or files and they will appear here.",
        "zh-Hans": "复制文字、图片或文件后，即会显示在这里。",
        "ja": "テキスト、画像、ファイルをコピーするとここに表示されます。"
    },
    "candidateBar.locationFallback": {
        "en": "Caret position unavailable. Showing near the pointer; Accessibility may be required.",
        "zh-Hans": "未能获取插入光标位置，暂在鼠标旁显示；请检查辅助功能权限。",
        "zh-Hant": "無法取得插入游標位置，暫在滑鼠旁顯示；請檢查輔助使用權限。",
        "ja": "カーソル位置を取得できないため、ポインタ付近に表示します。アクセシビリティ権限をご確認ください。",
        "ko": "텍스트 커서 위치를 가져올 수 없어 포인터 근처에 표시합니다. 손쉬운 사용 권한을 확인하세요.",
        "de": "Cursorposition nicht verfügbar. Anzeige am Mauszeiger; Bedienungshilfen prüfen.",
        "fr": "Position du curseur indisponible. Affichage près du pointeur ; vérifiez l’accessibilité.",
        "es": "Posición del cursor no disponible. Se muestra junto al puntero; comprueba Accesibilidad.",
        "pl": "Pozycja kursora niedostępna. Wyświetlanie przy wskaźniku; sprawdź dostępność.",
    },
    "candidateBar.footer": {
        "en": "1–5 to select · Tab to expand or collapse",
        "zh-Hans": "1–5 选择 · Tab 展开或收起",
        "ja": "1–5で選択 · Tabで展開／折りたたみ"
    },
    "candidateBar.moreFiles": {
        "en": "+%lld more",
        "zh-Hans": "另 %lld 个",
        "ja": "ほか%lld件"
    },
    "candidateBar.noPreview": {
        "en": "No Preview",
        "zh-Hans": "无法预览",
        "ja": "プレビューできません"
    },
    "candidateBar.fileCount": {
        "en": "%lld files",
        "zh-Hans": "%lld 个文件",
        "ja": "%lld件のファイル"
    },
    "candidateBar.emptyText": {
        "en": "Empty",
        "zh-Hans": "空内容",
        "ja": "空"
    }
})

# Vertical candidate pages and native settings (2026-10-28).
STRINGS.update({
    "settings.group.app": {
        "en": "App",
        "zh-Hans": "应用",
        "zh-Hant": "應用程式",
        "ja": "アプリ",
        "ko": "앱",
        "fr": "Application",
        "de": "App",
        "es": "Aplicación",
        "pl": "Aplikacja"
    },
    "settings.group.data": {
        "en": "Data",
        "zh-Hans": "数据",
        "zh-Hant": "資料",
        "ja": "データ",
        "ko": "데이터",
        "fr": "Données",
        "de": "Daten",
        "es": "Datos",
        "pl": "Dane"
    },
    "settings.tab.quickPaste": {
        "en": "Quick Paste",
        "zh-Hans": "快捷粘贴",
        "zh-Hant": "快速貼上",
        "ja": "クイックペースト",
        "ko": "빠른 붙여넣기",
        "fr": "Collage rapide",
        "de": "Schnelles Einfügen",
        "es": "Pegado rápido",
        "pl": "Szybkie wklejanie"
    },
    "clipboard.style.previewTimeline": {
        "en": "Cards along the bottom of the screen.",
        "zh-Hans": "在屏幕底部横向浏览卡片。",
        "zh-Hant": "在螢幕底部橫向瀏覽卡片。",
        "ja": "画面下部でカードを横に閲覧。",
        "ko": "화면 아래에서 카드를 가로로 탐색합니다.",
        "fr": "Des cartes en bas de l’écran.",
        "de": "Karten am unteren Bildschirmrand.",
        "es": "Tarjetas en la parte inferior de la pantalla.",
        "pl": "Karty u dołu ekranu."
    },
    "clipboard.style.previewCandidate": {
        "en": "A compact list next to your text cursor.",
        "zh-Hans": "在输入光标旁显示纵向列表。",
        "zh-Hant": "在文字游標旁顯示直向清單。",
        "ja": "文字カーソルの横に縦リストを表示。",
        "ko": "텍스트 커서 옆에 세로 목록을 표시합니다.",
        "fr": "Une liste près du curseur de texte.",
        "de": "Eine Liste neben dem Textcursor.",
        "es": "Una lista junto al cursor de texto.",
        "pl": "Lista przy kursorze tekstowym."
    },
    "candidatePlacement.title": {
        "en": "Candidate Position",
        "zh-Hans": "候选栏定位",
        "zh-Hant": "候選列定位",
        "ja": "候補の位置",
        "ko": "후보 위치",
        "fr": "Position des candidats",
        "de": "Position der Kandidaten",
        "es": "Posición de candidatos",
        "pl": "Pozycja kandydatów"
    },
    "candidatePlacement.status": {
        "en": "Accessibility",
        "zh-Hans": "辅助功能",
        "zh-Hant": "輔助使用",
        "ja": "アクセシビリティ",
        "ko": "손쉬운 사용",
        "fr": "Accessibilité",
        "de": "Bedienungshilfen",
        "es": "Accesibilidad",
        "pl": "Dostępność"
    },
    "candidatePlacement.granted": {
        "en": "Granted",
        "zh-Hans": "已授权",
        "zh-Hant": "已授權",
        "ja": "許可済み",
        "ko": "허용됨",
        "fr": "Autorisé",
        "de": "Erlaubt",
        "es": "Permitido",
        "pl": "Zezwolono"
    },
    "candidatePlacement.notGranted": {
        "en": "Not granted",
        "zh-Hans": "未授权",
        "zh-Hant": "未授權",
        "ja": "未許可",
        "ko": "허용 안 됨",
        "fr": "Non autorisé",
        "de": "Nicht erlaubt",
        "es": "Sin permiso",
        "pl": "Brak uprawnień"
    },
    "candidatePlacement.request": {
        "en": "Grant Access…",
        "zh-Hans": "获取权限…",
        "zh-Hant": "取得權限…",
        "ja": "権限を許可…",
        "ko": "권한 허용…",
        "fr": "Autoriser…",
        "de": "Zugriff erlauben…",
        "es": "Conceder acceso…",
        "pl": "Przyznaj dostęp…"
    },
    "candidatePlacement.help": {
        "en": "Accessibility lets Pastel it！ place the candidate bar next to your text cursor. Without it, the bar appears near the mouse pointer instead.",
        "zh-Hans": "授权后可在输入光标旁显示候选列表；无法定位时在鼠标旁显示。",
        "zh-Hant": "授權後可在文字游標旁顯示候選清單；無法定位時在滑鼠旁顯示。",
        "ja": "権限を許可すると文字カーソル付近に表示します。位置を取得できない場合はポインタ付近に表示します。",
        "ko": "권한을 허용하면 텍스트 커서 옆에 표시합니다. 위치를 확인할 수 없으면 포인터 근처에 표시합니다.",
        "fr": "L’accessibilité permet un affichage près du curseur de texte, sinon près du pointeur.",
        "de": "Mit Bedienungshilfen erscheint die Liste am Textcursor, andernfalls am Mauszeiger.",
        "es": "Accesibilidad permite mostrar la lista junto al cursor; si no está disponible, junto al puntero.",
        "pl": "Dostępność pozwala wyświetlać listę przy kursorze tekstowym, a w razie braku pozycji przy wskaźniku."
    },
    "candidateBar.page": {
        "en": "%lld/%lld",
        "zh-Hans": "%lld/%lld",
        "zh-Hant": "%lld/%lld",
        "ja": "%lld/%lld",
        "ko": "%lld/%lld",
        "fr": "%lld/%lld",
        "de": "%lld/%lld",
        "es": "%lld/%lld",
        "pl": "%lld/%lld"
    },
    "candidateBar.previousPage": {
        "en": "Previous page",
        "zh-Hans": "上一页",
        "zh-Hant": "上一頁",
        "ja": "前のページ",
        "ko": "이전 페이지",
        "fr": "Page précédente",
        "de": "Vorherige Seite",
        "es": "Página anterior",
        "pl": "Poprzednia strona"
    },
    "candidateBar.nextPage": {
        "en": "Next page",
        "zh-Hans": "下一页",
        "zh-Hant": "下一頁",
        "ja": "次のページ",
        "ko": "다음 페이지",
        "fr": "Page suivante",
        "de": "Nächste Seite",
        "es": "Página siguiente",
        "pl": "Następna strona"
    },
    "settings.tab.ocr": {
        "en": "OCR",
        "zh-Hans": "OCR",
        "zh-Hant": "OCR",
        "ja": "OCR",
        "ko": "OCR",
        "fr": "OCR",
        "de": "OCR",
        "es": "OCR",
        "pl": "OCR"
    },
    "shortcuts.timelineFootnote": {
        "en": "Open clipboard history with ⇧⌘C. Configure Quick Paste separately on the Quick Paste page.",
        "zh-Hans": "⇧⌘C 打开剪贴板；快捷粘贴在独立的“快捷粘贴”栏目中设置。",
        "zh-Hant": "⇧⌘C 開啟剪貼簿；快速貼上可在獨立的「快速貼上」頁面設定。",
        "ja": "⇧⌘Cで履歴を開きます。クイックペーストは専用ページで設定できます。",
        "ko": "⇧⌘C로 기록을 엽니다. 빠른 붙여넣기는 별도 페이지에서 설정하세요.",
        "fr": "⇧⌘C ouvre l’historique. Le collage rapide se configure sur sa propre page.",
        "de": "⇧⌘C öffnet den Verlauf. Schnelles Einfügen hat eine eigene Einstellungsseite.",
        "es": "⇧⌘C abre el historial. El pegado rápido se configura en su propia página.",
        "pl": "⇧⌘C otwiera historię. Szybkie wklejanie ma osobną stronę ustawień."
    },
    "clipboard.style.help": {
        "en": "Tab shows the next 10 clips in Candidate Bar. Both styles use the clipboard shortcut.",
        "zh-Hans": "候选列表每页10条，Tab 翻页；两种样式共用打开快捷键。",
        "zh-Hant": "候選清單每頁10筆，Tab 翻頁；兩種樣式共用開啟快速鍵。",
        "ja": "候補は1ページ10件。Tabで次のページへ進みます。開くショートカットは共通です。",
        "ko": "후보는 페이지당 10개이며 Tab으로 넘깁니다. 같은 단축키로 엽니다.",
        "fr": "10 éléments par page, Tab pour avancer. Le raccourci d’ouverture reste commun.",
        "de": "10 Einträge pro Seite, Tab blättert weiter. Beide Ansichten nutzen denselben Kurzbefehl.",
        "es": "10 elementos por página; Tab avanza. Ambas vistas usan el mismo atajo.",
        "pl": "10 pozycji na stronę; Tab przechodzi dalej. Oba widoki mają ten sam skrót."
    },
    "quickPaste.scopeHelp": {
        "en": "Only selected types are converted. Images follow the OCR settings on the OCR page. Without Accessibility, plain text is prepared for manual ⌘V. Automatic pasting restores the original clipboard unless you copy something newer.",
        "zh-Hans": "仅转换勾选的类型。图片遵循“OCR”栏目的设置；无辅助功能权限时，先准备纯文本，再手动按 ⌘V。自动粘贴后恢复原剪贴板；期间复制了新内容则保留新内容。",
        "zh-Hant": "只轉換勾選的類型。圖片依照「OCR」頁面的設定；未授權輔助使用時，先準備純文字，再手動按 ⌘V。自動貼上後會還原原剪貼簿，除非期間複製了新內容。",
        "ja": "選択した種類のみ変換します。画像はOCRページの設定を使用します。権限がない場合は⌘Vで手動ペーストできます。自動ペースト後は、新しいコピーがない限り元の内容に戻します。",
        "ko": "선택한 유형만 변환합니다. 이미지는 OCR 페이지 설정을 따릅니다. 권한이 없으면 ⌘V로 직접 붙여넣습니다. 새로 복사한 내용이 없으면 자동 붙여넣기 후 원래 클립보드를 복원합니다.",
        "fr": "Seuls les types sélectionnés sont convertis. Les images utilisent la page OCR. Sans accessibilité, collez avec ⌘V. Le presse-papiers est restauré sauf si un nouvel élément a été copié.",
        "de": "Nur ausgewählte Typen werden umgewandelt. Bilder nutzen die OCR-Seite. Ohne Bedienungshilfen manuell mit ⌘V einfügen. Die Zwischenablage wird wiederhergestellt, sofern nichts Neues kopiert wurde.",
        "es": "Solo se convierten los tipos seleccionados. Las imágenes usan la página OCR. Sin Accesibilidad, pega con ⌘V. El portapapeles se restaura salvo que copies algo nuevo.",
        "pl": "Konwertowane są tylko zaznaczone typy. Obrazy korzystają ze strony OCR. Bez Dostępności wklej ręcznie przez ⌘V. Schowek jest przywracany, chyba że skopiowano coś nowego."
    }
})

STRINGS["candidateBar.list"] = {"en": "Clipboard candidates", "zh-Hans": "剪贴板候选列表", "zh-Hant": "剪貼簿候選清單", "ja": "クリップボード候補", "ko": "클립보드 후보", "fr": "Éléments du presse-papiers", "de": "Zwischenablage-Einträge", "es": "Candidatos del portapapeles", "pl": "Pozycje schowka"}

# Candidate row context menu and quick-paste explanation.
STRINGS.update({
    "candidateBar.menu.paste": {
        "en": "Paste",
        "zh-Hans": "粘贴",
        "ja": "ペースト",
    },
    "candidateBar.menu.pastePlain": {
        "en": "Paste as Plain Text",
        "zh-Hans": "快捷粘贴纯文本",
        "ja": "プレーンテキストでペースト",
    },
    "candidateBar.menu.copyPlain": {
        "en": "Copy as Plain Text",
        "zh-Hans": "复制纯文本",
        "ja": "プレーンテキストでコピー",
    },
    "candidateBar.noPlainText": {
        "en": "No text recognized, or the content is unavailable.",
        "zh-Hans": "未识别到文字，或内容不可用。",
        "ja": "テキストを認識できませんでした。コンテンツが利用できない可能性があります。",
    },
    "candidateBar.recognizingImage": {
        "en": "Recognizing text in the image…",
        "zh-Hans": "正在识别图片中的文字…",
        "ja": "画像内のテキストを認識しています…",
    },
    "candidateBar.ocrCancelled": {
        "en": "Recognition was interrupted; the clipboard was left unchanged.",
        "zh-Hans": "识别已中断，剪贴板未更改。",
        "ja": "認識が中断されました。クリップボードは変更されていません。",
    },
    "quickPaste.behavior": {
        "en": "Quick paste removes formatting from copied text and turns images into plain text via OCR, then pastes it straight into the input field. The result depends on the selected content types, OCR settings, and Accessibility permission.",
        "zh-Hans": "快捷粘贴会将复制的文字去除格式、图片经 OCR 转换为纯文本，并直接粘贴到输入框。效果受已选内容类型、OCR 设置与辅助功能权限约束。",
        "ja": "クイックペーストはコピーしたテキストの書式を取り除き、画像はOCRでプレーンテキストに変換して、入力欄へ直接ペーストします。結果は選択した種類・OCR設定・アクセシビリティ権限に依存します。",
    }
})



# Local diagnostics only; no product analytics.
STRINGS.update({
    "privacy.logs.title": {
        "en": "Local Diagnostic Logs",
        "zh-Hans": "本地诊断日志",
        "ja": "ローカル診断ログ"
    },
    "privacy.logs.description": {
        "en": "No usage information is collected or uploaded. Diagnostic logs are stored only on this Mac and never contain clipboard contents.",
        "zh-Hans": "不收集或上传使用信息。诊断日志仅保存在本机，不包含剪贴板内容。",
        "ja": "使用情報の収集・送信は行いません。診断ログはこのMacにのみ保存され、クリップボードの内容を含みません。"
    },
    "privacy.logs.retention": {
        "en": "Logs are kept for at most 14 days, up to about 768 KB.",
        "zh-Hans": "日志最多保留14天，总量不超过约768 KB。",
        "ja": "ログは最大14日間、合計約768 KBまで保存されます。"
    },
    "privacy.logs.summary": {
        "en": "%lld files · %@",
        "zh-Hans": "%lld 个日志文件 · %@",
        "ja": "%lldファイル · %@"
    },
    "privacy.logs.delete": {
        "en": "Delete Past Logs",
        "zh-Hans": "删除过去日志",
        "ja": "過去のログを削除"
    },
    "privacy.logs.confirmTitle": {
        "en": "Delete Past Logs?",
        "zh-Hans": "删除过去日志？",
        "ja": "過去のログを削除しますか？"
    },
    "privacy.logs.confirmMessage": {
        "en": "Only local diagnostic logs will be deleted. Settings, clipboard history, and attachments will be preserved.",
        "zh-Hans": "仅删除本地诊断日志，配置、剪贴板历史和附件都会保留。",
        "ja": "ローカル診断ログのみ削除します。設定、クリップボード履歴、添付ファイルは保持されます。"
    },
    "privacy.logs.deleted": {
        "en": "Deleted %lld past log files.",
        "zh-Hans": "已删除 %lld 个过去日志文件。",
        "ja": "過去のログを%lldファイル削除しました。"
    },
    "privacy.logs.failed": {
        "en": "Could not access the logs. Please try again.",
        "zh-Hans": "无法访问日志，请重试。",
        "ja": "ログにアクセスできません。再試行してください。"
    },
    "privacy.logs.footerScope": {
        "en": "Deleting only removes this app’s local log files. Settings, clipboard history, attachments, and macOS system logs are preserved.",
        "zh-Hans": "仅清理本应用的本地日志，不删除配置、剪贴板历史、附件或 macOS 系统日志。",
        "ja": "このアプリのローカルログのみ削除します。設定、履歴、添付ファイル、macOSシステムログは保持されます。"
    }
})


# Missing interface resource recovery.
STRINGS.update({
    "languageRepair.statusFallback": {
        "en": "Language resources are missing; running in English temporarily.",
        "zh-Hans": "语言资源缺失，暂时使用英文界面。",
        "ja": "言語リソースがないため、一時的に英語で表示しています。"
    },
    "languageRepair.statusOK": {
        "en": "Language Resources",
        "zh-Hans": "语言资源",
        "ja": "言語リソース"
    },
    "languageRepair.download": {
        "en": "Download and Repair",
        "zh-Hans": "下载并修复",
        "ja": "ダウンロードして修復"
    },
    "languageRepair.browser": {
        "en": "Download via GitHub Login",
        "zh-Hans": "登录 GitHub 下载",
        "ja": "GitHubにログインして取得"
    },
    "languageRepair.import": {
        "en": "Install Downloaded Language Pack…",
        "zh-Hans": "安装已下载语言包…",
        "ja": "取得した言語パックをインストール…"
    },
    "languageRepair.missingTitle": {
        "en": "Language Resources Missing / 语言资源缺失",
        "zh-Hans": "语言资源缺失",
        "ja": "言語リソースがありません"
    },
    "languageRepair.missingMessage": {
        "en": "The resources for your selected language are missing. The app will continue running in English. Your settings and history are not affected.",
        "zh-Hans": "界面语言资源缺失，应用将继续使用英文运行。配置和剪贴板历史不受影响。",
        "ja": "言語リソースがありません。英語で引き続き使用できます。設定と履歴は保持されます。"
    },
    "languageRepair.importShort": {
        "en": "Install Downloaded Language Pack",
        "zh-Hans": "安装已下载语言包",
        "ja": "言語パックをインストール"
    },
    "languageRepair.later": {
        "en": "Later",
        "zh-Hans": "稍后",
        "ja": "あとで"
    },
    "languageRepair.downloading": {
        "en": "Downloading the language resources for this version…",
        "zh-Hans": "正在下载与当前版本匹配的语言资源…",
        "ja": "このバージョンの言語リソースを取得中…"
    },
    "languageRepair.privateHelp": {
        "en": "This repository is private or the file is unavailable. Sign in to GitHub in your browser, download this version’s language pack, then install the downloaded file. English remains available.",
        "zh-Hans": "仓库仍为私人或文件暂不可用。请在浏览器登录 GitHub，下载当前版本的语言包后导入安装。期间可继续使用英文界面。",
        "ja": "非公開リポジトリまたはファイルを取得できません。ブラウザでGitHubにログインし、このバージョンの言語パックを取得してインストールしてください。英語で引き続き使用できます。"
    },
    "languageRepair.invalid": {
        "en": "The language pack is damaged or does not match this app version. Nothing was installed. Download the matching pack and try again.",
        "zh-Hans": "语言包已损坏或与当前应用版本不匹配，未安装任何内容。请下载匹配的语言包后重试。",
        "ja": "言語パックが破損しているか、このバージョンと一致しません。インストールしていません。正しいパックで再試行してください。"
    },
    "languageRepair.failed": {
        "en": "The language resources could not be repaired. Check your connection or install a downloaded pack. Your settings and history are unchanged.",
        "zh-Hans": "暂时无法修复语言资源。请检查网络，或安装已下载的语言包。配置和历史保持不变。",
        "ja": "言語リソースを修復できません。接続を確認するか、取得済みのパックをインストールしてください。設定と履歴は保持されます。"
    },
    "languageRepair.chooseFile": {
        "en": "Choose the language pack downloaded from this app’s GitHub repository.",
        "zh-Hans": "请选择从本应用 GitHub 仓库下载的语言包。",
        "ja": "このアプリのGitHubリポジトリから取得した言語パックを選択してください。"
    },
    "languageRepair.installed": {
        "en": "Language resources installed. Reopen the app for all interface text to refresh. Your settings and history are unchanged.",
        "zh-Hans": "语言资源已安装。重新打开应用可完整刷新界面文字；配置和历史保持不变。",
        "ja": "言語リソースをインストールしました。アプリを開き直すとすべての表示が更新されます。設定と履歴は保持されます。"
    }
})

def main() -> None:
    strings = merge_batch_cjk(merge_batch2(STRINGS))
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps(build_catalog(strings), ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    write_strings_files(strings, LPROJ_ROOT)
    subprocess.run([sys.executable, str(ROOT / "scripts/generate-language-pack.py")], check=True)
    print(f"Wrote {len(strings)} keys × {len(SUPPORTED_LANGS)} langs to {OUT} and {LPROJ_ROOT}/*.lproj")


if __name__ == "__main__":
    main()
