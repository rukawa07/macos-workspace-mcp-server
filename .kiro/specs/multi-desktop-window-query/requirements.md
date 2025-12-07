# Requirements Document

## Introduction

本ドキュメントは、macOS Workspace MCPにおける複数デスクトップ（Spaces）をまたがるウィンドウ情報取得機能の要件を定義する。

ユーザーがClaudeに対してアプリケーションのウィンドウ情報を問い合わせた際、現在のデスクトップだけでなく、すべてのデスクトップ（Spaces）に存在するウィンドウの情報を取得し、適切なJSON形式で返却する機能を提供する。

## Requirements

### Requirement 1: 複数デスクトップウィンドウ一覧取得

**Objective:** As a ユーザー, I want 複数デスクトップにあるすべてのウィンドウ情報を取得したい, so that 現在のウィンドウ配置を把握し、適切な操作を決定できる

#### Acceptance Criteria
1. When ユーザーがアプリのウィンドウ情報を要求した場合, the WindowService shall すべてのデスクトップの全ウィンドウのリストを返す
2. When bundleIdパラメーターが指定された場合, the WindowService shall 指定されたアプリケーションのウィンドウのみをフィルタリングして返す
3. When bundleIdパラメーターが省略された場合, the WindowService shall すべてのアプリケーションのウィンドウを返す
4. The WindowService shall 各ウィンドウについてウィンドウタイトルを含める
5. The WindowService shall 各ウィンドウについて位置情報（x座標、y座標）を含める
6. The WindowService shall 各ウィンドウについてサイズ情報（width、height）を含める
7. The WindowService shall 各ウィンドウについて表示状態（最小化、フルスクリーン）を含める
8. The WindowService shall 各ウィンドウについてディスプレイ名を含める
9. The WindowService shall 各ウィンドウについて現在のデスクトップに表示されているかどうかを含める

### Requirement 2: ウィンドウ情報のデータ構造

**Objective:** As a 開発者, I want ウィンドウ情報が明確なデータ構造で返却される, so that プログラムから容易に解析・利用できる

#### Acceptance Criteria
1. The WindowService shall ウィンドウ情報をCodable準拠のWindowInfo構造体で返す
2. The WindowInfo shall 以下のプロパティを持つ: title (String), x (Double), y (Double), width (Double), height (Double), isMinimized (Bool), isFullscreen (Bool), displayName (String), isOnCurrentDesktop (Bool), ownerBundleId (String), ownerName (String)
3. The WindowService shall レスポンスをWindowListResponse構造体でラップして返す
4. The WindowService shall JSONEncoderを使用してprettyPrinted形式のJSON文字列を生成する

### Requirement 3: CGWindowListを使用した全デスクトップウィンドウ取得

**Objective:** As a システム, I want CGWindowList APIを使用してすべてのデスクトップのウィンドウを取得したい, so that Accessibility APIの制限を超えて全Spacesのウィンドウ情報にアクセスできる

#### Acceptance Criteria
1. The WindowService shall CGWindowListCopyWindowInfo APIを使用してシステム全体のウィンドウ一覧を取得する
2. The WindowService shall kCGWindowListOptionAllオプションを使用してすべてのウィンドウ（すべてのSpaces含む）を取得する
3. The WindowService shall kCGWindowBoundsキーからウィンドウの位置とサイズを抽出する
4. The WindowService shall kCGWindowOwnerPIDキーからオーナープロセスIDを取得し、bundle IDとアプリ名を解決する
5. If ウィンドウにタイトルがない場合, then the WindowService shall 空文字列を設定する

### Requirement 4: デスクトップ（Space）識別

**Objective:** As a ユーザー, I want 各ウィンドウがどのデスクトップ（Space）にあるかを知りたい, so that 目的のウィンドウを特定できる

#### Acceptance Criteria
1. The WindowService shall CGWindowListから取得したウィンドウに現在デスクトップ表示フラグを付与する
2. The WindowService shall kCGWindowIsOnscreenの値を使用してisOnCurrentDesktopを設定する
3. While 複数のディスプレイが接続されている場合, the WindowService shall 各ウィンドウに正しいディスプレイ名を設定する

### Requirement 5: エラーハンドリング

**Objective:** As a ユーザー, I want エラー発生時に適切なエラーメッセージを受け取りたい, so that 問題の原因を理解し対処できる

#### Acceptance Criteria
1. If CGWindowListCopyWindowInfoがnilを返した場合, then the WindowService shall 空のウィンドウリストを返す
2. If 指定されたbundleIdのアプリケーションが見つからない場合, then the WindowService shall 空のウィンドウリストを返す（エラーではない）
3. The WindowService shall Accessibility権限なしでもCGWindowList APIを使用できることを前提とする
