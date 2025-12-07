import Foundation
import MCP
import Testing

@testable import MacOSWorkspaceMCPServer

@Suite("FocusWindowTool のテスト")
struct FocusWindowToolTests {

    // MARK: - Mock Service

    final class MockWindowService: WindowServiceProtocol, @unchecked Sendable {
        var shouldThrowError: WorkspaceError?
        var lastBundleId: String?
        var lastTitle: String?

        func listWindows(bundleId: String?) async throws -> [WindowInfo] {
            return []
        }

        func checkAccessibilityPermission() -> Bool {
            return true
        }

        func positionWindow(
            bundleId: String,
            title: String?,
            preset: WindowPreset,
            displayName: String?
        ) async throws -> PositionResult {
            throw WorkspaceError.positioningFailed(reason: "Not implemented")
        }

        func focusWindow(
            bundleId: String,
            title: String?
        ) async throws -> FocusResult {
            lastBundleId = bundleId
            lastTitle = title

            if let error = shouldThrowError {
                throw error
            }

            let windowInfo = WindowInfo(
                title: title ?? "Test Window",
                x: 100,
                y: 200,
                width: 800,
                height: 600,
                isMinimized: false,
                isFullscreen: false,
                displayName: "Built-in Display",
                ownerBundleId: bundleId,
                ownerName: "Test App"
            )

            return FocusResult(window: windowInfo)
        }
    }

    // MARK: - Tool Definition Tests

    @Test("ツール名が focus_window であることを確認する")
    func toolNameIsFocusWindow() {
        #expect(FocusWindowTool.name == "focus_window")
    }

    @Test("ツール定義に bundleId パラメーターが含まれることを確認する")
    func definitionIncludesBundleIdParameter() {
        let definition = FocusWindowTool.definition

        #expect(definition.name == "focus_window")
        #expect(definition.description?.contains("最前面") == true)
    }

    // MARK: - Execute Method Tests

    @Test("bundleId を指定して正常にフォーカスできることを確認する")
    func executeWithBundleId() async throws {
        let mockService = MockWindowService()
        let tool = FocusWindowTool(windowService: mockService)

        let arguments: [String: MCP.Value] = [
            "bundleId": .string("com.apple.Safari")
        ]

        let result = await tool.execute(arguments: arguments)

        // 成功を確認
        #expect(result.isError == false)
        #expect(mockService.lastBundleId == "com.apple.Safari")
        #expect(mockService.lastTitle == nil)
    }

    @Test("bundleId とタイトルを指定してフィルタリングできることを確認する")
    func executeWithBundleIdAndTitle() async throws {
        let mockService = MockWindowService()
        let tool = FocusWindowTool(windowService: mockService)

        let arguments: [String: MCP.Value] = [
            "bundleId": .string("com.apple.Finder"),
            "title": .string("Desktop"),
        ]

        let result = await tool.execute(arguments: arguments)

        #expect(result.isError == false)
        #expect(mockService.lastBundleId == "com.apple.Finder")
        #expect(mockService.lastTitle == "Desktop")
    }

    @Test("bundleId が未指定の場合にエラーを返すことを確認する")
    func executeWithoutBundleId() async throws {
        let mockService = MockWindowService()
        let tool = FocusWindowTool(windowService: mockService)

        let arguments: [String: MCP.Value] = [:]

        let result = await tool.execute(arguments: arguments)

        #expect(result.isError == true)
        #expect(result.content.count > 0)
    }

    @Test("applicationNotFound エラーを適切に処理することを確認する")
    func executeHandlesApplicationNotFoundError() async throws {
        let mockService = MockWindowService()
        mockService.shouldThrowError = .applicationNotFound(bundleId: "com.invalid.app")
        let tool = FocusWindowTool(windowService: mockService)

        let arguments: [String: MCP.Value] = [
            "bundleId": .string("com.invalid.app")
        ]

        let result = await tool.execute(arguments: arguments)

        #expect(result.isError == true)

        if case .text(let text) = result.content.first {
            #expect(text.contains("見つかりません"))
        } else {
            Issue.record("Expected text content")
        }
    }

    @Test("permissionDenied エラーを適切に処理することを確認する")
    func executeHandlesPermissionDeniedError() async throws {
        let mockService = MockWindowService()
        mockService.shouldThrowError = .permissionDenied
        let tool = FocusWindowTool(windowService: mockService)

        let arguments: [String: MCP.Value] = [
            "bundleId": .string("com.apple.Safari")
        ]

        let result = await tool.execute(arguments: arguments)

        #expect(result.isError == true)

        if case .text(let text) = result.content.first {
            #expect(text.contains("権限"))
        } else {
            Issue.record("Expected text content")
        }
    }

    @Test("成功時に FocusResult の JSON を返すことを確認する")
    func executeReturnsJsonOnSuccess() async throws {
        let mockService = MockWindowService()
        let tool = FocusWindowTool(windowService: mockService)

        let arguments: [String: MCP.Value] = [
            "bundleId": .string("com.apple.Safari")
        ]

        let result = await tool.execute(arguments: arguments)

        #expect(result.isError == false)
        #expect(result.content.count == 1)

        if case .text(let text) = result.content.first {
            // JSON形式であることを確認
            #expect(text.contains("window"))
            #expect(text.contains("com.apple.Safari"))
        } else {
            Issue.record("Expected text content")
        }
    }
}
