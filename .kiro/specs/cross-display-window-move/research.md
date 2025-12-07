# Research & Design Decisions

---
**Purpose**: 複数ディスプレイ間でのウィンドウ移動機能に関する調査結果と設計判断の記録

**Usage**:
- 発見フェーズでの調査活動と結果を記録
- design.mdには詳細すぎるトレードオフの文書化
- 将来の監査や再利用のための参照と証拠を提供
---

## Summary
- **Feature**: `cross-display-window-move`
- **Discovery Scope**: Extension（既存システムの拡張）
- **Key Findings**:
  - `position_window`ツールにはすでに`displayName`パラメータが実装されている
  - `NSScreen`を使用したディスプレイ情報取得機能がWindowServiceに部分的に存在
  - `list_displays`ツールを新規追加することで要件を満たせる

## Research Log

### 既存のディスプレイ関連機能
- **Context**: 要件を満たすために既存コードで何が利用可能か調査
- **Sources Consulted**:
  - `Sources/WorkspaceMCP/Tools/PositionWindowTool.swift`
  - `Sources/WorkspaceMCP/Services/WindowService.swift`
  - `Sources/WorkspaceMCP/Models/Common/WorkspaceError.swift`
- **Findings**:
  - `PositionWindowTool`はすでに`displayName`パラメータをサポート
  - `DefaultWindowService.determineTargetScreen()`でディスプレイ検索を実装済み
  - `WorkspaceError.displayNotFound`エラーが定義済み
  - `NSScreen.screens`を使用してディスプレイ一覧を取得
- **Implications**:
  - Requirement 1.1（ディスプレイ指定）は実装済み
  - Requirement 1.2（ディスプレイ省略時の動作）は実装済み
  - Requirement 1.3（存在しないディスプレイのエラー）は実装済み
  - 新規実装は`list_displays`ツールのみ

### NSScreen APIの調査
- **Context**: ディスプレイ情報取得に使用するAPIの確認
- **Sources Consulted**:
  - Apple Developer Documentation - NSScreen
  - 既存コード `WindowService.swift`
- **Findings**:
  - `NSScreen.screens`: 接続されている全ディスプレイの配列
  - `NSScreen.main`: メインディスプレイ（メニューバーがあるディスプレイ）
  - `NSScreen.localizedName`: ディスプレイ名（例: "Built-in Retina Display"）
  - `NSScreen.frame`: ディスプレイの全体フレーム
  - `NSScreen.visibleFrame`: メニューバー・Dockを除いた可視領域
  - `NSScreen.deviceDescription[NSDeviceDescriptionKey.screenNumber]`: CGDirectDisplayID
- **Implications**:
  - `list_displays`ツールはNSScreen APIで十分実装可能
  - 既存の`determineDisplay()`メソッドのパターンを再利用可能

### プリセット配置のディスプレイ対応
- **Context**: Requirement 3（プリセット配置のディスプレイ対応）の実装状況確認
- **Sources Consulted**:
  - `Sources/WorkspaceMCP/Domain/PositionCalculator.swift`
  - `Sources/WorkspaceMCP/Services/WindowService.swift`
- **Findings**:
  - `PositionCalculator.calculateFrame()`は`visibleFrame`を受け取り、プリセットに基づいて計算
  - `DefaultWindowService.positionWindow()`で`targetScreen.visibleFrame`を使用
  - `convertToScreenCoordinates()`でNSScreen座標系をCGWindow座標系に変換済み
- **Implications**:
  - Requirement 3.1（プリセット+ディスプレイ指定）は実装済み
  - Requirement 3.2（メニューバー・Dock考慮）は`visibleFrame`使用で実装済み
  - Requirement 3.3（中央配置）は未実装 → `center`プリセットの追加が必要

## Architecture Pattern Evaluation

| Option | Description | Strengths | Risks / Limitations | Notes |
|--------|-------------|-----------|---------------------|-------|
| 既存パターン拡張 | WindowServiceに機能追加、新規ListDisplaysToolを追加 | 既存アーキテクチャとの一貫性、変更範囲最小 | 特になし | **選択** |
| DisplayService分離 | ディスプレイ操作を専用サービスに分離 | 将来のディスプレイ機能拡張に対応しやすい | 現時点でover-engineering | 将来の拡張時に検討 |

## Design Decisions

### Decision: 既存position_windowツールの拡張ではなく、list_displaysツールの新規追加

- **Context**: ディスプレイ情報取得機能の実装方法
- **Alternatives Considered**:
  1. `position_window`のレスポンスにディスプレイ一覧を追加
  2. 新規`list_displays`ツールを追加
- **Selected Approach**: 新規`list_displays`ツールを追加
- **Rationale**:
  - MCPツールは単一責任原則に従うべき
  - ディスプレイ情報取得はウィンドウ配置とは独立した操作
  - ユーザーは配置前にディスプレイ一覧を確認したい場合がある
- **Trade-offs**: ツール数が増えるが、各ツールの責務が明確
- **Follow-up**: なし

### Decision: centerプリセットの追加

- **Context**: Requirement 3.3「ディスプレイ名のみ指定しプリセット省略時は中央配置」の実装
- **Alternatives Considered**:
  1. `WindowPreset`に`center`を追加
  2. `position_window`でプリセット省略時のデフォルト動作として実装
- **Selected Approach**: `WindowPreset`に`center`を追加し、ツール側でプリセット省略時のデフォルトとして使用
- **Rationale**:
  - プリセットとして明示的に`center`を指定できると、ユーザーの意図が明確
  - 既存の`PositionCalculator`パターンと一貫性
- **Trade-offs**: プリセットの追加による既存コードへの影響（軽微）
- **Follow-up**: `WindowPreset.center`の実装、`PositionWindowTool`のinputSchema更新

### Decision: DisplayInfoモデルの新規追加

- **Context**: ディスプレイ情報のレスポンス形式
- **Alternatives Considered**:
  1. 既存のWindowInfoに類似した構造で新規モデル
  2. Dictionary/JSONで直接返却
- **Selected Approach**: `DisplayInfo`構造体を新規作成
- **Rationale**:
  - 型安全性の確保
  - 既存のCodableパターンとの一貫性
  - 将来の拡張（色空間、リフレッシュレート等）に対応しやすい
- **Trade-offs**: 新規ファイル追加
- **Follow-up**: `Models/Display/DisplayInfo.swift`の作成

## Risks & Mitigations

- **ディスプレイ名の重複**: 同じモデルのディスプレイが複数接続されている場合、`localizedName`が重複する可能性がある → CGDirectDisplayIDを使用した一意識別子の追加を検討（将来対応）
- **座標系の混乱**: NSScreenとCGWindowで座標系が異なる → 既存の`convertToScreenCoordinates()`を再利用し一貫した変換を維持

## References

- [NSScreen - Apple Developer Documentation](https://developer.apple.com/documentation/appkit/nsscreen) — ディスプレイ情報取得API
- [CGWindowListCopyWindowInfo - Apple Developer Documentation](https://developer.apple.com/documentation/coregraphics/1455137-cgwindowlistcopywindowinfo) — ウィンドウ一覧取得API
- 既存コード: `Sources/WorkspaceMCP/Services/WindowService.swift` — ディスプレイ判定の実装パターン
