# macOS Workspace MCP Server

macOS用のMCPサーバーで、macOSのアプリケーションとウィンドウを制御し、ユーザーのワークスペース管理を自動化します。

> [Model Context Protocol (MCP)](https://modelcontextprotocol.io/)は、AIアプリケーションと外部システムを接続するためのオープン標準です。

## 概要

Swift 6.0とMCP Swift SDKで実装されたMCPサーバーです。AIアシスタントから以下を自動化できます。

- **アプリ制御**: 起動・終了・起動中一覧
- **ウィンドウ管理**: 位置・サイズ調整、フォーカス、情報取得
- **マルチディスプレイ**: ディスプレイ間の移動・配置
- **プリセット配置**: 左/右/上下半分、4分割、3分割、全画面、中央寄せ

## Tools（MCP Server Tool一覧）

このサーバーは以下のMCPツールを提供します。各ツールは `Tools/` 配下に実装され、`ToolRegistry`で登録されています。

- [launch\_application](#launch_application)
- [quit\_application](#quit_application)
- [list\_applications](#list_applications)
- [list\_windows](#list_windows)
- [position\_window](#position_window)
- [focus\_window](#focus_window)
- [list\_displays](#list_displays)

### launch_application

- **概要**: Bundle IDでアプリを起動（起動済みなら前面化）。
- **パラメーター**: `bundleId`（必須、例: com.apple.Safari）
- **戻り値例**:

```json
{ "processId": 12345, "appName": "Safari", "wasAlreadyRunning": false }
```

### quit_application

- **概要**: 指定アプリを終了（保存ダイアログはOS標準に従う）。
- **パラメーター**: `bundleId`（必須）
- **戻り値例**:

```json
{ "appName": "Safari", "quitSuccessfully": true }
```

### list_applications

- **概要**: 起動中アプリ一覧（UIを持つプロセスのみ）。
- **戻り値例**:

```json
{ "applications": [ { "bundleId": "com.apple.Safari", "name": "Safari", "processId": 12345 } ] }
```

### list_windows

- **概要**: ウィンドウ情報（タイトル、位置、サイズ、状態、ディスプレイ）。
- **パラメーター**: `bundleId`（任意。指定時はそのアプリのみ）
- **戻り値例**:

```json
{ "windows": [ { "title": "ドキュメント.txt", "x": 100, "y": 200, "width": 800, "height": 600, "isMinimized": false, "isFullscreen": false, "displayId": 1 } ] }
```

### position_window

- **概要**: プリセットに基づくウィンドウ配置。
- **パラメーター**:
    - `bundleId`（必須）
    - `preset`（必須。例: left-half, right-half, top-left, left-third, fullscreen, centerなど）
    - `title`（任意）
    - `displayName`（任意）
- **戻り値例**:

```json
{ "windowTitle": "ドキュメント.txt", "newPosition": { "x": 0, "y": 23 }, "newSize": { "width": 960, "height": 1057 } }
```

### focus_window

- **概要**: 指定ウィンドウを最前面化。
- **パラメーター**: `bundleId`（必須）、`title`（任意）
- **戻り値例**:

```json
{ "windowTitle": "Safari", "focusSuccessfully": true }
```

### list_displays

- **概要**: 接続中ディスプレイ情報取得。
- **戻り値例**:

```json
{ "displays": [ { "id": 1, "name": "Built-in Display", "bounds": { "x": 0, "y": 0, "width": 1920, "height": 1080 }, "workArea": { "x": 0, "y": 23, "width": 1920, "height": 1057 }, "isPrimary": true } ] }
```

## セットアップ

### 前提条件

- **macOS**: 15.0以上
- **Xcode**: 16.1以上（Swift 6.0対応）
- **アクセシビリティ権限**: システム設定 > プライバシーとセキュリティ > アクセシビリティで許可

### ビルド

```bash
# Debugビルド（開発・デバッグ用）
swift build

# Releaseビルド（本番用、最適化あり）
swift build -c release
```

### 実行・クライアント設定（Claude Desktop）

Claude DesktopのMCPサーバー設定ファイルに以下を追加します。

macOS: ~/Library/Application Support/Claude/claude_desktop_config.json

```json
{
  "mcpServers": {
    "workspace": {
      "command": "/path/to/MacOSWorkspaceMCPServer/.build/release/MacOSWorkspaceMCPServer"
    }
  }
}
```

### 手動実行（開発・テスト）

```bash
# Debugビルドの実行
.build/debug/MacOSWorkspaceMCPServer

# Releaseビルドの実行
.build/release/MacOSWorkspaceMCPServer
```

サーバーは標準入出力（stdio）でMCPクライアントからのJSON-RPC通信を待機します。

## 使用例

- 「Safariを起動して」
- 「VS Codeのウィンドウを左半分に配置して」
- 「接続されているディスプレイを教えて」
- 「起動中のアプリケーション一覧を見せて」
- 「Slackのウィンドウを右側2/3に配置して」
- 「すべてのFinderウィンドウを表示して」

## 技術スタック

| カテゴリ | 技術 | バージョン |
|---------|------|-----------|
| 言語 | Swift | 6.0 |
| SDK | MCP Swift SDK | 0.10.0+ |
| プラットフォーム | macOS | 15.0+ |
| API | Accessibility API | - |
| ビルドツール | Swift Package Manager | - |
| テスト | Swift Testing | - |
| 通信 | StdioTransport (JSON-RPC) | - |

## トラブルシューティング

### アクセシビリティ権限エラー

1. システム設定を開く
2. プライバシーとセキュリティ > アクセシビリティ
3. サーバー本体またはClaude Desktopにチェックを入れる
4. Claude Desktopを再起動

### ウィンドウが見つからない

- 対象アプリが起動しているか確認
- ウィンドウが最小化されていないか確認
- Bundle IDが正しいか確認（list_applicationsで確認可能）

### マルチディスプレイで配置がずれる

- list_displaysでディスプレイ情報を確認
- displayNameで配置先ディスプレイを指定

## リンク

- [Model Context Protocol](https://modelcontextprotocol.io/)
- [MCP Swift SDK](https://github.com/modelcontextprotocol/swift-sdk)
- [MCP Servers Repository](https://github.com/modelcontextprotocol/servers)
