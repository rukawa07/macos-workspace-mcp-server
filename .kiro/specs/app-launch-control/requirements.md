# Requirements Document

## Introduction
本ドキュメントは、macOS Workspace MCPサーバーにおける「アプリケーション起動・終了制御」機能の要件を定義する。ユーザーがClaudeに自然言語で指示することで、Spotlight検索やDock操作を介さずにアプリケーションの起動・終了を実行できるようにする。本機能はワークスペース管理の最も基本的な操作であり、他の高度な機能の基盤となる。

## Project Description (Input)
As a ユーザー
I want Claudeに自然言語でアプリの起動・終了を指示できる
So that Spotlight検索やDockから探す手間を省ける

Priority Rationale:
すべてのワークスペース管理機能の最も基本的な操作。これがないと他の機能が実装できない。

## Requirements

### Requirement 1: アプリケーション起動
**Objective:** As a ユーザー, I want Claudeに指定したアプリケーションを起動させる, so that Spotlight検索やDockから探す手間を省ける

#### Acceptance Criteria
1. When ユーザーがbundle IDを指定してアプリケーション起動を要求する, the MCP Server shall 指定されたbundle IDのアプリケーションを起動する
2. When アプリケーション名（例: "Safari", "Finder"）を指定して起動を要求する, the MCP Server shall 対応するbundle IDを解決してアプリケーションを起動する
3. When 起動要求されたアプリケーションが既に起動している, the MCP Server shall そのアプリケーションをアクティブ化（最前面化）する
4. When アプリケーションが正常に起動した, the MCP Server shall プロセスIDとアプリケーション名を含む成功レスポンスを返す
5. If 指定されたbundle IDまたはアプリケーション名が見つからない, the MCP Server shall 具体的なエラーメッセージを含むエラーレスポンスを返す

### Requirement 2: アプリケーション終了
**Objective:** As a ユーザー, I want Claudeに指定したアプリケーションを終了させる, so that 手動でアプリを閉じる手間を省ける

#### Acceptance Criteria
1. When ユーザーがbundle IDを指定してアプリケーション終了を要求する, the MCP Server shall 指定されたbundle IDのアプリケーションに終了シグナルを送信する
2. When アプリケーション名を指定して終了を要求する, the MCP Server shall 対応するbundle IDを解決してアプリケーションを終了する
3. When アプリケーションが正常に終了した, the MCP Server shall 終了したアプリケーション名を含む成功レスポンスを返す
4. If 指定されたアプリケーションが起動していない, the MCP Server shall アプリケーションが起動していない旨のエラーレスポンスを返す
5. While アプリケーションが未保存のドキュメントを持っている, the MCP Server shall 強制終了せず通常の終了処理を実行する（ユーザーに保存確認ダイアログが表示される）

### Requirement 3: 起動中アプリケーション一覧取得
**Objective:** As a ユーザー, I want 現在起動中のアプリケーション一覧を確認する, so that どのアプリが動いているか把握できる

#### Acceptance Criteria
1. When ユーザーが起動中アプリケーション一覧を要求する, the MCP Server shall 現在起動中のすべてのアプリケーション情報を返す
2. The MCP Server shall 各アプリケーションについてbundle ID、アプリケーション名、プロセスIDを含める
3. The MCP Server shall 非表示（hidden）のアプリケーションも一覧に含める
4. The MCP Server shall システムプロセス（UIを持たないバックグラウンドプロセス）を除外する

### Requirement 4: 権限管理
**Objective:** As a ユーザー, I want システム権限の状態を確認・管理する, so that 機能が正しく動作することを保証できる

#### Acceptance Criteria
1. When MCPサーバーが起動する, the MCP Server shall Accessibility APIの権限状態を確認する
2. If Accessibility権限が付与されていない, the MCP Server shall 権限が必要である旨と設定方法を含むエラーメッセージを返す
3. The MCP Server shall 権限エラー時に具体的な設定手順（システム設定 > プライバシーとセキュリティ > アクセシビリティ）を案内する

### Requirement 5: エラーハンドリング
**Objective:** As a 開発者, I want 明確で一貫したエラーレスポンスを受け取る, so that エラーの原因を特定して対処できる

#### Acceptance Criteria
1. If アプリケーションが見つからない, the MCP Server shall `isError: true`と具体的なエラーメッセージを含むレスポンスを返す
2. If Accessibility権限がない, the MCP Server shall 権限エラーであることと対処方法を含むレスポンスを返す
3. If 起動・終了処理がタイムアウトした, the MCP Server shall タイムアウトエラーを返す
4. The MCP Server shall すべてのエラーレスポンスに一貫したフォーマット（isErrorフラグ、エラーメッセージ）を使用する

### Requirement 6: MCPツール定義
**Objective:** As a MCP Client, I want 明確に定義されたツールインターフェースを使用する, so that アプリケーション制御機能を正しく呼び出せる

#### Acceptance Criteria
1. The MCP Server shall `launch_application`ツールを提供し、bundleIdパラメーター（必須）を受け付ける
2. The MCP Server shall `quit_application`ツールを提供し、bundleIdパラメーター（必須）を受け付ける
3. The MCP Server shall `list_applications`ツールを提供し、パラメーターなしで呼び出し可能とする
4. The MCP Server shall 各ツールに明確な説明文（何をするか、いつ使うか、何を返すか）を含める
5. The MCP Server shall inputSchemaで必須パラメーターを明示する
