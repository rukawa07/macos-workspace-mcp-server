# Requirements Document

## Introduction

本機能は、ユーザーが指定したウィンドウを最前面に表示（フォーカス）する機能を提供する。ウィンドウ配置操作と連携して、配置後のウィンドウを自動的に最前面に表示することで、ユーザーの作業効率を向上させる。

## Requirements

### Requirement 1: ウィンドウの前面表示

**Objective:** As a ユーザー, I want 指定したアプリケーションのウィンドウを最前面に表示したい, so that スムーズに特定のウィンドウを確認・操作できる

#### Acceptance Criteria

1. When ユーザーがbundle IDを指定してウィンドウの前面表示を要求した場合, the WindowService shall 対象アプリケーションをアクティブ化し、ウィンドウを最前面に表示する
2. When ユーザーがbundle IDとウィンドウタイトルを指定した場合, the WindowService shall 指定されたタイトルに一致するウィンドウのみを最前面に表示する
3. If 指定されたアプリケーションが見つからない場合, then the WindowService shall applicationNotFoundエラーを返す
4. If 指定されたウィンドウが見つからない場合, then the WindowService shall windowNotFoundエラーを返す
5. If Accessibility権限がない場合, then the WindowService shall permissionDeniedエラーを返す

### Requirement 2: ウィンドウ配置との連携

**Objective:** As a ユーザー, I want ウィンドウ配置後に配置したウィンドウが自動的に前面に表示されてほしい, so that 配置したウィンドウをすぐに確認・操作できる

#### Acceptance Criteria

1. When positionWindowが成功した場合, the WindowService shall 配置したウィンドウを最前面に表示する
2. While ウィンドウが最小化されている場合, the WindowService shall 最小化を解除してから前面表示を行う

### Requirement 3: MCPツールインターフェース

**Objective:** As a MCP利用者, I want focus_windowツールを通じてウィンドウの前面表示を実行したい, so that Claudeからウィンドウ操作が可能になる

#### Acceptance Criteria

1. The ToolRegistry shall focus_windowツールをツール一覧に登録する
2. The focus_windowツール shall bundleIdパラメーター（必須）とtitleパラメーター（オプション）を受け付ける
3. When focus_windowが実行された場合, the FocusWindowTool shall WindowServiceのfocusWindowメソッドを呼び出す
4. The FocusWindowTool shall 成功時にフォーカスしたウィンドウの情報をJSON形式で返す
5. If エラーが発生した場合, then the FocusWindowTool shall isError: trueと日本語エラーメッセージを返す
