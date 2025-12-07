import Foundation
import Testing
@testable import MacOSWorkspaceMCPServer

@Suite("WorkspaceError ウィンドウ配置エラーのテスト")
struct WindowPositioningErrorTests {

    // MARK: - windowNotFound

    @Test("windowNotFoundがbundle IDを含むメッセージを提供する")
    func windowNotFoundWithBundleIdOnly() {
        let error = WorkspaceError.windowNotFound(bundleId: "com.apple.Safari", title: nil)
        let message = error.userMessage

        #expect(message.contains("com.apple.Safari"))
        #expect(message.contains("ウィンドウ") || message.contains("window"))
        #expect(message.contains("見つかりません") || message.contains("not found"))
    }

    @Test("windowNotFoundがbundle IDとタイトルの両方を含むメッセージを提供する")
    func windowNotFoundWithBundleIdAndTitle() {
        let error = WorkspaceError.windowNotFound(
            bundleId: "com.apple.Safari",
            title: "Google"
        )
        let message = error.userMessage

        #expect(message.contains("com.apple.Safari"))
        #expect(message.contains("Google"))
    }

    @Test("windowNotFoundのメッセージが空でない")
    func windowNotFoundMessageNotEmpty() {
        let error = WorkspaceError.windowNotFound(bundleId: "test.app", title: nil)
        #expect(error.userMessage.isEmpty == false)
        #expect(error.userMessage.count > 10)
    }

    // MARK: - windowMinimized

    @Test("windowMinimizedがbundle IDを含むメッセージを提供する")
    func windowMinimizedWithBundleIdOnly() {
        let error = WorkspaceError.windowMinimized(bundleId: "com.apple.Finder", title: nil)
        let message = error.userMessage

        #expect(message.contains("com.apple.Finder"))
        #expect(message.contains("最小化") || message.contains("minimized"))
    }

    @Test("windowMinimizedがbundle IDとタイトルの両方を含むメッセージを提供する")
    func windowMinimizedWithBundleIdAndTitle() {
        let error = WorkspaceError.windowMinimized(
            bundleId: "com.apple.TextEdit",
            title: "Untitled"
        )
        let message = error.userMessage

        #expect(message.contains("com.apple.TextEdit"))
        #expect(message.contains("Untitled"))
    }

    @Test("windowMinimizedのメッセージが空でない")
    func windowMinimizedMessageNotEmpty() {
        let error = WorkspaceError.windowMinimized(bundleId: "test.app", title: nil)
        #expect(error.userMessage.isEmpty == false)
        #expect(error.userMessage.count > 10)
    }

    // MARK: - positioningFailed

    @Test("positioningFailedが失敗理由を含むメッセージを提供する")
    func positioningFailedIncludesReason() {
        let reason = "AXUIElementSetAttributeValue failed with error -25204"
        let error = WorkspaceError.positioningFailed(reason: reason)
        let message = error.userMessage

        #expect(message.contains(reason))
        #expect(message.contains("配置") || message.contains("position"))
        #expect(message.contains("失敗") || message.contains("failed"))
    }

    @Test("positioningFailedのメッセージが空でない")
    func positioningFailedMessageNotEmpty() {
        let error = WorkspaceError.positioningFailed(reason: "test reason")
        #expect(error.userMessage.isEmpty == false)
        #expect(error.userMessage.count > 10)
    }

    // MARK: - displayNotFound

    @Test("displayNotFoundがディスプレイ名を含むメッセージを提供する")
    func displayNotFoundIncludesDisplayName() {
        let displayName = "External Monitor"
        let error = WorkspaceError.displayNotFound(displayName: displayName)
        let message = error.userMessage

        #expect(message.contains(displayName))
        #expect(message.contains("ディスプレイ") || message.contains("display"))
        #expect(message.contains("見つかりません") || message.contains("not found"))
    }

    @Test("displayNotFoundのメッセージが空でない")
    func displayNotFoundMessageNotEmpty() {
        let error = WorkspaceError.displayNotFound(displayName: "Test Display")
        #expect(error.userMessage.isEmpty == false)
        #expect(error.userMessage.count > 10)
    }

    // MARK: - Sendable準拠

    @Test("新しいエラーケースがSendableに準拠している")
    func newErrorCasesAreSendable() async {
        let errors: [WorkspaceError] = [
            .windowNotFound(bundleId: "test", title: nil),
            .windowMinimized(bundleId: "test", title: "title"),
            .positioningFailed(reason: "reason"),
            .displayNotFound(displayName: "display")
        ]

        await Task {
            for error in errors {
                let _ = error.userMessage
            }
        }.value

        #expect(Bool(true))  // コンパイルが通ればOK
    }

    // MARK: - Error準拠

    @Test("新しいエラーケースがErrorプロトコルに準拠している")
    func newErrorCasesConformToError() {
        let errors: [Error] = [
            WorkspaceError.windowNotFound(bundleId: "test", title: nil),
            WorkspaceError.windowMinimized(bundleId: "test", title: nil),
            WorkspaceError.positioningFailed(reason: "test"),
            WorkspaceError.displayNotFound(displayName: "test")
        ]

        for error in errors {
            #expect(error is WorkspaceError)
        }
    }

    // MARK: - 全エラーケースの網羅性

    @Test("WorkspaceErrorの全ケースでuserMessageが非空である")
    func allCasesHaveNonEmptyMessage() {
        let allErrors: [WorkspaceError] = [
            // 既存ケース
            .applicationNotFound(bundleId: "test"),
            .applicationNotRunning(bundleId: "test"),
            .launchFailed(bundleId: "test", reason: "reason"),
            .permissionDenied,
            .invalidParameter(name: "param", reason: "reason"),
            // 新規ケース
            .windowNotFound(bundleId: "test", title: nil),
            .windowNotFound(bundleId: "test", title: "title"),
            .windowMinimized(bundleId: "test", title: nil),
            .windowMinimized(bundleId: "test", title: "title"),
            .positioningFailed(reason: "reason"),
            .displayNotFound(displayName: "display")
        ]

        for error in allErrors {
            #expect(error.userMessage.isEmpty == false, "Error \(error) has empty message")
        }
    }
}
