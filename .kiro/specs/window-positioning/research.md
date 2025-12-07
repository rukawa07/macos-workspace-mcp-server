# Research & Design Decisions

## Summary
- **Feature**: `window-positioning`
- **Discovery Scope**: Extension（既存WindowServiceの拡張）
- **Key Findings**:
  - Accessibility API（AXUIElementSetAttributeValue）を使用してウィンドウの位置・サイズを変更可能
  - ディスプレイ間移動時は「サイズ→位置→サイズ」の順序で設定が必要
  - NSScreen.visibleFrameでメニューバー・Dock除外の作業領域を取得可能

## Research Log

### macOS Accessibility APIによるウィンドウ操作
- **Context**: ウィンドウの位置・サイズ変更に必要なAPIの調査
- **Sources Consulted**:
  - [Rectangle - AccessibilityElement.swift](https://github.com/rxhanson/Rectangle/blob/main/Rectangle/AccessibilityElement.swift)
  - [ModMove - AccessibilityElement.swift](https://github.com/keith/ModMove/blob/main/ModMove/AccessibilityElement.swift)
  - [Alt-Tab macOS - AXUIElement.swift](https://github.com/lwouis/alt-tab-macos/blob/master/src/api-wrappers/AXUIElement.swift)
  - [Apple Developer Documentation - AXUIElementSetAttributeValue](https://developer.apple.com/documentation/applicationservices/1460434-axuielementsetattributevalue)
- **Findings**:
  - `kAXPositionAttribute`と`kAXSizeAttribute`を使用して位置・サイズを設定
  - CGPoint/CGSizeを`AXValueCreate`でAXValueに変換して設定
  - 戻り値でエラーハンドリング（.success, .cannotComplete等）
- **Implications**: 既存のAccessibility API使用パターンを拡張して実装可能

### ディスプレイ間移動の考慮事項
- **Context**: マルチディスプレイ環境での動作確認
- **Sources Consulted**: [Rectangle](https://github.com/rxhanson/Rectangle)のソースコード
- **Findings**:
  - macOSはウィンドウサイズを現在のディスプレイに収まるよう強制する
  - 異なるディスプレイへの移動時は「サイズ→位置→サイズ」の順序で設定が必要
  - Enhanced UI（ズーム機能等）の一時無効化が必要な場合がある
- **Implications**: setFrame実装時に多段階アプローチを採用

### 作業領域（visibleFrame）の取得
- **Context**: メニューバー・Dockを除外した配置可能領域の取得
- **Sources Consulted**: Apple Developer Documentation
- **Findings**:
  - `NSScreen.visibleFrame`でメニューバー・Dock除外の領域を取得
  - `NSScreen.frame`は全体領域（メニューバー含む）
  - Dockの位置（下/左/右）は自動的に考慮される
- **Implications**: プリセット計算にvisibleFrameを使用

## Architecture Pattern Evaluation

| Option | Description | Strengths | Risks / Limitations | Notes |
|--------|-------------|-----------|---------------------|-------|
| WindowServiceProtocol拡張 | 既存プロトコルにpositionWindow追加 | 既存パターン踏襲、統一されたAPI | プロトコル変更が必要 | **採用** - 既存アーキテクチャと整合 |
| 新規PositioningService | 配置専用の新サービス | 責務分離 | サービス増加、依存複雑化 | 過剰な分離 |

## Design Decisions

### Decision: プリセット列挙型の設計
- **Context**: 13種類のプリセット配置を型安全に表現する必要
- **Alternatives Considered**:
  1. 文字列ベース — シンプルだが型安全性なし
  2. enum with associated values — 柔軟だが複雑
  3. 単純enum — 型安全で明確
- **Selected Approach**: 単純enumで全プリセットを定義
- **Rationale**: 13プリセットは固定であり、associated valuesは不要
- **Trade-offs**: 将来のカスタム比率追加には拡張が必要
- **Follow-up**: 将来要件でカスタム比率が必要になれば再検討

### Decision: ウィンドウ識別方法
- **Context**: 対象ウィンドウを一意に特定する方法
- **Alternatives Considered**:
  1. bundleId + title — 十分な識別精度
  2. windowId（CGWindowID）— APIの制約あり
  3. PID + AXUIElement参照 — 複雑すぎる
- **Selected Approach**: bundleId（必須）+ title（オプション）の組み合わせ
- **Rationale**: 既存list_windowsの出力と整合し、ユーザーが指定しやすい
- **Trade-offs**: 同一タイトルの複数ウィンドウは最前面を対象

### Decision: エラーケースの定義
- **Context**: WorkspaceErrorに追加すべきエラーケース
- **Alternatives Considered**:
  1. 既存エラーのみ使用
  2. ウィンドウ操作専用エラー追加
- **Selected Approach**: windowNotFound, windowMinimized, positioningFailed を追加
- **Rationale**: 明確なエラーメッセージでユーザー体験向上
- **Trade-offs**: エラー種類の増加

## Risks & Mitigations
- **Accessibility権限未付与** — 権限チェックを先行実行し、明確なガイダンスを提供
- **ウィンドウ操作拒否** — 一部アプリはAX操作を拒否する可能性。エラーハンドリングで対応
- **ディスプレイ間移動の視覚的ちらつき** — 多段階設定により最小化を試みる

## References
- [Rectangle - AccessibilityElement.swift](https://github.com/rxhanson/Rectangle/blob/main/Rectangle/AccessibilityElement.swift) — ウィンドウ配置の実装参考
- [Apple - AXUIElementSetAttributeValue](https://developer.apple.com/documentation/applicationservices/1460434-axuielementsetattributevalue) — 公式APIドキュメント
- [Swindler](https://github.com/tmandry/Swindler) — macOSウィンドウ管理ライブラリ
