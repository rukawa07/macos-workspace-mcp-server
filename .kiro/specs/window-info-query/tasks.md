# Implementation Plan

## Task 1: データモデルの定義

- [x] 1.1 (P) ウィンドウ情報を保持するデータ構造を作成する
  - ウィンドウのタイトル、座標（x, y）、サイズ（幅、高さ）を保持するプロパティを定義
  - 最小化状態とフルスクリーン状態を示すブール値を追加
  - 所属ディスプレイの識別子（名前）を保持するプロパティを定義
  - 所有者アプリケーションのbundle IDと名前を保持するプロパティを定義
  - Swift 6のSendable準拠を確保
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6_

## Task 2: ウィンドウサービスの実装

- [x] 2.1 ウィンドウ操作サービスのプロトコルを定義する
  - ウィンドウ一覧を取得するメソッドのシグネチャを定義（bundle IDによるフィルタリング対応）
  - Accessibility権限を確認するメソッドのシグネチャを定義
  - Sendable準拠のプロトコルとして宣言
  - _Requirements: 1.2, 1.3, 3.2_

- [x] 2.2 ウィンドウサービスのデフォルト実装を作成する
  - 権限チェックとして`AXIsProcessTrusted()`を呼び出し、権限がない場合はエラーをスロー
  - bundle ID指定時は該当アプリケーションのウィンドウのみを取得
  - bundle ID省略時は全アプリケーションのウィンドウを取得
  - 指定されたbundle IDのアプリケーションが見つからない場合はエラーをスロー
  - _Requirements: 1.2, 1.3, 3.1, 3.2_

- [x] 2.3 Accessibility APIを使用してウィンドウ属性を取得する
  - `AXUIElementCreateApplication`でアプリケーション要素を作成
  - `kAXWindowsAttribute`でウィンドウ一覧を取得
  - 各ウィンドウから`kAXTitleAttribute`でタイトルを取得
  - `kAXPositionAttribute`と`kAXSizeAttribute`で位置・サイズを取得
  - `kAXMinimizedAttribute`と`kAXFullscreenAttribute`で状態を取得
  - 取得失敗時のフォールバック値（空文字列、false等）を設定
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5_

- [x] 2.4 ウィンドウの所属ディスプレイを判定する
  - `NSScreen.screens`から接続中ディスプレイの一覧を取得
  - ウィンドウの中心点座標を計算
  - 各ディスプレイの`frame`に中心点が含まれるかを判定
  - 該当ディスプレイの`localizedName`を識別子として返却
  - ディスプレイが見つからない場合は「Unknown」を返却
  - _Requirements: 2.6_

## Task 3: MCPツールの実装

- [x] 3.1 ウィンドウ一覧取得ツールのMCP定義を作成する
  - ツール名を`list_windows`として定義
  - 説明文にアクション内容、使用ケース、戻り値の説明を含める
  - オプショナルパラメーター`bundleId`（string型）を定義
  - 既存のMCPToolプロトコルに準拠
  - _Requirements: 4.1, 4.2, 4.3_

- [x] 3.2 ツール実行ロジックを実装する
  - 引数から`bundleId`を抽出（オプショナル）
  - WindowServiceの`listWindows`メソッドを呼び出し
  - 正常時はウィンドウ情報をJSON配列形式で返却
  - ウィンドウが存在しない場合は空配列を返却
  - エラー発生時は`isError: true`フラグとエラーメッセージを返却
  - _Requirements: 1.1, 3.1, 3.3, 4.4, 4.5_

## Task 4: システム統合

- [x] 4.1 ToolRegistryにウィンドウツールを登録する
  - `registeredTools`配列に新しいツールを追加
  - `handleCallTool`メソッドに`list_windows`のルーティングを追加
  - DefaultWindowServiceをインスタンス化してツールに注入
  - _Requirements: 1.1_

## Task 5: テストの実装

- [x] 5.1 (P) ウィンドウ情報モデルのテストを作成する
  - モデルの初期化が正しく動作することを検証
  - 全プロパティが期待通りの値を保持することを確認
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6_

- [x] 5.2 (P) モック用ウィンドウサービスを作成する
  - WindowServiceProtocolに準拠したモック実装を作成
  - テスト用のスタブデータを設定可能にする
  - 権限エラーやアプリ未検出エラーをシミュレート可能にする
  - _Requirements: 3.1, 3.2_

- [x] 5.3 ウィンドウツールのテストを作成する
  - モックサービスを使用してツールの動作を検証
  - bundle ID指定時と省略時の両方のケースをテスト
  - 正常レスポンスのJSON形式を検証
  - エラーレスポンスの形式と`isError`フラグを検証
  - _Requirements: 1.1, 1.2, 1.3, 3.1, 3.3, 4.4, 4.5_

- [x] 5.4 ToolRegistry統合テストを作成する
  - `list_windows`ツールがToolRegistryに正しく登録されていることを確認
  - CallToolハンドラー経由でツールが呼び出せることを検証
  - _Requirements: 4.1_

## Task 6: ビルド検証

- [x] 6.1 ビルドとテストの実行
  - `swift build`でコンパイルエラーがないことを確認
  - `swift test`で全テストがパスすることを確認
  - Swift 6のstrict concurrency警告がないことを確認
