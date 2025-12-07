# Research & Design Decisions

## Summary
- **Feature**: window-focus
- **Discovery Scope**: Extension（既存システムの拡張）
- **Key Findings**:
  - NSRunningApplication.activate()でアプリケーションレベルのアクティブ化が可能（既存ApplicationServiceで使用済み）
  - AXUIElementPerformAction(kAXRaiseAction)で特定ウィンドウの前面表示が可能
  - 最小化されたウィンドウはkAXMinimizedAttributeをfalseに設定して解除可能

## Research Log

### macOSでの特定ウィンドウ前面表示方法
- **Context**: 要件1.1, 1.2でbundle IDとタイトル指定でウィンドウを前面表示する必要がある
- **Sources Consulted**:
  - Apple Developer Documentation: AXUIElement
  - 既存コード: ApplicationService.swift, WindowService.swift
- **Findings**:
  - `NSRunningApplication.activate(options: .activateIgnoringOtherApps)`: アプリ全体をアクティブ化
  - `AXUIElementPerformAction(window, kAXRaiseAction)`: 特定ウィンドウを前面に表示
  - 特定ウィンドウを前面表示するには、まずアプリをアクティブ化し、次にウィンドウにRaiseActionを実行
- **Implications**:
  - WindowServiceに`focusWindow`メソッドを追加
  - 既存の`findTargetWindow`ヘルパーを再利用可能

### 最小化されたウィンドウの解除
- **Context**: 要件2.2で最小化されたウィンドウを解除してから前面表示する必要がある
- **Sources Consulted**: Apple Accessibility API Reference
- **Findings**:
  - `kAXMinimizedAttribute`をfalseに設定することで最小化を解除可能
  - `AXUIElementSetAttributeValue(window, kAXMinimizedAttribute, kCFBooleanFalse)`
  - 解除後は自動的に画面に表示されるが、前面にはならないためRaiseActionも必要
- **Implications**: focusWindow内で最小化状態をチェックし、解除してから前面表示

### positionWindowとの連携
- **Context**: 要件2.1でpositionWindow成功後に自動で前面表示する必要がある
- **Sources Consulted**: 既存WindowService.swift
- **Findings**:
  - 現在のpositionWindowは配置後にウィンドウを前面表示していない
  - positionWindowの最後のステップとして前面表示処理を追加すべき
  - focusWindowを別メソッドとして実装し、positionWindowから呼び出す設計が適切
- **Implications**:
  - focusWindowメソッドを追加
  - positionWindowの最後でfocusWindow相当の処理を呼び出す

## Architecture Pattern Evaluation

| Option | Description | Strengths | Risks / Limitations | Notes |
|--------|-------------|-----------|---------------------|-------|
| WindowService拡張 | 既存WindowServiceにfocusWindowメソッドを追加 | 既存パターンに準拠、コード再利用可能 | なし | 推奨アプローチ |
| 別Service作成 | FocusServiceを新規作成 | 責務分離 | 過剰な分離、コード重複 | 不採用 |

## Design Decisions

### Decision: WindowServiceProtocolにfocusWindowメソッドを追加
- **Context**: ウィンドウの前面表示機能を実装する必要がある
- **Alternatives Considered**:
  1. 新規FocusServiceを作成
  2. 既存WindowServiceを拡張
- **Selected Approach**: WindowServiceProtocolに`focusWindow`メソッドを追加
- **Rationale**:
  - ウィンドウ操作はWindowServiceの責務範囲内
  - 既存の`findTargetWindow`ヘルパーを再利用可能
  - steering/macos-automation.mdのドメインベースサービス分離原則に準拠
- **Trade-offs**: WindowServiceの責務が増えるが、適切な範囲内
- **Follow-up**: なし

### Decision: positionWindow内でactivate + raiseを実行
- **Context**: positionWindow成功後にウィンドウを前面表示する必要がある
- **Alternatives Considered**:
  1. positionWindowからfocusWindowを呼び出す
  2. positionWindow内で直接activate + raiseを実行
- **Selected Approach**: positionWindow内で直接activate + raiseを実行
- **Rationale**:
  - focusWindowメソッドは外部（MCP ツール）からの呼び出し用
  - positionWindowは既にAXUIElement参照を持っているため直接実行が効率的
  - 内部ヘルパー（activateAndRaiseWindow）を共有することでコード重複を回避
- **Trade-offs**: ヘルパーメソッドの追加が必要
- **Follow-up**: なし

## Risks & Mitigations
- **Risk 1**: 一部のアプリでkAXRaiseActionがサポートされていない可能性
  - **Mitigation**: エラーをキャッチしてNSRunningApplication.activate()にフォールバック
- **Risk 2**: System Integrity Protection (SIP)により特定アプリへのアクセスが制限される可能性
  - **Mitigation**: 適切なエラーメッセージを返す（既存パターンに従う）

## References
- [AXUIElement Reference](https://developer.apple.com/documentation/applicationservices/axuielement) — Accessibility API
- [NSRunningApplication](https://developer.apple.com/documentation/appkit/nsrunningapplication) — アプリケーション制御API
- 既存コード: `Sources/WorkspaceMCP/Services/WindowService.swift`
- 既存コード: `Sources/WorkspaceMCP/Services/ApplicationService.swift`
