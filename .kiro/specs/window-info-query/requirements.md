# Requirements Document

## Introduction

本ドキュメントは、macOS Workspace MCPにおけるウィンドウ情報取得機能の要件を定義する。ユーザーがClaudeを通じて特定アプリケーションのウィンドウ情報を照会し、現在のウィンドウ配置を把握できるようにすることを目的とする。この機能は、ウィンドウ制御機能の前提となる基盤機能として位置づけられる。

## Requirements

### Requirement 1: ウィンドウ一覧取得

**Objective:** As a ユーザー, I want アプリケーションのウィンドウ情報を取得できる, so that 現在のウィンドウ配置を把握し、適切な操作ができる

#### Acceptance Criteria

1. When ユーザーがウィンドウ情報取得ツールを呼び出した場合, the WorkspaceMCP shall 指定されたアプリケーションの全ウィンドウ情報をリストとして返す
2. When bundle IDが指定された場合, the WorkspaceMCP shall そのbundle IDに一致するアプリケーションのウィンドウのみを返す
3. When bundle IDが省略された場合, the WorkspaceMCP shall 全アプリケーションのウィンドウ情報を返す

### Requirement 2: ウィンドウ属性情報

**Objective:** As a ユーザー, I want 各ウィンドウの詳細な属性情報を確認できる, so that ウィンドウの状態を正確に把握できる

#### Acceptance Criteria

1. The WorkspaceMCP shall 各ウィンドウについてウィンドウタイトルを含める
2. The WorkspaceMCP shall 各ウィンドウについて位置情報（x座標、y座標）を含める
3. The WorkspaceMCP shall 各ウィンドウについてサイズ情報（幅、高さ）を含める
4. The WorkspaceMCP shall 各ウィンドウについて最小化状態を含める
5. The WorkspaceMCP shall 各ウィンドウについてフルスクリーン状態を含める
6. The WorkspaceMCP shall 各ウィンドウについてウィンドウが表示されているディスプレイの識別子を含める

### Requirement 3: エラーハンドリング

**Objective:** As a ユーザー, I want エラー時に適切なフィードバックを受け取りたい, so that 問題の原因を理解し対処できる

#### Acceptance Criteria

1. If 指定されたbundle IDのアプリケーションが見つからない場合, the WorkspaceMCP shall アプリケーションが見つからない旨のエラーメッセージを返す
2. If Accessibility権限が付与されていない場合, the WorkspaceMCP shall 権限が必要である旨のエラーメッセージを返す
3. If 指定されたアプリケーションにウィンドウが存在しない場合, the WorkspaceMCP shall 空のウィンドウリストを返す（エラーではなく正常なレスポンス）

### Requirement 4: MCPツール定義

**Objective:** As a MCP クライアント, I want 明確なツール定義を通じて機能を呼び出せる, so that 正しいパラメーターで機能を利用できる

#### Acceptance Criteria

1. The WorkspaceMCP shall `list_windows`という名前のMCPツールを提供する
2. The WorkspaceMCP shall ツール説明にアクション内容、使用ケース、戻り値の説明を含める
3. The WorkspaceMCP shall オプショナルパラメーター`bundleId`（string型）を受け付ける
4. When ツールが成功した場合, the WorkspaceMCP shall ウィンドウ情報のJSON配列を返す
5. When ツールが失敗した場合, the WorkspaceMCP shall `isError: true`フラグとエラー詳細メッセージを返す
