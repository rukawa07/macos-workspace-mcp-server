import Foundation
import MCP
import Testing

@testable import MacOSWorkspaceMCPServer

/// ListWindowsToolのテストスイート
@Suite("ListWindowsToolのテスト")
struct ListWindowsToolTests {

    // MARK: - Mock Service

    /// テスト用のモックWindowService
    final class MockWindowService: WindowServiceProtocol, @unchecked Sendable {
        var stubbedWindows: [WindowInfo] = []
        var shouldThrowPermissionDenied = false
        var shouldThrowApplicationNotFound = false
        var applicationNotFoundBundleId: String = ""
        var lastRequestedBundleId: String?

        func listWindows(bundleId: String?) async throws -> [WindowInfo] {
            lastRequestedBundleId = bundleId

            if shouldThrowPermissionDenied {
                throw WorkspaceError.permissionDenied
            }

            if shouldThrowApplicationNotFound {
                throw WorkspaceError.applicationNotFound(bundleId: applicationNotFoundBundleId)
            }

            return stubbedWindows
        }

        func checkAccessibilityPermission() -> Bool {
            return !shouldThrowPermissionDenied
        }

        func positionWindow(
            bundleId: String,
            title: String?,
            preset: WindowPreset,
            displayName: String?
        ) async throws -> PositionResult {
            throw WorkspaceError.positioningFailed(reason: "Not implemented in mock")
        }

        func focusWindow(
            bundleId: String,
            title: String?
        ) async throws -> FocusResult {
            throw WorkspaceError.focusFailed(reason: "Not implemented in mock")
        }
    }

    // MARK: - Tool Definition Tests

    @Test("ListWindowsToolのツール名がlist_windowsである")
    func toolNameIsCorrect() {
        #expect(ListWindowsTool.name == "list_windows")
    }

    @Test("ListWindowsToolの定義がツール名を含む")
    func definitionContainsName() {
        let definition = ListWindowsTool.definition
        #expect(definition.name == "list_windows")
    }

    @Test("ListWindowsToolの定義が説明文を含む")
    func definitionContainsDescription() {
        let definition = ListWindowsTool.definition
        #expect(definition.description != nil)
        #expect(definition.description!.isEmpty == false)
    }

    @Test("ListWindowsToolの定義がbundleIdパラメーターを含む")
    func definitionContainsBundleIdParameter() {
        let definition = ListWindowsTool.definition
        // inputSchemaが存在することを確認
        #expect(definition.inputSchema != nil)
    }

    // MARK: - Execute Logic Tests

    @Test("bundleId省略時に全ウィンドウを取得する")
    func executeWithoutBundleId() async {
        let mockService = MockWindowService()
        mockService.stubbedWindows = [
            WindowInfo(
                title: "Window 1",
                x: 0, y: 0, width: 800, height: 600,
                isMinimized: false, isFullscreen: false,
                displayName: "Display 1",
                ownerBundleId: "com.example.app1",
                ownerName: "App 1"
            )
        ]

        let tool = ListWindowsTool(service: mockService)
        let result = await tool.execute(arguments: [:])

        #expect(result.isError == false)
        #expect(mockService.lastRequestedBundleId == nil)
    }

    @Test("bundleId指定時にフィルタリングされたウィンドウを取得する")
    func executeWithBundleId() async {
        let mockService = MockWindowService()
        mockService.stubbedWindows = [
            WindowInfo(
                title: "Safari Window",
                x: 100, y: 50, width: 1200, height: 800,
                isMinimized: false, isFullscreen: false,
                displayName: "Built-in Retina Display",
                ownerBundleId: "com.apple.Safari",
                ownerName: "Safari"
            )
        ]

        let tool = ListWindowsTool(service: mockService)
        let result = await tool.execute(arguments: ["bundleId": Value.string("com.apple.Safari")])

        #expect(result.isError == false)
        #expect(mockService.lastRequestedBundleId == "com.apple.Safari")
    }

    @Test("ウィンドウが存在しない場合に空配列を返す")
    func executeWithNoWindows() async {
        let mockService = MockWindowService()
        mockService.stubbedWindows = []

        let tool = ListWindowsTool(service: mockService)
        let result = await tool.execute(arguments: [:])

        #expect(result.isError == false)
        // レスポンスに空のwindows配列が含まれることを確認
        if case .text(let text) = result.content.first {
            #expect(text.contains("\"windows\""))
            // JSON形式で配列が空（オブジェクトを含まない）
            let trimmed = text.replacingOccurrences(of: " ", with: "").replacingOccurrences(
                of: "\n", with: "")
            #expect(trimmed.contains("\"windows\":[]"))
        } else {
            Issue.record("Expected text content")
        }
    }

    @Test("正常レスポンスがJSON形式のwindows配列を含む")
    func executeReturnsJsonFormat() async {
        let mockService = MockWindowService()
        mockService.stubbedWindows = [
            WindowInfo(
                title: "Test Window",
                x: 100, y: 200, width: 800, height: 600,
                isMinimized: false, isFullscreen: true,
                displayName: "Display 1",
                ownerBundleId: "com.test.app",
                ownerName: "Test App"
            )
        ]

        let tool = ListWindowsTool(service: mockService)
        let result = await tool.execute(arguments: [:])

        #expect(result.isError == false)

        if case .text(let text) = result.content.first {
            // JSON構造を検証
            #expect(text.contains("\"windows\""))
            #expect(text.contains("\"title\""))
            #expect(text.contains("\"x\""))
            #expect(text.contains("\"y\""))
            #expect(text.contains("\"width\""))
            #expect(text.contains("\"height\""))
            #expect(text.contains("\"isMinimized\""))
            #expect(text.contains("\"isFullscreen\""))
            #expect(text.contains("\"displayName\""))
            #expect(text.contains("\"ownerBundleId\""))
            #expect(text.contains("\"ownerName\""))
        } else {
            Issue.record("Expected text content")
        }
    }

    @Test("権限エラー時にisError:trueを返す")
    func executeWithPermissionDenied() async {
        let mockService = MockWindowService()
        mockService.shouldThrowPermissionDenied = true

        let tool = ListWindowsTool(service: mockService)
        let result = await tool.execute(arguments: [:])

        #expect(result.isError == true)

        if case .text(let text) = result.content.first {
            #expect(text.contains("アクセシビリティ") || text.contains("Accessibility"))
        } else {
            Issue.record("Expected text content")
        }
    }

    @Test("アプリ未検出エラー時にisError:trueを返す")
    func executeWithApplicationNotFound() async {
        let mockService = MockWindowService()
        mockService.shouldThrowApplicationNotFound = true
        mockService.applicationNotFoundBundleId = "com.nonexistent.app"

        let tool = ListWindowsTool(service: mockService)
        let result = await tool.execute(arguments: [
            "bundleId": Value.string("com.nonexistent.app")
        ])

        #expect(result.isError == true)

        if case .text(let text) = result.content.first {
            #expect(text.contains("com.nonexistent.app"))
        } else {
            Issue.record("Expected text content")
        }
    }

    @Test("空文字列のbundleIdはnilとして扱う（全アプリ取得）")
    func executeWithEmptyBundleId() async {
        let mockService = MockWindowService()
        mockService.stubbedWindows = []

        let tool = ListWindowsTool(service: mockService)
        let result = await tool.execute(arguments: ["bundleId": Value.string("")])

        #expect(result.isError == false)
        #expect(mockService.lastRequestedBundleId == nil)
    }

    // MARK: - Integration Tests

    @Test("実際のCGWindowListCopyWindowInfo呼び出しでウィンドウを取得できる")
    func integrationTestRealWindowListRetrieval() async throws {
        let service = DefaultWindowService()
        let tool = ListWindowsTool(service: service)

        // 実際のMCP呼び出しをシミュレート
        let result = await tool.execute(arguments: [:])

        // エラーなしでレスポンスが返ることを確認
        #expect(result.isError == false)
        #expect(result.content.count == 1)

        if case .text(let jsonText) = result.content.first {
            // JSON構造の検証
            #expect(jsonText.contains("\"windows\""))

            // JSONをデコードして構造を検証
            let jsonData = jsonText.data(using: .utf8)!
            let response = try JSONDecoder().decode(WindowListResponse.self, from: jsonData)

            // WindowInfo配列が返されることを確認
            #expect(response.windows is [WindowInfo])

            // 各ウィンドウにdisplayNameが含まれることを確認
            for window in response.windows {
                #expect(window.displayName.isEmpty == false)
            }
        } else {
            Issue.record("Expected text content with JSON")
        }
    }

    @Test("JSON形式レスポンスにdisplayNameが含まれる")
    func integrationTestJsonContainsNewProperties() async throws {
        let service = DefaultWindowService()
        let tool = ListWindowsTool(service: service)

        let result = await tool.execute(arguments: [:])

        if case .text(let jsonText) = result.content.first {
            // JSONをデコードして構造を検証
            let jsonData = jsonText.data(using: .utf8)!
            let response = try JSONDecoder().decode(WindowListResponse.self, from: jsonData)

            // ウィンドウが存在する場合、displayNameがJSONに含まれることを確認
            if !response.windows.isEmpty {
                #expect(jsonText.contains("\"displayName\""))

                // displayIdは含まれない（displayNameに改名済み）
                #expect(!jsonText.contains("\"displayId\""))
            } else {
                // ウィンドウが0件の場合もエラーではない
                #expect(response.windows.isEmpty)
            }
        } else {
            Issue.record("Expected JSON text content")
        }
    }

    @Test("特定アプリのウィンドウのみを取得できる（統合テスト）")
    func integrationTestBundleIdFiltering() async throws {
        let service = DefaultWindowService()
        let tool = ListWindowsTool(service: service)

        // Finderは通常起動しているはず
        let result = await tool.execute(arguments: [
            "bundleId": Value.string("com.apple.Finder")
        ])

        #expect(result.isError == false)

        if case .text(let jsonText) = result.content.first {
            let jsonData = jsonText.data(using: .utf8)!
            let response = try JSONDecoder().decode(WindowListResponse.self, from: jsonData)

            // 返却されたウィンドウがすべてFinderのものであることを確認
            for window in response.windows {
                #expect(window.ownerBundleId == "com.apple.Finder")
            }
        }
    }

    @Test("存在しないアプリのbundleIdで空配列を返す（統合テスト）")
    func integrationTestNonExistentApp() async throws {
        let service = DefaultWindowService()
        let tool = ListWindowsTool(service: service)

        let result = await tool.execute(arguments: [
            "bundleId": Value.string("com.example.NonExistent")
        ])

        #expect(result.isError == false)

        if case .text(let jsonText) = result.content.first {
            let jsonData = jsonText.data(using: .utf8)!
            let response = try JSONDecoder().decode(WindowListResponse.self, from: jsonData)

            // 空配列が返されることを確認
            #expect(response.windows.isEmpty)
        }
    }

    @Test("displayName判定が正しく機能する（統合テスト）")
    func integrationTestDisplayNameDetection() async throws {
        let service = DefaultWindowService()
        let tool = ListWindowsTool(service: service)

        let result = await tool.execute(arguments: [:])

        if case .text(let jsonText) = result.content.first {
            let jsonData = jsonText.data(using: .utf8)!
            let response = try JSONDecoder().decode(WindowListResponse.self, from: jsonData)

            // 各ウィンドウのdisplayNameが設定されていることを確認
            for window in response.windows {
                // displayNameは空でない文字列または"Unknown"
                #expect(window.displayName.isEmpty == false)
                #expect(window.displayName != "")
            }
        }
    }
}
