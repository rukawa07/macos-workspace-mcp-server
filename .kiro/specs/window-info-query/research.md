# Research & Design Decisions

## Summary
- **Feature**: `window-info-query`
- **Discovery Scope**: Extension（既存のMCPツールパターンを拡張）
- **Key Findings**:
  - Accessibility APIの`kAXWindowsAttribute`でウィンドウ一覧を取得
  - フルスクリーン状態は`kAXFullscreenAttribute`、最小化は`kAXMinimizedAttribute`で取得
  - ディスプレイ識別はウィンドウ座標とNSScreen.screensの比較で実現

## Research Log

### Accessibility APIによるウィンドウ属性取得
- **Context**: ウィンドウのタイトル、位置、サイズ、状態を取得する方法の調査
- **Sources Consulted**:
  - [alt-tab-macos AXUIElement wrapper](https://github.com/lwouis/alt-tab-macos/blob/master/src/api-wrappers/AXUIElement.swift)
  - [DFAXUIElement library](https://github.com/DevilFinger/DFAXUIElement)
  - [Stack Overflow: Getting a list of windows](https://stackoverflow.com/questions/2107657/mac-cocoa-getting-a-list-of-windows-using-accessibility-api)
- **Findings**:
  - `AXUIElementCopyAttributeValue`で各属性を取得
  - `kAXWindowsAttribute`: アプリケーションの全ウィンドウリスト
  - `kAXTitleAttribute`: ウィンドウタイトル
  - `kAXPositionAttribute`: CGPoint形式の位置
  - `kAXSizeAttribute`: CGSize形式のサイズ
  - `kAXMinimizedAttribute`: Bool、最小化状態
  - `kAXFullscreenAttribute`: Bool、フルスクリーン状態（一部アプリで非対応の可能性）
- **Implications**: 既存の`ApplicationService`を拡張してウィンドウ取得メソッドを追加

### ディスプレイ識別方法
- **Context**: ウィンドウがどのディスプレイに表示されているか判定
- **Sources Consulted**:
  - [Stack Overflow: Determine which display a window is on](https://stackoverflow.com/questions/40881963/determine-which-display-a-window-is-on-in-macos)
  - [Stack Overflow: To which screen window belongs](https://stackoverflow.com/questions/36938069/to-which-screen-window-belongs)
- **Findings**:
  - `NSScreen.screens`で接続ディスプレイ一覧を取得
  - ウィンドウの中心点がどのスクリーンの`frame`に含まれるか判定
  - Core GraphicsとNSScreenで座標系が異なる（Y軸反転）ため変換が必要
  - ウィンドウが複数ディスプレイにまたがる可能性あり
- **Implications**: ウィンドウ中心点で判定し、複数ディスプレイにまたがる場合は主要部分のディスプレイを返す

### 既存コードベースのパターン分析
- **Context**: 既存のツール実装パターンに準拠
- **Sources Consulted**: 既存の`LaunchApplicationTool.swift`, `ListApplicationsTool.swift`, `ApplicationService.swift`
- **Findings**:
  - Tool-per-Fileパターン: 1ツール1ファイル
  - `MCPTool`プロトコル準拠: `name`, `definition`, `execute(arguments:)`
  - `ApplicationServiceProtocol`で外部API呼び出しを抽象化
  - JSON形式でレスポンスを生成
- **Implications**: 既存パターンを踏襲し、`WindowServiceProtocol`または`ApplicationServiceProtocol`拡張で実装

## Architecture Pattern Evaluation

| Option | Description | Strengths | Risks / Limitations | Notes |
|--------|-------------|-----------|---------------------|-------|
| ApplicationServiceProtocol拡張 | 既存プロトコルにウィンドウ取得メソッド追加 | 変更最小、一貫性維持 | プロトコル肥大化の可能性 | - |
| 新規WindowServiceProtocol | ウィンドウ専用サービスを分離 | 責務分離が明確 | 新規ファイル追加、DI設定変更 | 採用 |

## Design Decisions

### Decision: WindowServiceProtocol新規作成
- **Context**: ウィンドウ情報取得機能の実装場所
- **Alternatives Considered**:
  1. ApplicationServiceProtocol拡張 — 既存プロトコルにメソッド追加
  2. WindowServiceProtocol新規作成 — ウィンドウ専用サービス
- **Selected Approach**: WindowServiceProtocol新規作成
- **Rationale**:
  - 責務の明確な分離（アプリ制御 vs ウィンドウ制御）
  - 将来のウィンドウ操作機能（移動、リサイズ等）追加時の拡張性
  - 単一責任の原則に準拠
  - テスト時のモック作成が容易
- **Trade-offs**: 新規ファイル追加、ToolRegistryでのDI設定変更が必要
- **Follow-up**: 将来的にウィンドウ制御機能を追加する際、同じWindowServiceProtocolを拡張

### Decision: ディスプレイ識別方式
- **Context**: ウィンドウがどのディスプレイに表示されているか判定
- **Alternatives Considered**:
  1. ウィンドウ中心点による判定
  2. ウィンドウ面積の過半数による判定
- **Selected Approach**: ウィンドウ中心点による判定
- **Rationale**:
  - 実装がシンプル
  - 大半のユースケースで十分
  - NSScreen.localizedNameでディスプレイ名取得可能
- **Trade-offs**: 端にあるウィンドウの判定が直感と異なる可能性
- **Follow-up**: ユーザーフィードバックに基づき改善

### Decision: フルスクリーン状態取得の代替手段
- **Context**: `kAXFullscreenAttribute`は一部アプリで取得できない場合がある
- **Alternatives Considered**:
  1. kAXFullscreenAttributeのみ使用
  2. フォールバックとしてウィンドウサイズとスクリーンサイズ比較
- **Selected Approach**: kAXFullscreenAttributeを優先し、取得失敗時はfalse
- **Rationale**:
  - シンプルな実装を優先
  - 取得失敗は稀
- **Trade-offs**: 一部アプリでフルスクリーン検出漏れ
- **Follow-up**: 検出漏れが問題になれば代替手段を追加

## Risks & Mitigations
- **Risk 1**: Accessibility権限がない場合にAPI呼び出し失敗 → 事前の権限チェックとユーザーガイダンス提供
- **Risk 2**: 一部アプリでkAXFullscreenAttribute未対応 → デフォルトfalseを返し、エラーとしない
- **Risk 3**: 大量のウィンドウがある場合のパフォーマンス → 指定bundleIdでフィルタリングを推奨

## References
- [Apple Accessibility Programming Guide](https://developer.apple.com/library/archive/documentation/Accessibility/Conceptual/AccessibilityMacOSX/)
- [alt-tab-macos](https://github.com/lwouis/alt-tab-macos) — Swift製のウィンドウ切り替えアプリ、AXUIElement利用の参考
- [DFAXUIElement](https://github.com/DevilFinger/DFAXUIElement) — Accessibility API Swiftラッパー
- [Stack Overflow: Window on display](https://stackoverflow.com/questions/40881963/determine-which-display-a-window-is-on-in-macos)
