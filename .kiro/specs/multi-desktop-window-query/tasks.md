# Implementation Plan

## Task Overview

複数デスクトップ（Spaces）ウィンドウ情報取得機能の実装タスク

---

## Tasks

- [x] 1. WindowInfoモデルの更新
- [x] 1.1 (P) WindowInfo構造体にisOnCurrentDesktopプロパティを追加
    - 既存のWindowInfo構造体を拡張してBool型のisOnCurrentDesktopプロパティを追加
    - 現在のデスクトップに表示されているかどうかを表現する
    - Codable、Sendable準拠を維持
    - _Requirements: 1.9, 2.1, 2.2, 4.1_

- [x] 1.2 (P) WindowInfoのdisplayIdプロパティをdisplayNameに改名
    - displayIdをdisplayNameに変更し、ディスプレイ名を格納することを明確化
    - 既存のWindowInfo生成箇所を更新
    - _Requirements: 1.8, 2.2_

- [x] 2. CGWindowListベースのウィンドウ取得実装
- [x] 2.1 CGWindowListCopyWindowInfo APIを使用した全ウィンドウ取得処理を実装
    - CGWindowListCopyWindowInfoを.optionAllオプションで呼び出し
    - 全デスクトップ（Spaces）のウィンドウを取得
    - 返却される辞書配列のパース処理を実装
    - nilが返却された場合は空配列を返す
    - _Requirements: 1.1, 3.1, 3.2, 5.1_

- [x] 2.2 kCGWindowBoundsからウィンドウの位置・サイズを抽出
    - CGRect(dictionaryRepresentation:)を使用してboundsを変換
    - x, y, width, heightの各プロパティに設定
    - _Requirements: 1.5, 1.6, 3.3_

- [x] 2.3 kCGWindowOwnerPIDからbundle IDとアプリ名を解決
    - プロセスIDからNSRunningApplicationを取得
    - bundleIdentifierとlocalizedNameを抽出
    - 解決できない場合はウィンドウをスキップ
    - _Requirements: 3.4_

- [x] 2.4 ウィンドウタイトルの取得とフォールバック処理
    - kCGWindowNameからタイトルを取得
    - タイトルがない場合は空文字列を設定
    - _Requirements: 1.4, 3.5_

- [x] 2.5 システムウィンドウのフィルタリング
    - kCGWindowLayer == 0の通常ウィンドウのみを対象とする
    - デスクトップ要素やメニューバーなどを除外
    - _Requirements: 1.1_

- [x] 3. ウィンドウ属性の判定・設定
- [x] 3.1 isOnCurrentDesktopの設定（kCGWindowIsOnscreenから判定）
    - kCGWindowIsOnscreenの値を直接isOnCurrentDesktopにマッピング
    - true = 現在のデスクトップに表示中
    - false = 他のSpaceまたは非表示
    - _Requirements: 4.1, 4.2_

- [x] 3.2 displayNameの設定（ディスプレイ判定）
    - ウィンドウの中心点を計算
    - NSScreen.screensから該当ディスプレイを特定
    - localizedNameをdisplayNameに設定
    - 見つからない場合は"Unknown"を設定
    - _Requirements: 1.8, 4.3_

- [x] 3.3 isMinimized/isFullscreenの設定
    - Accessibility権限がある場合はAccessibility APIから取得
    - 権限がない場合はisOnCurrentDesktopから推定（false固定）
    - 権限チェックを行い適切に分岐
    - _Requirements: 1.7, 5.3_

- [x] 4. bundleIdフィルタリング機能
- [x] 4.1 bundleIdパラメーターによるフィルタリング処理
    - bundleId指定時は該当アプリのウィンドウのみを返却
    - bundleId省略または空文字列時は全アプリのウィンドウを返却
    - 該当アプリが見つからない場合は空配列を返却（エラーではない）
    - _Requirements: 1.2, 1.3, 5.2_

- [x] 5. 統合とテスト
- [x] 5.1 DefaultWindowServiceのlistWindowsメソッドをCGWindowListベースに置き換え
    - 既存のAccessibility APIベースの実装を新実装に置き換え
    - WindowServiceProtocolインターフェースは変更なし
    - 既存のListWindowsToolとの連携を維持
    - _Requirements: 1.1, 1.2, 1.3, 2.3, 2.4_

- [x] 5.2 ユニットテストの実装
    - WindowInfoの新プロパティ（isOnCurrentDesktop, displayName）のテスト
    - CGWindowList辞書からWindowInfo変換ロジックのテスト
    - bundleIdフィルタリングのテスト
    - isOnCurrentDesktop判定ロジックのテスト
    - _Requirements: 1.4, 1.5, 1.6, 1.7, 1.8, 1.9, 2.1, 2.2_

- [x] 5.3 統合テストの実装
    - CGWindowListCopyWindowInfo実呼び出しでのウィンドウ取得テスト
    - 複数ディスプレイ環境でのdisplayName判定テスト
    - MCPツール経由でのJSON形式レスポンス検証
    - _Requirements: 2.3, 2.4, 4.3_

---

## Requirements Coverage

| Requirement | Tasks |
|-------------|-------|
| 1.1 | 2.1, 2.5, 5.1 |
| 1.2 | 4.1, 5.1 |
| 1.3 | 4.1, 5.1 |
| 1.4 | 2.4, 5.2 |
| 1.5 | 2.2, 5.2 |
| 1.6 | 2.2, 5.2 |
| 1.7 | 3.3, 5.2 |
| 1.8 | 1.2, 3.2, 5.2 |
| 1.9 | 1.1, 5.2 |
| 2.1 | 1.1, 5.2 |
| 2.2 | 1.1, 1.2, 5.2 |
| 2.3 | 5.1, 5.3 |
| 2.4 | 5.1, 5.3 |
| 3.1 | 2.1 |
| 3.2 | 2.1 |
| 3.3 | 2.2 |
| 3.4 | 2.3 |
| 3.5 | 2.4 |
| 4.1 | 1.1, 3.1 |
| 4.2 | 3.1 |
| 4.3 | 3.2, 5.3 |
| 5.1 | 2.1 |
| 5.2 | 4.1 |
| 5.3 | 3.3 |
