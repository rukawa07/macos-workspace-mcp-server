# Requirements Document

## Introduction

本ドキュメントは、macOS Workspace MCP サーバーにおけるウィンドウ配置機能の要件を定義します。ユーザーは Claude を通じてウィンドウを指定位置（左半分、右半分、4分割など）に配置し、効率的な画面レイアウトを素早く実現できます。

## Project Description (Input)
As a マルチタスクユーザー
I want Claudeにウィンドウの配置を指示できる
So that 効率的な画面レイアウトを素早く実現できる

Priority Rationale:
個別ウィンドウの配置は、ワークスペース管理の基本単位。

## Requirements

### Requirement 1: プリセット配置によるウィンドウ位置指定
**Objective:** As a マルチタスクユーザー, I want ウィンドウをプリセット位置に配置できる, so that 素早く効率的な画面レイアウトを構築できる

#### Acceptance Criteria
1. When ユーザーがウィンドウの配置を要求した場合, the MCP Server shall 指定されたプリセット位置にウィンドウを移動およびリサイズする
2. The MCP Server shall 以下の2分割プリセットをサポートする: 左半分（50%）、右半分（50%）、上半分（50%）、下半分（50%）
3. The MCP Server shall 以下の4分割プリセットをサポートする: 左上、右上、左下、右下（各25%）
4. The MCP Server shall 以下の3分割プリセットをサポートする: 左3分の1、中央3分の1、右3分の1（各33.3%）、左3分の2（66.7%）、右3分の2（66.7%）
5. The MCP Server shall フルスクリーン配置をサポートする（ディスプレイの作業領域全体）

### Requirement 2: 作業領域の考慮
**Objective:** As a マルチタスクユーザー, I want ウィンドウがシステムUI領域を避けて配置される, so that メニューバーやDockに重ならない

#### Acceptance Criteria
1. When ウィンドウを配置する場合, the MCP Server shall macOSのメニューバー領域を除外した作業領域（visibleFrame）を使用する
2. When ウィンドウを配置する場合, the MCP Server shall Dockの位置と領域を考慮して配置位置を計算する
3. The MCP Server shall NSScreen.visibleFrameを使用して作業領域を取得する

### Requirement 3: マルチディスプレイ対応
**Objective:** As a マルチディスプレイユーザー, I want 配置先のディスプレイを指定できる, so that 複数画面を活用した効率的なレイアウトが可能になる

#### Acceptance Criteria
1. Where 複数ディスプレイが接続されている場合, the MCP Server shall ディスプレイ名による配置先指定を許可する
2. When ディスプレイが指定されなかった場合, the MCP Server shall ウィンドウが現在存在するディスプレイに配置する
3. If 指定されたディスプレイが見つからない場合, the MCP Server shall エラーメッセージを返す

### Requirement 4: ウィンドウ識別
**Objective:** As a ユーザー, I want 配置対象のウィンドウを正確に指定できる, so that 意図したウィンドウのみが操作される

#### Acceptance Criteria
1. The MCP Server shall bundle IDによるアプリケーション指定をサポートする
2. The MCP Server shall ウィンドウタイトルによるウィンドウ指定をサポートする
3. When 指定条件に一致するウィンドウが見つからない場合, the MCP Server shall エラーメッセージを返す
4. When 指定条件に複数のウィンドウが一致する場合, the MCP Server shall 最前面のウィンドウを対象とする

### Requirement 5: エラーハンドリング
**Objective:** As a ユーザー, I want 操作失敗時に明確なフィードバックを受け取る, so that 問題を理解し対処できる

#### Acceptance Criteria
1. If Accessibility権限が付与されていない場合, the MCP Server shall 権限エラーを返し、システム環境設定への誘導メッセージを含める
2. If 対象ウィンドウが最小化されている場合, the MCP Server shall ウィンドウ状態エラーを返す
3. If ウィンドウの移動またはリサイズに失敗した場合, the MCP Server shall 操作失敗エラーを返す
4. The MCP Server shall 操作成功時に配置後のウィンドウ情報を返す
