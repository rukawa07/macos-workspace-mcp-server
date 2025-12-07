# Implementation Plan

## Tasks

- [x] 1. FocusResultモデルの作成
- [x] 1.1 (P) FocusResult構造体を追加
    - フォーカス結果を表現するデータモデルを作成する
    - WindowInfoを含むレスポンス型を定義する
    - Sendable、Codable準拠を確保する
    - _Requirements: 3.4_

- [x] 2. WindowServiceの拡張
- [x] 2.1 focusWindowメソッドをプロトコルに追加
    - WindowServiceProtocolにfocusWindowメソッドを追加する
    - bundle IDとオプションのタイトルパラメーターを受け付ける
    - FocusResultを返す非同期メソッドとして定義する
    - _Requirements: 1.1, 1.2_

- [x] 2.2 focusWindowの実装
    - Accessibility権限チェックを行う
    - 既存のfindTargetWindowヘルパーを使用してウィンドウを検索する
    - NSRunningApplication.activate()でアプリをアクティブ化する
    - AXUIElementPerformAction(kAXRaiseAction)でウィンドウを前面表示する
    - エラー発生時に適切なWorkspaceErrorを投げる
    - 依存: 2.1完了後
    - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5_

- [x] 2.3 最小化ウィンドウの自動解除機能
    - kAXMinimizedAttributeでウィンドウの最小化状態をチェックする
    - 最小化されている場合はfalseを設定して解除する
    - 解除後に前面表示を実行する
    - 依存: 2.2完了後
    - _Requirements: 2.2_

- [x] 2.4 positionWindow完了後の自動前面表示
    - positionWindowメソッドの最後に前面表示処理を追加する
    - アプリのアクティブ化とウィンドウのRaise処理を実行する
    - 内部ヘルパーを共有して重複を避ける
    - 依存: 2.2, 2.3完了後
    - _Requirements: 2.1_

- [x] 3. FocusWindowToolの実装
- [x] 3.1 (P) ツール定義とInput構造体の作成
    - focus_windowツールの定義を作成する
    - bundleId（必須）とtitle（オプション）のパラメーターを定義する
    - Input構造体をDecodableで定義する
    - _Requirements: 3.2_

- [x] 3.2 executeメソッドの実装
    - MCPArgumentDecoderでパラメーターをデコードする
    - bundleId必須バリデーションを実装する
    - WindowServiceのfocusWindowメソッドを呼び出す
    - MCPResultEncoderで結果をJSON形式で返す
    - エラー発生時はisError: trueと日本語メッセージを返す
    - 依存: 2.4, 3.1完了後
    - _Requirements: 3.3, 3.4, 3.5_

- [x] 4. ToolRegistryへの統合
- [x] 4.1 FocusWindowToolの登録
    - registeredToolsにFocusWindowToolを追加する
    - handleCallToolにfocus_windowケースを追加する
    - WindowServiceインスタンスを作成してツールに渡す
    - 依存: 3.2完了後
    - _Requirements: 3.1_

- [x] 5. 動作確認
- [x] 5.1 ビルドとMCP Inspectorでの確認
    - swift buildでビルドが成功することを確認する
    - MCP Inspectorでfocus_windowツールが表示されることを確認する
    - 実際のアプリケーションで前面表示が動作することを確認する
    - positionWindow後に自動で前面表示されることを確認する
    - 依存: 4.1完了後
    - _Requirements: 1.1, 1.2, 2.1, 2.2, 3.1, 3.2, 3.3, 3.4, 3.5_
