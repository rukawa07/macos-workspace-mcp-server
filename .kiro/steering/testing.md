# Testing Standards

MacOSWorkspaceMCPServerにおけるテスト戦略とSwift Testingを使用したモダンテスト実装パターン

---

## Testing Philosophy

- **Modern Swift Testing**: Swift 6標準のTestingフレームワークを使用
- **振る舞い駆動**: 実装ではなく振る舞いをテスト
- **高速・信頼性**: モックで外部依存を排除し高速化
- **クリティカルパス優先**: 100%カバレッジより重要機能の深いテスト

---

## Japanese Test Case Naming Policy

**必須ルール: テストケースの説明は日本語で書く**

### 基本方針

- **@Test の説明文**: 必ず日本語で記述
- **@Suite の説明文**: 必ず日本語で記述  
- **関数名**: 英語（Swift命名規則に従う）
- **コメント**: 日本語で記述

### パターン例

```swift
@Suite("ApplicationService のテスト")
struct ApplicationServiceTests {
    
    @Test("アプリケーション起動が成功した場合、プロセスIDとアプリ名を返す")
    func launchApplicationSuccess() async throws {
        let service = DefaultApplicationService()
        let result = try await service.launchApplication(bundleId: "com.apple.Safari")
        
        #expect(result.processId > 0)
        #expect(result.appName.isEmpty == false)
    }
    
    @Test("存在しないbundle IDの場合、applicationNotFoundエラーを投げる")
    func throwsErrorWhenAppNotFound() async throws {
        let service = DefaultApplicationService()
        
        await #expect(throws: WorkspaceError.applicationNotFound) {
            try await service.launchApplication(bundleId: "com.invalid.app")
        }
    }
}
```

### 説明文の命名パターン

| テスト対象 | 説明文パターン | 例 |
|-----------|--------------|-----|
| 正常系 | 「〜の場合、〜を返す」 | 「起動成功の場合、プロセスIDを返す」 |
| 異常系 | 「〜の場合、〜エラーを投げる」 | 「存在しないアプリの場合、NotFoundエラーを投げる」 |
| 状態検証 | 「〜が〜であることを確認する」 | 「起動後、wasAlreadyRunningがfalseであることを確認する」 |
| 境界値 | 「〜が空/nilの場合、〜」 | 「bundleIdが空文字列の場合、invalidParameterエラーを投げる」 |
| プロトコル | 「〜が〜を定義している」 | 「ApplicationServiceProtocolがlaunchメソッドを定義している」 |

### ✅ 良い例

```swift
@Test("起動中アプリの一覧に、bundle ID・名前・プロセスIDが含まれる")
@Test("Accessibility権限がない場合、permissionDeniedエラーを返す")
@Test("既に起動中のアプリを起動した場合、wasAlreadyRunningがtrueになる")
@Test("アプリ終了が成功した場合、終了したアプリ名を返す")
@Test("パラメーター 'bundleId' が必須であることを確認する")
```

### ❌ 悪い例

```swift
@Test("test launch app")  // 英語 & 不明瞭
@Test("テスト")  // 何をテストするか不明
@Test("launchApplication()が正常に動作する")  // 実装詳細に言及
@Test("launches successfully")  // 英語
```

---

## TDD Unit Test Policy

### 許可されるテストスタイル

TDDにおけるユニットテストは以下の2種類のみ許可する:

1. **出力値ベーステスト (Output-Based Testing)**
   - 関数/メソッドの戻り値を検証
   - 入力に対する出力の正確性を確認
   - 最も推奨されるスタイル

2. **状態ベーステスト (State-Based Testing)**
   - 操作後のオブジェクト状態を検証
   - プロパティの変化を確認
   - 副作用の結果を検証

```swift
// ✅ Good: 出力値ベーステスト
@Test("calculates correct bundle ID from app name")
func resolveBundleId() async throws {
    let resolver = BundleIdResolver()
    let bundleId = try await resolver.resolve(appName: "Safari")
    #expect(bundleId == "com.apple.Safari")
}

// ✅ Good: 状態ベーステスト
@Test("updates running applications list after launch")
func updateAppList() async throws {
    let manager = ApplicationManager()
    try await manager.launch(bundleId: "com.apple.Safari")
    #expect(manager.runningApplications.contains("com.apple.Safari"))
}
```

### 禁止されるテストスタイル

以下のテストスタイルは壊れやすく、メンテナンスコストが高いため禁止:

1. **ファイル内容の文字列検証テスト**
   - ファイルを読み込んで文字列マッチングするテスト
   - 実装詳細に依存し、リファクタリングで壊れやすい

2. **コミュニケーションベーステスト（過度なモック検証）**
   - 内部メソッド呼び出し順序の検証
   - 外部から観測できない振る舞いのテスト

```swift
// ❌ Bad: ファイル内容の文字列検証
@Test("generates correct config file")
func configFileContent() throws {
    let generator = ConfigGenerator()
    generator.generate(to: "/tmp/config.json")
    let content = try String(contentsOfFile: "/tmp/config.json")
    #expect(content.contains("\"version\": \"1.0\""))  // 壊れやすい
}

// ❌ Bad: 過度なモック検証（コミュニケーションベース）
@Test("calls methods in correct order")
func methodOrder() async throws {
    let mock = MockService()
    let tool = LaunchTool(service: mock)
    try await tool.execute(bundleId: "com.apple.Safari")
    #expect(mock.callOrder == ["validate", "prepare", "launch"])  // 実装詳細
}
```

### テスト不可能なタスクの扱い

以下の場合はテストを書かずに実装してよい:

- ファイルシステムへの書き込みのみを行う機能
- 外部APIへの副作用のみを持つ機能
- 出力値も状態変化も検証できない機能

ただし、可能な限り設計を見直し、テスト可能な形に分離することを推奨する。

```swift
// テスト可能な設計への分離例
// Before: テスト不可能
func saveConfig() {
    let content = generateConfigContent()
    FileManager.write(content, to: path)  // 副作用のみ
}

// After: テスト可能に分離
func generateConfigContent() -> ConfigData {  // ✅ 出力値をテスト可能
    return ConfigData(version: "1.0", ...)
}

func saveConfig() {
    let content = generateConfigContent()
    FileManager.write(content, to: path)
}
```

---

## Technology Stack

### Core Tools

- **Xcode 16.1以上**: Swift Testing標準サポート
- **Swift 6.0**: Swift Testing + strict concurrency対応
- **Swift Testing**: Xcode 16標準のテストフレームワーク
- **Swift Package Manager**: 依存関係管理

### Package.swift Configuration

```swift
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MacOSWorkspaceMCPServer",
    platforms: [.macOS(.v15)],
    dependencies: [
        .package(url: "https://github.com/modelcontextprotocol/swift-sdk", from: "0.10.0")
    ],
    targets: [
        .executableTarget(
            name: "MacOSWorkspaceMCPServer",
            dependencies: [
                .product(name: "MCPSwiftSDK", package: "swift-sdk")
            ],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "MacOSWorkspaceMCPServerTests",
            dependencies: ["MacOSWorkspaceMCPServer"]
        )
    ]
)
```

---

## Test Organization

### Directory Structure

```text
Tests/
└── MacOSWorkspaceMCPServerTests/
    ├── Tools/
    │   ├── LaunchApplicationToolTests.swift
    │   ├── QuitApplicationToolTests.swift
    │   └── WindowManagementToolTests.swift
    ├── Services/
    │   ├── AccessibilityServiceTests.swift
    │   └── AppleScriptServiceTests.swift
    ├── Mocks/
    │   ├── MockAccessibilityService.swift
    │   └── MockNSWorkspace.swift
    └── Fixtures/
        └── TestApplications.swift
```

### Naming Conventions

- **Test files**: `{TargetName}Tests.swift`
- **Mock classes**: `Mock{ProtocolName}.swift`
- **Fixtures**: `Test{Domain}.swift`
- **Test functions**: `test{Behavior}()`または descriptive name

---

## Swift Testing Pattern

### Basic Test Structure

```swift
import Testing
@testable import MacOSWorkspaceMCPServer

@Suite("LaunchApplicationTool")
struct LaunchApplicationToolTests {
    
    @Test("launches application successfully when app exists")
    func launchExistingApplication() async throws {
        // Given
        let mockService = MockAccessibilityService()
        mockService.stubbedApp = TestApplications.safari
        let tool = LaunchApplicationTool(service: mockService)
        let bundleId = "com.apple.Safari"
        
        // When
        let result = try await tool.execute(bundleId: bundleId)
        
        // Then
        #expect(result.success == true)
        #expect(mockService.launchedBundleId == bundleId)
    }
    
    @Test("throws error when application not found")
    func launchNonexistentApplication() async throws {
        // Given
        let mockService = MockAccessibilityService()
        mockService.shouldThrowNotFound = true
        let tool = LaunchApplicationTool(service: mockService)
        let bundleId = "com.invalid.app"
        
        // When & Then
        await #expect(throws: WorkspaceError.applicationNotFound(bundleId)) {
            try await tool.execute(bundleId: bundleId)
        }
    }
}
```

### Suite Organization

- **@Suite**: テスト対象のグループ化（クラス単位、機能単位）
- **@Test**: 個別のテストケース
- **Descriptive names**: テスト名で振る舞いを明示

---

## Test Lifecycle

### Setup and Teardown

```swift
@Suite("AccessibilityService")
struct AccessibilityServiceTests {
    
    init() async throws {
        // Suite全体のセットアップ
    }
    
    deinit {
        // Suite全体のクリーンアップ
    }
    
    @Test("retrieves windows for application")
    func getWindows() async throws {
        // テストごとにインスタンス作成
        let service = AccessibilityService()
        
        // テスト実行
        let windows = try await service.getWindows(for: "com.apple.Safari")
        
        #expect(!windows.isEmpty)
        // スコープ終了で自動クリーンアップ
    }
}
```

### Shared Test Context

```swift
@Suite("Window Management")
struct WindowManagementTests {
    let mockService: MockAccessibilityService
    
    init() {
        // テストごとに新しいインスタンス作成
        self.mockService = MockAccessibilityService()
    }
    
    @Test("sets window position")
    func setPosition() async throws {
        let tool = WindowManagementTool(service: mockService)
        // テスト実行
    }
}
```

---

## Test Types

### Unit Tests

- **対象**: 単一のTool/Service
- **依存**: すべてモック化
- **速度**: 非常に高速（外部API呼び出しなし）

```swift
@Suite("AccessibilityService Unit Tests")
struct AccessibilityServiceUnitTests {
    
    @Test("parses window information correctly")
    func parseWindowInfo() {
        // プロトコルベースでテスト
        let mockService = MockAccessibilityService()
        mockService.stubbedWindows = TestApplications.safari.withWindows(2)
        
        #expect(mockService.stubbedWindows.count == 2)
    }
}
```

### Integration Tests

- **対象**: 複数コンポーネントの連携
- **依存**: 外部依存のみモック
- **速度**: 中程度

```swift
@Suite("Window Management Integration", .tags(.integration))
struct WindowManagementIntegrationTests {
    
    @Test("launches app and positions window")
    func launchAndPosition() async throws {
        // LaunchTool + WindowTool の連携テスト
        let mockService = MockAccessibilityService()
        let launchTool = LaunchApplicationTool(service: mockService)
        let windowTool = WindowManagementTool(service: mockService)
        
        try await launchTool.execute(bundleId: "com.apple.Safari")
        try await windowTool.setPosition(x: 100, y: 100)
        
        #expect(mockService.setPositionCalled == true)
    }
}
```

### End-to-End Tests

- **対象**: MCPサーバー全体のフロー
- **依存**: 最小限のモック
- **速度**: 低速
- **注意**: CI環境では権限問題でスキップ

```swift
@Suite("MCP Server E2E", .tags(.e2e), .disabled("Requires accessibility permissions"))
struct MCPServerE2ETests {
    
    @Test("processes tool request end-to-end")
    func endToEndFlow() async throws {
        // 実際のアプリケーション起動が必要
        // CI環境では無効化
    }
}
```

---

## Mocking Strategy

### Protocol-Based Mocking

```swift
// プロトコル定義
protocol AccessibilityServiceProtocol: Sendable {
    func getWindows(for bundleId: String) async throws -> [WindowInfo]
    func setWindowPosition(_ window: WindowInfo, to position: CGPoint) async throws
}

// 本番実装
final class AccessibilityService: AccessibilityServiceProtocol {
    func getWindows(for bundleId: String) async throws -> [WindowInfo] {
        // 実際のAccessibility API呼び出し
    }
    
    func setWindowPosition(_ window: WindowInfo, to position: CGPoint) async throws {
        // 実際のAPI呼び出し
    }
}

// モック実装
final class MockAccessibilityService: AccessibilityServiceProtocol {
    var stubbedWindows: [WindowInfo] = []
    var setPositionCalled = false
    var lastPosition: CGPoint?
    var shouldThrowNotFound = false
    var launchedBundleId: String?
    
    func getWindows(for bundleId: String) async throws -> [WindowInfo] {
        if shouldThrowNotFound {
            throw WorkspaceError.applicationNotFound(bundleId)
        }
        return stubbedWindows
    }
    
    func setWindowPosition(_ window: WindowInfo, to position: CGPoint) async throws {
        setPositionCalled = true
        lastPosition = position
    }
}
```

### Mock Guidelines

- **モック対象**: 外部システム（Accessibility API、NSWorkspace、NSAppleScript）
- **モック禁止**: テスト対象のシステム自体
- **Sendable準拠**: Swift 6 concurrency対応

---

## Assertions and Expectations

### Basic Expectations

```swift
// 等価性
#expect(actual == expected)

// Bool検証
#expect(result.success)
#expect(!result.isEmpty)

// Nil検証
#expect(value != nil)
#expect(optionalValue == nil)

// Collection検証
#expect(windows.count == 3)
#expect(windows.contains(where: { $0.title == "Safari" }))
```

### Error Expectations

```swift
// エラー発生を期待
#expect(throws: WorkspaceError.self) {
    try await operation()
}

// 特定のエラーを期待
#expect(throws: WorkspaceError.applicationNotFound("com.test")) {
    try await operation()
}

// エラーが発生しないことを期待
#expect(throws: Never.self) {
    try await operation()
}
```

### Custom Validation

```swift
// カスタム検証ロジック
#expect(window.position.x >= 0 && window.position.x <= 1920)
#expect(abs(window.position.x - expectedX) < 1.0, "Position tolerance check")
```

---

## Test Fixtures

### Test Data Factory

```swift
enum TestApplications {
    static let safari = TestApplication(
        bundleId: "com.apple.Safari",
        name: "Safari",
        processId: 1234
    )
    
    static let finder = TestApplication(
        bundleId: "com.apple.Finder",
        name: "Finder",
        processId: 100
    )
}

struct TestApplication: Sendable {
    let bundleId: String
    let name: String
    let processId: pid_t
    
    func withWindows(_ count: Int) -> [WindowInfo] {
        (0..<count).map { index in
            WindowInfo(
                id: "\(processId)-\(index)",
                title: "\(name) Window \(index + 1)",
                position: CGPoint(x: 0, y: 0),
                size: CGSize(width: 800, height: 600)
            )
        }
    }
}
```

### Fixture Guidelines

- **最小限**: 必要最小限のデータのみ
- **意図明確**: テストの意図がわかるデータ
- **再利用可能**: 複数テストで共有可能
- **Sendable準拠**: Swift 6対応

---

## Parameterized Tests

### Multiple Test Cases

```swift
@Suite("Window Position Validation")
struct WindowPositionTests {
    
    @Test("validates window positions",
          arguments: [
            (x: 0, y: 0, valid: true),
            (x: 100, y: 100, valid: true),
            (x: -10, y: 0, valid: false),
            (x: 0, y: -10, valid: false)
          ])
    func validatePosition(x: Int, y: Int, valid: Bool) {
        let position = CGPoint(x: x, y: y)
        let isValid = WindowValidator.isValid(position: position)
        
        #expect(isValid == valid)
    }
}
```

---

## Tags and Filtering

### Test Tags

```swift
extension Tag {
    @Tag static var integration: Self
    @Tag static var e2e: Self
    @Tag static var slow: Self
    @Tag static var requiresPermissions: Self
}

@Suite("Window Tests", .tags(.integration))
struct WindowIntegrationTests {
    
    @Test("fast test")
    func fastTest() {
        // 常に実行
    }
    
    @Test("slow operation", .tags(.slow))
    func slowTest() async throws {
        // タグでフィルタリング可能
    }
}
```

### Running Tagged Tests

```bash
# 特定のタグのみ実行
swift test --filter tag:integration

# タグを除外
swift test --skip tag:slow

# 複数タグ
swift test --filter "tag:integration && !tag:slow"
```

---

## Async Testing

### Concurrent Tests

```swift
@Suite("Concurrent Operations")
struct ConcurrentTests {
    
    @Test("handles multiple concurrent requests")
    func concurrentRequests() async throws {
        await withThrowingTaskGroup(of: Bool.self) { group in
            for i in 0..<10 {
                group.addTask {
                    try await operation(index: i)
                    return true
                }
            }
            
            var results: [Bool] = []
            for try await result in group {
                results.append(result)
            }
            
            #expect(results.count == 10)
            #expect(results.allSatisfy { $0 })
        }
    }
}
```

---

## Coverage Standards

### Target Coverage

- **Overall**: 70%以上
- **Critical Paths**: 90%以上（MCP tool handlers、主要サービス）
- **Edge Cases**: エラーハンドリング、権限チェック

### Coverage Collection

```bash
# テスト実行とカバレッジ収集
swift test --enable-code-coverage

# カバレッジレポート生成
xcrun llvm-cov report \
    .build/debug/MacOSWorkspaceMCPServerPackageTests.xctest/Contents/MacOS/MacOSWorkspaceMCPServerPackageTests \
    -instr-profile=.build/debug/codecov/default.profdata
```

### CI Integration

```yaml
# GitHub Actions
test:
  runs-on: macos-15
  steps:
    - uses: actions/checkout@v4
    - name: Run tests
      run: swift test --enable-code-coverage
    - name: Generate coverage report
      run: |
        xcrun llvm-cov export -format=lcov \
          .build/debug/WorkspaceMCPPackageTests.xctest/Contents/MacOS/WorkspaceMCPPackageTests \
          -instr-profile=.build/debug/codecov/default.profdata > coverage.lcov
    - name: Upload coverage
      uses: codecov/codecov-action@v3
```

---

## Performance Testing

### Time Limits

```swift
@Suite("Performance Tests")
struct PerformanceTests {
    
    @Test("window retrieval completes quickly", .timeLimit(.seconds(1)))
    func fastWindowRetrieval() async throws {
        let service = MockAccessibilityService()
        service.stubbedWindows = TestApplications.safari.withWindows(100)
        
        let windows = try await service.getWindows(for: "com.apple.Safari")
        #expect(windows.count == 100)
        // 1秒以内に完了しない場合は失敗
    }
}
```

---

## Test Execution Strategy

### Local Development

```bash
# すべてのテスト実行
swift test

# 特定のスイート実行
swift test --filter LaunchApplicationToolTests

# タグでフィルタリング
swift test --filter "tag:integration"
```

### CI/CD Pipeline

- **PR**: Unit tests + integration tests (permissions不要)
- **Main**: すべてのテスト（E2E除く）
- **Nightly**: E2Eテスト（Accessibility権限設定済み環境）

---

## Test Isolation

### Isolation Modes

```swift
// デフォルト: テストは並列実行可能
@Suite("Parallel Safe Tests")
struct ParallelTests {
    @Test func test1() { }
    @Test func test2() { }
}

// シリアル実行が必要な場合
@Suite("Serial Tests", .serialized)
struct SerialTests {
    @Test func test1() { }
    @Test func test2() { }
}
```

---

## Best Practices

### Test Quality

1. **1 Test = 1 Behavior**: 1つのテストで1つの振る舞いのみ検証
2. **Arrange-Act-Assert**: Given-When-Then構造を維持
3. **Descriptive Names**: テスト名で意図を明確に
4. **Fast Tests**: モックで高速化、E2Eは最小限
5. **Reliable Tests**: フレーキーテスト（時々失敗）は即修正

### Code Organization

```swift
// ✅ Good: 明確な振る舞い、1つの検証
@Test("launches Safari successfully")
func launchSafari() async throws {
    let result = try await tool.execute(bundleId: "com.apple.Safari")
    #expect(result.success)
}

// ❌ Bad: 複数の振る舞いを1つのテストで検証
@Test("application management")
func appManagement() async throws {
    try await tool.launch("com.apple.Safari")
    try await tool.quit("com.apple.Safari")
    try await tool.launch("com.apple.Finder")
    // 複数の振る舞いが混在
}
```

---

## Migration from XCTest

### Key Differences

| XCTest | Swift Testing |
|--------|---------------|
| `XCTestCase` subclass | `@Suite` struct |
| `func testExample()` | `@Test func example()` |
| `XCTAssertEqual(a, b)` | `#expect(a == b)` |
| `XCTAssertThrowsError` | `#expect(throws:)` |
| `setUp()`/`tearDown()` | `init()`/`deinit` |
| Test methods | Test functions |

### Example Migration

```swift
// Before (XCTest)
class MyTests: XCTestCase {
    func testExample() {
        XCTAssertEqual(1 + 1, 2)
    }
}

// After (Swift Testing)
@Suite("My Tests")
struct MyTests {
    @Test("addition works correctly")
    func addition() {
        #expect(1 + 1 == 2)
    }
}
```

---

## Notes

- Swift Testing は Xcode 16+ / Swift 6標準
- 外部依存なし、SPMで追加設定不要
- Sendable準拠でSwift 6 concurrency完全対応
- Accessibility APIは必ずプロトコルで抽象化
- E2Eテストは権限問題でCI環境では制限あり
- カバレッジは目標、品質の唯一の指標ではない

---

**Updated**: 2025-12-08
**Reason**: TDD Unit Test Policy追加（出力値/状態ベーステストのみ許可）
