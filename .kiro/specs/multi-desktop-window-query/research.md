# Research & Design Decisions

---
**Purpose**: 複数デスクトップ（Spaces）ウィンドウ取得機能のディスカバリー調査結果
---

## Summary
- **Feature**: `multi-desktop-window-query`
- **Discovery Scope**: Extension（既存WindowServiceの拡張）
- **Key Findings**:
  - CGWindowListCopyWindowInfo APIで全Spacesのウィンドウ情報取得が可能
  - Space IDの取得はmacOS公開APIでは直接サポートされていない
  - Accessibility権限なしでもCGWindowList APIは使用可能

## Research Log

### CGWindowListCopyWindowInfo API調査
- **Context**: 現在のAccessibility API実装では現在のデスクトップのウィンドウのみ取得可能。全Spaces対応が必要。
- **Sources Consulted**:
  - [Apple Developer Documentation - CGWindowListCopyWindowInfo](https://developer.apple.com/documentation/coregraphics/1455137-cgwindowlistcopywindowinfo)
  - [Qiita - macOS Swift ウインドウキャプチャ](https://qiita.com/a_jike/items/eaa93e688e278f0a8a7b)
  - [GitHub - onmyway133/blog Issue #243](https://github.com/onmyway133/blog/issues/243)
- **Findings**:
  - `.optionAll`オプションで全ウィンドウ（オフスクリーン含む）取得可能
  - `.optionOnScreenOnly`では現在のSpaceのウィンドウのみ
  - 返却される辞書のキー:
    - `kCGWindowNumber`: ウィンドウID
    - `kCGWindowOwnerPID`: オーナープロセスID
    - `kCGWindowOwnerName`: オーナーアプリ名
    - `kCGWindowName`: ウィンドウタイトル
    - `kCGWindowBounds`: 位置・サイズ（辞書形式: X, Y, Width, Height）
    - `kCGWindowLayer`: ウィンドウレイヤー
    - `kCGWindowIsOnscreen`: 画面表示中フラグ
  - `CGRect(dictionaryRepresentation:)`でkCGWindowBoundsを直接CGRectに変換可能
- **Implications**:
  - Accessibility API不要で全ウィンドウ取得可能
  - ただしisMinimized/isFullscreenはCGWindowListでは直接取得不可
  - kCGWindowLayerで通常ウィンドウ（layer == 0）をフィルタリング可能

### Space ID取得方法調査
- **Context**: 各ウィンドウがどのデスクトップ（Space）に属するか識別する方法
- **Sources Consulted**:
  - [GitHub - dshnkao/SpaceId](https://github.com/dshnkao/SpaceId)
  - [GitHub - yabai Discussion #2274](https://github.com/koekeishiya/yabai/discussions/2274)
  - [GitHub - alt-tab-macos Issue #447](https://github.com/lwouis/alt-tab-macos/issues/447)
  - [Exploring macOS private frameworks](https://www.jviotti.com/2023/11/20/exploring-macos-private-frameworks.html)
- **Findings**:
  - macOSには**公開APIでSpace IDを取得する方法がない**
  - 既存ツール（yabai, alt-tab等）はSkyLightプライベートAPIを使用
  - `CGSAddWindowsToSpaces`等のプライベートAPIはmacOS 14.5以降で制限強化
  - `com.apple.spaces` plistから情報取得する方法もあるがウィンドウ単位では不可
  - Dock.appへのコードインジェクション（SIP無効化必要）以外に信頼できる方法なし
- **Implications**:
  - 現実的にはdesktopIdは"current"（現在Space）または"unknown"を設定
  - プライベートAPI使用は安定性・App Store互換性の問題があり採用しない

### ディスプレイ識別方法
- **Context**: ウィンドウがどのディスプレイに表示されているか判定
- **Sources Consulted**: 既存コードベース分析（WindowService.swift）
- **Findings**:
  - 既存実装でNSScreen.screensとウィンドウ中心点の交差判定を使用
  - CGWindowListでもkCGWindowBoundsから同様の判定が可能
- **Implications**: 既存ロジックを再利用可能

### 最小化・フルスクリーン状態の取得
- **Context**: CGWindowListでは最小化・フルスクリーン状態を直接取得できない
- **Sources Consulted**: Apple Developer Documentation, 既存コードベース
- **Findings**:
  - CGWindowListは`kCGWindowIsOnscreen`のみ提供
  - isMinimized/isFullscreenはAccessibility APIでのみ取得可能
  - 代替アプローチ:
    1. オフスクリーン（isOnscreen=false）を最小化とみなす（不正確）
    2. ハイブリッドアプローチ: CGWindowList + Accessibility API併用
    3. シンプルに`false`を設定（情報欠落を許容）
- **Implications**:
  - 要件を完全に満たすにはハイブリッドアプローチが必要
  - ただし複雑性増加とパフォーマンス懸念あり

## Architecture Pattern Evaluation

| Option | Description | Strengths | Risks / Limitations | Notes |
|--------|-------------|-----------|---------------------|-------|
| CGWindowList Only | CGWindowListのみ使用、Accessibility API不使用 | シンプル、権限不要、全Spaces対応 | isMinimized/isFullscreen取得不可 | 要件一部未達 |
| Hybrid Approach | CGWindowList + Accessibility API併用 | 全情報取得可能 | 複雑、パフォーマンス懸念、権限必要 | 推奨 |
| Accessibility Only | 現行実装を維持 | 既存コードそのまま | 現在Spaceのみ、要件未達 | 却下 |

## Design Decisions

### Decision: CGWindowList + Accessibility APIのハイブリッドアプローチ採用

- **Context**: 要件では全デスクトップのウィンドウ取得と各種状態情報（最小化、フルスクリーン）の両方が必要
- **Alternatives Considered**:
  1. CGWindowList Only - シンプルだが状態情報欠落
  2. Hybrid Approach - 全要件対応可能
  3. Accessibility Only - 現行維持だが要件未達
- **Selected Approach**:
  - 基本的にCGWindowListで全ウィンドウを取得
  - 状態情報（isMinimized, isFullscreen）はAccessibility APIで補完
  - Accessibility権限がない場合はCGWindowListのみで動作（状態は推定値）
- **Rationale**:
  - 要件を最大限満たしつつ、権限なしでも基本機能は動作
  - 段階的な実装が可能
- **Trade-offs**:
  - 実装複雑性の増加
  - 2つのAPIからのデータマージ処理が必要
- **Follow-up**: パフォーマンステストで許容範囲か確認

### Decision: isOnCurrentDesktop (Bool) で現在デスクトップ表示を判定

- **Context**: Space IDの取得方法がmacOS公開APIで存在しない
- **Alternatives Considered**:
  1. プライベートAPI（SkyLight）使用 - 不安定、App Store不可
  2. String型desktopId ("current"/"unknown") - 曖昧
  3. Bool型isOnCurrentDesktop - 明確、シンプル
- **Selected Approach**:
  - `kCGWindowIsOnscreen`の値を直接`isOnCurrentDesktop`にマッピング
  - true = 現在のデスクトップに表示中、false = 他のSpaceまたは非表示
- **Rationale**:
  - Bool型で意図が明確
  - 「どのSpaceにあるか」より「現在のSpaceにあるか」の方が実用的
  - APIシンプル化
- **Trade-offs**:
  - 具体的なSpace番号は提供できない
  - ただし現在の要件には十分

## Risks & Mitigations

- **CGWindowListの大量ウィンドウ返却** - kCGWindowLayer == 0でフィルタリング、システムウィンドウ除外
- **パフォーマンス劣化（ハイブリッドアプローチ）** - 必要な情報のみ取得、キャッシュ検討
- **macOSバージョン間の動作差異** - 主要バージョン（15.x）でテスト実施
- **Accessibility権限なし時の動作** - CGWindowListのみで基本動作を保証

## References

- [CGWindowListCopyWindowInfo - Apple Developer](https://developer.apple.com/documentation/coregraphics/1455137-cgwindowlistcopywindowinfo)
- [GitHub - onmyway133/blog #243](https://github.com/onmyway133/blog/issues/243) - Swift実装例
- [GitHub - dshnkao/SpaceId](https://github.com/dshnkao/SpaceId) - Space ID取得ツール
- [GitHub - yabai Discussion #2274](https://github.com/koekeishiya/yabai/discussions/2274) - SkyLight API制限について
