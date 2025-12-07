# macOS Automation Steering

macOS Workspace MCPにおけるアプリケーション制御とウィンドウ管理の実装パターン

---

## Technology Stack

### Core Technologies

- **Swift 6.0**: Swift 6言語機能を活用（strict concurrency対応）
- **macOS 15+**: 最新のmacOS APIを対象
- **MCP Swift SDK 0.10.0+**: Model Context Protocol実装
- **StdioTransport**: stdin/stdoutベースのJSON-RPC通信
- **Accessibility API**: アプリケーション・ウィンドウ制御
- **NSAppleScript**: レガシーアプリケーション対応

### Platform Requirements

- Deployment Target: macOS 15.0以上
- Swift Language Version: 6.0
- Xcode: Xcode 16.1以上（Swift 6対応）
- Transport Protocol: StdioTransport（標準入出力）

---

## Code Organization

### MARK Comments規約

**禁止ルール: MARKコメントにタスク番号を含めない**

実装フェーズで一時的に使用したタスク番号は、実装完了後に必ず削除すること。

#### ✅ 良い例（プロダクションコード）

```swift
// MARK: - Protocol Definition
protocol ApplicationService {
    func launchApplication(bundleId: String) async throws -> LaunchResult
}

// MARK: - Tool Registration and Routing
struct ToolRegistry {
    static func handleListTools(_ params: ListTools.Parameters) -> ListTools.Response {
        // ...
    }
}

// MARK: - Launch Application Tests
@Suite("ApplicationServiceのテスト")
struct ApplicationServiceTests {
    // ...
}
```

#### ❌ 悪い例（タスク番号が残っている）

```swift
// MARK: - Protocol Definition (Task 2.1)  // ❌ タスク番号を削除すべき
protocol ApplicationService {
    func launchApplication(bundleId: String) async throws -> LaunchResult
}

// MARK: - Task 3.2: Tool Registration and Routing  // ❌ タスク番号を削除すべき
struct ToolRegistry {
    // ...
}

// MARK: - Task 2.2: Launch Application Tests  // ❌ タスク番号を削除すべき
@Suite("ApplicationServiceのテスト")
struct ApplicationServiceTests {
    // ...
}
```

#### 実装フェーズでの一時的な使用（許可）

TDD実装中は一時的にタスク番号を含めてもよいが、機能完成後に必ず削除する:

```swift
// 実装中（一時的に許可）
// MARK: - Task 2.1: Protocol Definition

// 実装完了後（必須）
// MARK: - Protocol Definition
```

---

### Documentation Comments規約

**禁止ルール: ドキュメンテーションコメントにRequirements番号を含めない**

実装フェーズで一時的に使用したRequirements参照は、実装完了後に必ず削除すること。

#### ✅ 良い例（プロダクションコード）

```swift
/// アプリケーション制御サービスのプロトコル
public protocol ApplicationServiceProtocol: Sendable {
    /// アプリケーションを起動する
    /// - Parameter bundleId: アプリケーションのbundle ID
    /// - Returns: 起動結果
    func launchApplication(bundleId: String) async throws -> LaunchResult
}

/// ウィンドウ情報を表現するデータモデル
public struct WindowInfo: Sendable, Codable {
    public let title: String
    public let x: Double
    public let y: Double
}
```

#### ❌ 悪い例（Requirements番号が残っている）

```swift
/// アプリケーション制御サービスのプロトコル
///
/// Requirements:  // ❌ Requirements参照を削除すべき
/// - 1.1, 2.1, 3.1, 4.1: 起動、終了、一覧取得、権限確認の4つの機能を抽象化
public protocol ApplicationServiceProtocol: Sendable {
    /// アプリケーションを起動する
    ///
    /// Requirements:  // ❌ Requirements参照を削除すべき
    /// - 1.1: bundle IDを指定してアプリケーションを起動
    /// - 1.3: 既に起動中のアプリは最前面にアクティブ化
    func launchApplication(bundleId: String) async throws -> LaunchResult
}

/// ウィンドウ情報を表現するデータモデル
///
/// Requirements:  // ❌ Requirements参照を削除すべき
/// - 2.1: ウィンドウタイトル
/// - 2.2: 位置情報（x座標、y座標）
public struct WindowInfo: Sendable, Codable {
    public let title: String
    public let x: Double
    public let y: Double
}
```

#### 実装フェーズでの一時的な使用（許可）

TDD実装中は一時的にRequirements番号を含めてもよいが、機能完成後に必ず削除する:

```swift
// 実装中（一時的に許可）
/// アプリケーションを起動する
///
/// Requirements:
/// - 1.1: bundle IDを指定してアプリケーションを起動
func launchApplication(bundleId: String) async throws -> LaunchResult

// 実装完了後（必須）
/// アプリケーションを起動する
/// - Parameter bundleId: アプリケーションのbundle ID
/// - Returns: 起動結果
func launchApplication(bundleId: String) async throws -> LaunchResult
```

**理由**:

- Requirements番号は仕様書との紐付けのために一時的に有用
- プロダクションコードでは実装の「何を」「なぜ」を説明すべき
- Requirements番号は実装の詳細ではなくプロセスの痕跡

---

## Architecture Patterns

### MCP Server Structure

```swift
// MCPサーバーの基本構造（Swift 6.0 + StdioTransport）
import MCP

@main
struct MacOSWorkspaceMCPServer {
    static func main() async throws {
        // サーバー初期化（capabilities定義）
        let server = Server(
            name: "MacOSWorkspaceMCP",
            version: "0.1.0",
            capabilities: .init(
                tools: .init(listChanged: false)
            )
        )
        
        // ツールハンドラー登録（handler-based pattern）
        .withMethodHandler(ListTools.self) { _, _ in
            // ツールリスト返却
            return .init(tools: [
                // Tool定義
            ])
        }
        .withMethodHandler(CallTool.self) { params, _ in
            // ツール実行
            return .init(content: [], isError: false)
        }
        
        // StdioTransportで起動
        let transport = StdioTransport()
        try await server.start(transport: transport)
    }
}
```

### Tool Implementation Pattern

```swift
// 各ツールは独立したstructで実装
struct LaunchApplicationTool: MCPTool {
    var name: String { "launch_application" }
    var description: String { "指定されたアプリケーションを起動" }
    
    func execute(parameters: Parameters) async throws -> ToolResult {
        // Accessibility APIまたはNSAppleScriptを使用
    }
}
```

### Tool Definition Best Practices

**MCP Builder準拠のツール設計**:

```swift
// ✅ Good: 明確でアクション指向の命名
Tool(
    name: "launch_application",
    description: """
    指定されたbundle IDのアプリケーションを起動します。
    アプリが既に起動している場合はアクティブ化します。
    成功時にはプロセスIDを返します。
    """,
    inputSchema: .object(
        properties: [
            "bundleId": .object(
                type: "string",
                description: "アプリケーションのbundle ID（例: com.apple.Safari）"
            )
        ],
        required: ["bundleId"]
    )
)

// ❌ Bad: 曖昧な命名と説明
Tool(
    name: "launch",
    description: "アプリ起動",
    inputSchema: .object(properties: ["id": .object(type: "string")])
)
```

**ツール名の原則**:

- アクション指向（`search_`, `create_`, `update_`など）
- スネークケース（`launch_application`、`quit_application`）
- 具体的で簡潔

**説明文の原則**:

1. 何をするか（アクション）
2. いつ使うか（使用ケース）
3. 何を返すか（戻り値）

**inputSchemaの原則**:

- 必ず明示的に定義（パラメーターなしでも`.object(properties: [:], required: [])`）
- 固定オプションには`enum`を使用
- 各フィールドに`description`を追加

```

---

## MCP Tool Parameter Extraction

### MCPArgumentDecoder ユーティリティ

**重要**: MCPツール実装時のパラメータ抽出には `MCPArgumentDecoder` と `Input` 構造体を使用すること。

MCPライブラリは引数を `[String: Value]` 型で渡す。`Input` 構造体を `Decodable` で定義し、`MCPArgumentDecoder` でデコードすることで、型安全かつテスト/本番で統一されたパラメータ抽出を実現する。

### 使用パターン

```swift
public struct PositionWindowTool: MCPTool {
    // MARK: - Input

    /// ツール入力パラメーター（inputSchemaと対応）
    struct Input: Decodable {
        let bundleId: String?   // 必須はバリデーションで判定
        let preset: String?     // 必須はバリデーションで判定
        let title: String?      // オプション
        let displayName: String?  // オプション
    }

    public func execute(arguments: [String: Value]) async -> CallTool.Result {
        // 1. 引数をデコード
        guard let input: Input = MCPArgumentDecoder.decode(from: arguments) else {
            return .init(
                content: [.text("エラー: 引数のデコードに失敗しました。")],
                isError: true
            )
        }

        // 2. 必須パラメータのバリデーション
        guard let bundleId = input.bundleId, !bundleId.isEmpty else {
            return .init(
                content: [.text("エラー: パラメーター 'bundleId' は必須です。")],
                isError: true
            )
        }

        // 3. オプションパラメータ（空文字列はnilとして扱う）
        let title = input.title.flatMap { $0.isEmpty ? nil : $0 }

        // 4. サービス呼び出し...
    }
}
```

### Input構造体の設計原則

1. **全フィールドをOptionalで定義**: 必須/オプションはバリデーションで判定
2. **inputSchemaと対応**: ツール定義の `properties` と同じフィールド名
3. **ツール内部に定義**: 各ツールの `Input` はそのツール構造体内で定義

```swift
// ✅ Good: 全フィールドOptional + バリデーション
struct Input: Decodable {
    let bundleId: String?  // 必須だがOptionalで定義
}
guard let bundleId = input.bundleId, !bundleId.isEmpty else { /* エラー */ }

// ❌ Bad: non-Optionalだとデコードエラーになりやすい
struct Input: Decodable {
    let bundleId: String  // 必須フィールドをnon-Optionalにすると
}                          // フィールドが無い場合デコード失敗
```

### テストでの使用

テストでは必ず `Value.string()` 等を使用して引数を渡す:

```swift
let result = await tool.execute(arguments: [
    "bundleId": Value.string("com.apple.Safari"),
    "preset": Value.string("left")
])
```

### MCPResultEncoder ユーティリティ

レスポンスのJSON変換には `MCPResultEncoder` を使用する:

```swift
// サービス呼び出し
do {
    let result = try await service.positionWindow(...)
    return MCPResultEncoder.encode(result)  // Encodable → CallTool.Result
} catch let error as WorkspaceError {
    return .init(content: [.text(error.userMessage)], isError: true)
}
```

### ファイル配置

```
Sources/MacOSMacOSWorkspaceMCP/
└── Utils/
    ├── MCPArgumentDecoder.swift  # パラメータデコードユーティリティ
    └── MCPResultEncoder.swift    # レスポンスエンコードユーティリティ
```

### ❌ アンチパターン（禁止）

```swift
// ❌ 直接キャストは本番環境で失敗する
guard let bundleId = arguments["bundleId"] as? String else { ... }

// ❌ String(describing:)は意図しない結果を生成する
let bundleId = String(describing: arguments["bundleId"])
// 結果: "string(\"com.apple.Safari\")" になってしまう

// ❌ MCP Value型の直接操作は冗長
if let value = arguments["bundleId"] as? String {
    bundleId = value
} else if let value = arguments["bundleId"] as? Value, let str = value.stringValue {
    bundleId = str
}

// ❌ テストで生の文字列を渡すとデコードに失敗
let result = await tool.execute(arguments: [
    "bundleId": "com.apple.Safari"  // ❌ Value.string() を使用すべき
])

// ❌ 手動でJSONEncoderを呼び出す（MCPResultEncoderを使用すべき）
let encoder = JSONEncoder()
encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
let jsonData = try encoder.encode(response)
let jsonResult = String(data: jsonData, encoding: .utf8) ?? "{}"
return .init(content: [.text(jsonResult)], isError: false)
```

---

## Accessibility API Usage

### Application Control

```swift
import ApplicationServices

// アプリケーション検索
let apps = NSWorkspace.shared.runningApplications
let targetApp = apps.first { $0.bundleIdentifier == bundleId }

// プロセスベースのAXUIElement作成
if let pid = targetApp?.processIdentifier {
    let appElement = AXUIElementCreateApplication(pid)
    // ウィンドウ操作など
}
```

### Window Management Pattern

```swift
// ウィンドウ一覧取得
var windowList: CFArray?
AXUIElementCopyAttributeValue(
    appElement,
    kAXWindowsAttribute as CFString,
    &windowList
)

// ウィンドウ属性操作
AXUIElementSetAttributeValue(
    windowElement,
    kAXPositionAttribute as CFString,
    position
)
```

### Common Attributes

- `kAXWindowsAttribute`: ウィンドウ一覧
- `kAXPositionAttribute`: ウィンドウ位置 (CGPoint)
- `kAXSizeAttribute`: ウィンドウサイズ (CGSize)
- `kAXMinimizedAttribute`: 最小化状態 (Bool)
- `kAXMainWindowAttribute`: メインウィンドウ

---

## NSAppleScript Integration

### When to Use

- Accessibility APIで制御できないレガシーアプリ
- システムイベント操作が必要な場合
- アプリケーション固有のスクリプトコマンド

### Pattern

```swift
import Foundation

func executeAppleScript(_ script: String) throws -> String? {
    let appleScript = NSAppleScript(source: script)
    var error: NSDictionary?
    let result = appleScript?.executeAndReturnError(&error)
    
    if let error = error {
        throw AppleScriptError.executionFailed(error)
    }
    
    return result?.stringValue
}
```

### Example Scripts

```applescript
-- アプリケーション起動
tell application "Safari"
    activate
end tell

-- ウィンドウサイズ変更
tell application "System Events"
    tell process "Safari"
        set position of window 1 to {0, 0}
        set size of window 1 to {1920, 1080}
    end tell
end tell
```

---

## Error Handling

### Error Types

```swift
enum WorkspaceError: Error, LocalizedError {
    case applicationNotFound(String)
    case accessibilityPermissionDenied
    case windowOperationFailed(String)
    case appleScriptError(NSDictionary)
    
    var errorDescription: String? {
        switch self {
        case .applicationNotFound(let name):
            return "アプリケーション '\(name)' が見つかりません"
        case .accessibilityPermissionDenied:
            return "アクセシビリティ権限が必要です"
        case .windowOperationFailed(let detail):
            return "ウィンドウ操作に失敗: \(detail)"
        case .appleScriptError(let error):
            return "AppleScript実行エラー: \(error)"
        }
    }
}
```

### Permission Checking

```swift
// Accessibility権限確認
func checkAccessibilityPermission() -> Bool {
    let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true]
    return AXIsProcessTrustedWithOptions(options as CFDictionary)
}
```

---

## Naming Conventions

### File Organization

```text
Sources/MacOSWorkspaceMCP/
├── Main.swift                    # エントリポイント、サーバー初期化
├── MCP/
│   ├── MCPTool.swift             # ツール共通プロトコル
│   └── ToolRegistry.swift        # ツール登録・ルーティング
├── Tools/                        # MCPツール実装（1ツール1ファイル）
│   ├── LaunchApplicationTool.swift
│   ├── QuitApplicationTool.swift
│   ├── ListApplicationsTool.swift
│   └── ListWindowsTool.swift
├── Services/                     # ドメインごとにサービスを分離
│   ├── ApplicationService.swift  # ApplicationServiceProtocol + DefaultApplicationService
│   └── WindowService.swift       # WindowServiceProtocol + DefaultWindowService
└── Models/                       # データ型定義（1struct/enum 1ファイル）
    ├── Common/                   # 複数ドメインで共通使用される型
    │   └── WorkspaceError.swift
    ├── Application/              # アプリケーション関連モデル
    │   ├── ApplicationInfo.swift
    │   ├── LaunchResult.swift
    │   ├── QuitResult.swift
    │   ├── LaunchApplicationResponse.swift
    │   ├── QuitApplicationResponse.swift
    │   └── ApplicationListResponse.swift
    └── Window/                   # ウィンドウ関連モデル
        ├── WindowInfo.swift
        └── WindowListResponse.swift
```

### Models Directory Structure

**原則**: 各struct/enumは個別ファイルに分割し、ドメインごとにサブディレクトリを作成する。

| ディレクトリ | 用途 | 例 |
|-------------|------|-----|
| `Models/Common/` | 複数ドメインで共通使用される型 | `WorkspaceError` |
| `Models/Application/` | アプリケーション操作関連 | `ApplicationInfo`, `LaunchResult` |
| `Models/Window/` | ウィンドウ操作関連 | `WindowInfo`, `WindowListResponse` |
| `Models/Display/` | ディスプレイ操作関連（将来） | `DisplayInfo` |

**ファイル命名規則**:

- データモデル: `{ModelName}.swift` (例: `ApplicationInfo.swift`)
- レスポンス型: `{Action}{Domain}Response.swift` (例: `LaunchApplicationResponse.swift`)
- 一覧レスポンス: `{Domain}ListResponse.swift` (例: `WindowListResponse.swift`)

### Tool-per-File Pattern

各MCPツールは独立したファイルで管理する:

```swift
// Tools/LaunchApplicationTool.swift
struct LaunchApplicationTool: MCPTool {
    static let name = "launch_application"
    static let definition = Tool(...)

    private let service: ApplicationServiceProtocol

    init(service: ApplicationServiceProtocol) {
        self.service = service
    }

    func execute(arguments: [String: JSONValue]) async -> CallTool.Result {
        // 実装
    }
}
```

**利点**:

- 新規ツール追加時の変更範囲が最小化
- ツールごとの独立したテストが容易
- コードレビュー・差分管理が明確

### MCPTool Protocol

```swift
/// MCPツールの共通プロトコル
protocol MCPTool: Sendable {
    static var name: String { get }
    static var definition: Tool { get }
    func execute(arguments: [String: JSONValue]) async -> CallTool.Result
}
```

### Naming Rules

- **Tool structs**: `{Action}{Target}Tool` (例: `LaunchApplicationTool`)
- **Tool files**: `{Action}{Target}Tool.swift` (例: `LaunchApplicationTool.swift`)
- **Service protocols**: `{Domain}ServiceProtocol` (例: `ApplicationServiceProtocol`)
- **Service classes**: `Default{Domain}Service` (例: `DefaultApplicationService`)
- **Error enums**: `{Domain}Error` (例: `WorkspaceError`)
- **Extensions**: `{Type}+{Feature}.swift` (例: `AXUIElement+Window.swift`)

### Domain-based Service Separation

**原則**: 操作対象のドメインが異なる場合は、Serviceファイルを分離する。

| ドメイン | Service | 責務 |
|---------|---------|------|
| Application | `ApplicationService` | アプリの起動・終了・一覧取得 |
| Window | `WindowService` | ウィンドウの取得・移動・リサイズ |
| Display | `DisplayService` | ディスプレイ情報の取得・設定 |
| Workspace | `WorkspaceService` | デスクトップ・スペース管理 |

**分離の判断基準**:

1. **操作対象が異なる**: アプリ vs ウィンドウ vs ディスプレイ
2. **ライフサイクルが異なる**: アプリ起動 vs ウィンドウ配置
3. **将来の拡張が予想される**: ウィンドウ操作は移動・リサイズ等が追加される

```swift
// ✅ Good: ドメインごとにサービスを分離
struct LaunchApplicationTool: MCPTool {
    private let service: ApplicationServiceProtocol  // アプリ操作
}

struct ListWindowsTool: MCPTool {
    private let service: WindowServiceProtocol  // ウィンドウ操作
}

// ❌ Bad: 異なるドメインを1つのサービスに混在
struct ListWindowsTool: MCPTool {
    private let service: ApplicationServiceProtocol  // 責務が曖昧
}
```

**ファイル構成例**:

```text
Sources/MacOSWorkspaceMCP/
├── Services/
│   ├── ApplicationService.swift   # ApplicationServiceProtocol + DefaultApplicationService
│   ├── WindowService.swift        # WindowServiceProtocol + DefaultWindowService
│   └── DisplayService.swift       # DisplayServiceProtocol + DefaultDisplayService（将来）
```

**プロトコルと実装は同一ファイルに配置**:

```swift
// Services/WindowService.swift

/// ウィンドウ操作サービスのプロトコル
public protocol WindowServiceProtocol: Sendable {
    func listWindows(bundleId: String?) async throws -> [WindowInfo]
    func checkAccessibilityPermission() -> Bool
}

/// WindowServiceProtocolのデフォルト実装
public final class DefaultWindowService: WindowServiceProtocol, @unchecked Sendable {
    // 実装
}
```

---

## Async/Await Pattern

### Concurrency

```swift
// 非同期操作はasync/awaitで統一
func launchApplication(_ bundleId: String) async throws {
    try await Task.detached {
        // NSWorkspace操作
        NSWorkspace.shared.launchApplication(
            withBundleIdentifier: bundleId,
            options: [],
            additionalEventParamDescriptor: nil,
            launchIdentifier: nil
        )
    }.value
}

// 複数操作の並列実行
async let windowsTask = getWindows(for: app)
async let attributesTask = getAttributes(for: window)
let (windows, attributes) = try await (windowsTask, attributesTask)
```

---

## Testing Strategy

### Unit Tests

- Accessibility API呼び出しはプロトコルで抽象化
- モック実装でテスト可能に

```swift
protocol AccessibilityServiceProtocol {
    func getWindows(for app: AXUIElement) async throws -> [AXUIElement]
}

// 本番
class AccessibilityService: AccessibilityServiceProtocol { }

// テスト
class MockAccessibilityService: AccessibilityServiceProtocol { }
```

### Integration Tests

- 実際のアプリケーション起動が必要
- CI環境では制約あり（権限問題）

---

## Error Handling Patterns

### Error Categories

```swift
// MCP Builder準拠のエラー分類
enum WorkspaceError: Error {
    case applicationNotFound(String)
    case accessibilityPermissionDenied
    case windowNotFound(String)
    case invalidParameter(String)
}
```

### Error Response Pattern

```swift
// ✅ Good: 説明的なエラーメッセージとisErrorフラグ
return .init(
    content: [.text("Error: Application 'com.example.app' not found. Please check the bundle ID.")],
    isError: true
)

// ❌ Bad: 曖昧なエラーメッセージ
return .init(
    content: [.text("エラーが発生しました")],
    isError: false  // フラグ忘れ
)
```

### Input Validation Pattern

```swift
// 必須パラメーターの検証
guard let bundleId = arguments["bundleId"] as? String,
      !bundleId.isEmpty else {
    return .init(
        content: [.text("Error: Missing required parameter 'bundleId'")],
        isError: true
    )
}

// URLスキーム検証（セキュリティ）
guard let url = URL(string: urlString),
      ["http", "https"].contains(url.scheme?.lowercased()) else {
    return .init(
        content: [.text("Error: Only HTTP/HTTPS URLs are allowed")],
        isError: true
    )
}
```

### Common Pitfalls

1. **サイレントな失敗**: 必ず`isError: true`を設定
2. **曖昧なメッセージ**: 具体的なエラー内容を説明
3. **検証漏れ**: 必須パラメーターは必ずチェック

---

## JSON Serialization

### Codable + JSONEncoder Pattern

オブジェクトからJSON文字列への変換は、手動の文字列組み立てではなく、`Codable`準拠と`JSONEncoder`を使用する。

**原則**:

1. **データモデルは`Codable`準拠**: レスポンスに含める全ての型を`Codable`に準拠させる
2. **レスポンス用ラッパー型を定義**: APIレスポンスの構造を明示的に型で表現
3. **JSONEncoderで変換**: 手動の文字列組み立ては禁止

```swift
// ✅ Good: Codable準拠のモデルとJSONEncoder

// 1. データモデルをCodable準拠に
public struct WindowInfo: Sendable, Codable {
    public let title: String
    public let x: Double
    public let y: Double
    public let width: Double
    public let height: Double
    public let isMinimized: Bool
    public let isFullscreen: Bool
    public let displayId: String
    public let ownerBundleId: String
    public let ownerName: String
}

// 2. レスポンス用ラッパー型を定義
public struct WindowListResponse: Sendable, Codable {
    public let windows: [WindowInfo]
}

// 3. ツールでJSONEncoderを使用
func execute(arguments: [String: Any]) async -> CallTool.Result {
    let windows = try await service.listWindows(bundleId: bundleId)

    let response = WindowListResponse(windows: windows)
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    let jsonData = try encoder.encode(response)
    let jsonResult = String(data: jsonData, encoding: .utf8) ?? "{}"

    return .init(content: [.text(jsonResult)], isError: false)
}
```

```swift
// ❌ Bad: 手動の文字列組み立て

func execute(arguments: [String: Any]) async -> CallTool.Result {
    let windows = try await service.listWindows(bundleId: bundleId)

    // 手動JSON組み立て - エスケープ漏れ、フォーマットエラーのリスク
    let windowsJson = windows.map { window in
        """
        {
          "title": "\(window.title)",
          "x": \(window.x)
        }
        """
    }.joined(separator: ",")

    let jsonResult = "{\"windows\": [\(windowsJson)]}"
    return .init(content: [.text(jsonResult)], isError: false)
}
```

### Response Type Naming Convention

| 用途 | 命名パターン | 例 |
|------|-------------|-----|
| 一覧取得 | `{Domain}ListResponse` | `WindowListResponse`, `ApplicationListResponse` |
| 単一操作結果 | `{Action}{Domain}Response` | `LaunchApplicationResponse`, `QuitApplicationResponse` |

### JSONEncoder Settings

```swift
let encoder = JSONEncoder()
encoder.outputFormatting = [.prettyPrinted, .sortedKeys]  // 読みやすく、キー順序を安定化
```

- `.prettyPrinted`: 整形されたJSON出力（デバッグ・ログ確認が容易）
- `.sortedKeys`: キーをアルファベット順にソート（差分比較が容易）

---

## Testing & Debugging

### MCP Inspector

```bash
# MCPサーバーのデバッグ（MCP Builder推奨）
npx @modelcontextprotocol/inspector swift run WorkspaceMCP
```

### Unit Testing Pattern

Swift Testingを使用（testing.md参照）:

```swift
import Testing
@testable import WorkspaceMCP

@Suite("Launch Application Tool")
struct LaunchApplicationToolTests {
    
    @Test("launches Safari successfully")
    func launchSafari() async throws {
        let mockService = MockAccessibilityService()
        mockService.stubbedApp = TestApplications.safari
        
        let tool = LaunchApplicationTool(service: mockService)
        let result = try await tool.execute(bundleId: "com.apple.Safari")
        
        #expect(result.success == true)
        #expect(mockService.launchedBundleId == "com.apple.Safari")
    }
}
```

---

## Performance Optimization

### Parallel Async Operations

```swift
// ✅ Good: 並列実行（MCP Builder推奨）
let results = await withTaskGroup(of: WindowInfo.self) { group in
    for windowId in windowIds {
        group.addTask {
            await fetchWindowInfo(windowId)
        }
    }
    var allResults: [WindowInfo] = []
    for await result in group {
        allResults.append(result)
    }
    return allResults
}

// ❌ Bad: 逐次実行（遅い）
var results: [WindowInfo] = []
for windowId in windowIds {
    let result = await fetchWindowInfo(windowId)
    results.append(result)
}
```

---

## Security & Permissions

### Required Entitlements

- `com.apple.security.automation.apple-events`: AppleScript実行
- Accessibility権限: システム環境設定で手動有効化

### Privacy

- ユーザーの明示的な権限付与が必須
- 権限エラー時は適切なガイダンスを提供

---

## Performance Considerations

### Caching

```swift
// 実行中アプリケーションのキャッシュ
actor ApplicationCache {
    private var apps: [String: NSRunningApplication] = [:]
    
    func get(_ bundleId: String) async -> NSRunningApplication? {
        if let cached = apps[bundleId], cached.isTerminated == false {
            return cached
        }
        // 再取得とキャッシュ更新
    }
}
```

### Throttling

- Accessibility API呼び出しは重い操作
- 頻繁なポーリングは避ける
- 必要な情報のみ取得

---

## Package Structure

### Package.swift Pattern

```swift
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MacOSWorkspaceMCP",
    platforms: [.macOS(.v15)],
    dependencies: [
        .package(url: "https://github.com/modelcontextprotocol/swift-sdk", from: "0.10.0")
    ],
    targets: [
        .executableTarget(
            name: "MacOSWorkspaceMCP",
            dependencies: [
                .product(name: "MCP", package: "swift-sdk")
            ],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        )
    ]
)
```

---

## References

- [MCP Swift SDK](https://github.com/modelcontextprotocol/swift-sdk) - 公式Swift SDK
- [MCP Specification](https://modelcontextprotocol.io/specification/2025-03-26) - プロトコル仕様
- [ClaudeSkills MCP Builder](https://claude-plugins.dev/skills/@AutumnsGrove/ClaudeSkills/mcp-builder) - ベストプラクティス
- [MCP Inspector](https://github.com/modelcontextprotocol/inspector) - デバッグツール
- [Swift Concurrency](https://docs.swift.org/swift-book/LanguageGuide/Concurrency.html) - 並行性ガイド

---

## Notes

- Accessibility APIとNSAppleScriptは相補的に使用
- 可能な限りAccessibility APIを優先（パフォーマンス・信頼性）
- AppleScriptは最後の手段として使用
- すべての外部制御操作はasyncで実装
- エラーハンドリングは必須（権限・存在確認）
- MCP Builder Best Practicesに準拠したツール設計
- 入力検証とエラーレスポンスは常に明示的に

---

**Updated**: 2025-12-12
**Reason**: MCPResultEncoder を追加し、パラメータ型を [String: Value] に統一
