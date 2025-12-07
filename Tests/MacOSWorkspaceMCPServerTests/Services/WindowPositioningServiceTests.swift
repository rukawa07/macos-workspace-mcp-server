import Foundation
import Testing

@testable import MacOSWorkspaceMCPServer

@Suite("WindowService ウィンドウ配置機能のテスト")
struct WindowPositioningServiceTests {

    // MARK: - Protocol Definition Tests

    @Test("WindowServiceProtocolがpositionWindowメソッドを定義している")
    func protocolDefinesPositionWindowMethod() async throws {
        let service: any WindowServiceProtocol = DefaultWindowService()

        // プロトコルメソッドが存在することを確認（コンパイルが通ればOK）
        _ = try? await service.positionWindow(
            bundleId: "com.apple.Finder",
            title: nil,
            preset: .left,
            displayName: nil
        )

        #expect(Bool(true))
    }

    // MARK: - Error Handling Tests

    @Test("権限がない場合にpermissionDeniedエラーをスローする")
    func throwsPermissionDeniedWhenNoPermission() async throws {
        // 実環境ではAccessibility権限がないとエラーになる
        // このテストは権限がない場合のエラーハンドリングを確認
        let service = DefaultWindowService()

        // 権限がない場合のみテストが意味を持つ
        if !service.checkAccessibilityPermission() {
            await #expect(throws: WorkspaceError.self) {
                try await service.positionWindow(
                    bundleId: "com.apple.Finder",
                    title: nil,
                    preset: .left,
                    displayName: nil
                )
            }
        } else {
            // 権限がある場合はスキップ（実際の操作が発生するため）
            #expect(Bool(true))
        }
    }

    @Test("存在しないディスプレイ名を指定するとdisplayNotFoundエラーをスローする")
    func throwsDisplayNotFoundForInvalidDisplay() async throws {
        let service = DefaultWindowService()

        // 権限がある場合のみテスト
        guard service.checkAccessibilityPermission() else {
            #expect(Bool(true))
            return
        }

        await #expect(throws: WorkspaceError.self) {
            try await service.positionWindow(
                bundleId: "com.apple.Finder",
                title: nil,
                preset: .fullscreen,
                displayName: "NonExistent Display XYZ123"
            )
        }
    }

    @Test("ウィンドウが見つからない場合にwindowNotFoundエラーをスローする")
    func throwsWindowNotFoundForInvalidBundleId() async throws {
        let service = DefaultWindowService()

        // 権限がある場合のみテスト
        guard service.checkAccessibilityPermission() else {
            #expect(Bool(true))
            return
        }

        await #expect(throws: WorkspaceError.self) {
            try await service.positionWindow(
                bundleId: "com.example.NonExistentApp123",
                title: nil,
                preset: .left,
                displayName: nil
            )
        }
    }
}

// MARK: - Mock Window Service for Testing

/// テスト用モックWindowService
final class MockWindowService: WindowServiceProtocol, @unchecked Sendable {
    var hasPermission = true
    var stubbedWindows: [WindowInfo] = []
    var positionWindowCalled = false
    var lastPositionRequest:
        (bundleId: String, title: String?, preset: WindowPreset, displayName: String?)?
    var positionResult: PositionResult?
    var errorToThrow: WorkspaceError?

    func listWindows(bundleId: String?) async throws -> [WindowInfo] {
        if !hasPermission {
            throw WorkspaceError.permissionDenied
        }

        if let bundleId = bundleId {
            return stubbedWindows.filter { $0.ownerBundleId == bundleId }
        }
        return stubbedWindows
    }

    func checkAccessibilityPermission() -> Bool {
        return hasPermission
    }

    func positionWindow(
        bundleId: String,
        title: String?,
        preset: WindowPreset,
        displayName: String?
    ) async throws -> PositionResult {
        positionWindowCalled = true
        lastPositionRequest = (bundleId, title, preset, displayName)

        if let error = errorToThrow {
            throw error
        }

        guard hasPermission else {
            throw WorkspaceError.permissionDenied
        }

        if let result = positionResult {
            return result
        }

        // デフォルトの戻り値
        let windowInfo =
            stubbedWindows.first
            ?? WindowInfo(
                title: "Test",
                x: 0,
                y: 0,
                width: 960,
                height: 1055,
                isMinimized: false,
                isFullscreen: false,
                displayName: "Built-in Display",
                ownerBundleId: bundleId,
                ownerName: "TestApp"
            )

        return PositionResult(
            window: windowInfo,
            appliedPreset: preset,
            displayName: displayName ?? "Built-in Display"
        )
    }

    func focusWindow(
        bundleId: String,
        title: String?
    ) async throws -> FocusResult {
        if let error = errorToThrow {
            throw error
        }

        guard hasPermission else {
            throw WorkspaceError.permissionDenied
        }

        let windowInfo =
            stubbedWindows.first
            ?? WindowInfo(
                title: "Test",
                x: 0,
                y: 0,
                width: 960,
                height: 1055,
                isMinimized: false,
                isFullscreen: false,
                displayName: "Built-in Display",
                ownerBundleId: bundleId,
                ownerName: "TestApp"
            )

        return FocusResult(window: windowInfo)
    }
}

// MARK: - Mock Service Tests

@Suite("MockWindowService のテスト")
struct MockWindowServiceTests {

    @Test("モックサービスがpositionWindowを呼び出せる")
    func mockServiceCanCallPositionWindow() async throws {
        let mock = MockWindowService()
        mock.hasPermission = true

        let result = try await mock.positionWindow(
            bundleId: "com.apple.Safari",
            title: "Test",
            preset: .left,
            displayName: "Display"
        )

        #expect(mock.positionWindowCalled == true)
        #expect(mock.lastPositionRequest?.bundleId == "com.apple.Safari")
        #expect(mock.lastPositionRequest?.title == "Test")
        #expect(mock.lastPositionRequest?.preset == .left)
        #expect(result.appliedPreset == .left)
    }

    @Test("モックサービスがエラーをスローできる")
    func mockServiceCanThrowError() async throws {
        let mock = MockWindowService()
        mock.errorToThrow = .windowNotFound(bundleId: "test", title: nil)

        await #expect(throws: WorkspaceError.self) {
            try await mock.positionWindow(
                bundleId: "test",
                title: nil,
                preset: .left,
                displayName: nil
            )
        }
    }

    @Test("モックサービスが権限エラーをスローできる")
    func mockServiceCanThrowPermissionError() async throws {
        let mock = MockWindowService()
        mock.hasPermission = false

        await #expect(throws: WorkspaceError.self) {
            try await mock.positionWindow(
                bundleId: "test",
                title: nil,
                preset: .left,
                displayName: nil
            )
        }
    }

    @Test("モックサービスがカスタム結果を返せる")
    func mockServiceCanReturnCustomResult() async throws {
        let mock = MockWindowService()

        let customWindow = WindowInfo(
            title: "Custom Window",
            x: 100,
            y: 200,
            width: 500,
            height: 400,
            isMinimized: false,
            isFullscreen: false,
            displayName: "Test Display",
            ownerBundleId: "com.test.app",
            ownerName: "TestApp"
        )

        mock.positionResult = PositionResult(
            window: customWindow,
            appliedPreset: .topRight,
            displayName: "Test Display"
        )

        let result = try await mock.positionWindow(
            bundleId: "com.test.app",
            title: nil,
            preset: .topRight,
            displayName: nil
        )

        #expect(result.window.title == "Custom Window")
        #expect(result.appliedPreset == .topRight)
        #expect(result.displayName == "Test Display")
    }
}
