import Foundation
import Testing

@testable import MacOSWorkspaceMCPServer

/// アプリケーション制御のデータモデルをテストするスイート
@Suite("アプリケーションモデルのテスト")
struct ApplicationModelsTests {

    // MARK: - ApplicationInfo Tests

    @Test("ApplicationInfoがbundle ID、名前、プロセスID、非表示状態を保持する")
    func applicationInfoProperties() {
        let appInfo = ApplicationInfo(
            bundleId: "com.apple.Safari",
            name: "Safari",
            processId: 12345,
            isHidden: false
        )

        #expect(appInfo.bundleId == "com.apple.Safari")
        #expect(appInfo.name == "Safari")
        #expect(appInfo.processId == 12345)
        #expect(appInfo.isHidden == false)
    }

    @Test("ApplicationInfoがSwift 6並行処理のためSendableに準拠している")
    func applicationInfoIsSendable() {
        // コンパイル時にSendable準拠が確認される
        let appInfo = ApplicationInfo(
            bundleId: "com.apple.Finder",
            name: "Finder",
            processId: 100,
            isHidden: true
        )

        Task {
            // Sendable準拠していればコンパイルエラーにならない
            let _ = appInfo
        }

        #expect(true)  // コンパイルが通ればOK
    }

    // MARK: - LaunchResult Tests

    @Test("LaunchResultがプロセスID、アプリ名、起動済みフラグを保持する")
    func launchResultProperties() {
        let result = LaunchResult(
            processId: 54321,
            appName: "TextEdit",
            wasAlreadyRunning: false
        )

        #expect(result.processId == 54321)
        #expect(result.appName == "TextEdit")
        #expect(result.wasAlreadyRunning == false)
    }

    @Test("LaunchResultがアプリ既起動を示す場合、wasAlreadyRunningがtrueになる")
    func launchResultAlreadyRunning() {
        let result = LaunchResult(
            processId: 999,
            appName: "Safari",
            wasAlreadyRunning: true
        )

        #expect(result.wasAlreadyRunning == true)
    }

    // MARK: - QuitResult Tests

    @Test("QuitResultがアプリ名を保持する")
    func quitResultProperties() {
        let result = QuitResult(appName: "Safari")

        #expect(result.appName == "Safari")
    }

    // MARK: - WorkspaceError Tests

    @Test("WorkspaceError.applicationNotFoundがユーザーフレンドリーなメッセージを提供する")
    func errorApplicationNotFound() {
        let error = WorkspaceError.applicationNotFound(bundleId: "com.example.NoSuchApp")

        let message = error.userMessage
        #expect(message.contains("com.example.NoSuchApp"))
        #expect(message.contains("見つかりません") || message.contains("not found"))
    }

    @Test("WorkspaceError.applicationNotRunningがユーザーフレンドリーなメッセージを提供する")
    func errorApplicationNotRunning() {
        let error = WorkspaceError.applicationNotRunning(bundleId: "com.apple.Safari")

        let message = error.userMessage
        #expect(message.contains("com.apple.Safari"))
        #expect(message.contains("起動していません") || message.contains("not running"))
    }

    @Test("WorkspaceError.launchFailedがユーザーフレンドリーなメッセージを提供する")
    func errorLaunchFailed() {
        let error = WorkspaceError.launchFailed(
            bundleId: "com.apple.Safari", reason: "Unknown error")

        let message = error.userMessage
        #expect(message.contains("com.apple.Safari"))
        #expect(message.contains("起動に失敗") || message.contains("failed to launch"))
        #expect(message.contains("Unknown error"))
    }

    @Test("WorkspaceError.permissionDeniedがアクセシビリティ設定パスを含む")
    func errorPermissionDenied() {
        let error = WorkspaceError.permissionDenied

        let message = error.userMessage
        #expect(message.contains("アクセシビリティ") || message.contains("Accessibility"))
        #expect(message.contains("システム設定") || message.contains("System Settings"))
        #expect(message.contains("プライバシーとセキュリティ") || message.contains("Privacy"))
    }

    @Test("WorkspaceError.invalidParameterがユーザーフレンドリーなメッセージを提供する")
    func errorInvalidParameter() {
        let error = WorkspaceError.invalidParameter(name: "bundleId", reason: "empty string")

        let message = error.userMessage
        #expect(message.contains("bundleId"))
        #expect(message.contains("empty string"))
        #expect(message.contains("不正") || message.contains("invalid"))
    }

    @Test("WorkspaceErrorがErrorプロトコルに準拠している")
    func errorConformsToErrorProtocol() {
        let error: Error = WorkspaceError.applicationNotFound(bundleId: "test")

        // Error型として扱えることを確認
        #expect(error is WorkspaceError)
    }

    // MARK: - WorkspaceError Additional Tests

    @Test("すべてのWorkspaceErrorケースでメッセージが空でないことを確認する")
    func errorMessagesNonEmpty() {
        let errors: [WorkspaceError] = [
            .applicationNotFound(bundleId: "test.app"),
            .applicationNotRunning(bundleId: "test.app"),
            .launchFailed(bundleId: "test.app", reason: "test reason"),
            .permissionDenied,
            .invalidParameter(name: "test", reason: "test reason"),
        ]

        for error in errors {
            #expect(error.userMessage.isEmpty == false)
            #expect(error.userMessage.count > 10)  // メッセージは十分な情報を含む
        }
    }

    @Test("WorkspaceError.applicationNotFoundがメッセージにbundle IDを含む")
    func errorApplicationNotFoundIncludesBundleId() {
        let bundleId = "com.example.SpecificApp"
        let error = WorkspaceError.applicationNotFound(bundleId: bundleId)

        #expect(error.userMessage.contains(bundleId))
    }

    @Test("WorkspaceError.applicationNotRunningがメッセージにbundle IDを含む")
    func errorApplicationNotRunningIncludesBundleId() {
        let bundleId = "com.example.NotRunningApp"
        let error = WorkspaceError.applicationNotRunning(bundleId: bundleId)

        #expect(error.userMessage.contains(bundleId))
    }

    @Test("WorkspaceError.launchFailedがbundle IDと理由の両方を含む")
    func errorLaunchFailedIncludesDetails() {
        let bundleId = "com.example.FailApp"
        let reason = "Specific failure reason"
        let error = WorkspaceError.launchFailed(bundleId: bundleId, reason: reason)

        #expect(error.userMessage.contains(bundleId))
        #expect(error.userMessage.contains(reason))
    }

    @Test("WorkspaceError.permissionDeniedが実行可能な手順を提供する")
    func errorPermissionDeniedActionable() {
        let error = WorkspaceError.permissionDenied
        let message = error.userMessage

        // 手順が含まれていることを確認
        #expect(message.contains("1.") || message.contains("手順"))
        #expect(message.contains("2.") || message.contains("選択"))
        #expect(message.contains("3.") || message.contains("追加") || message.contains("有効"))
    }

    @Test("WorkspaceError.invalidParameterがパラメーター名と理由を含む")
    func errorInvalidParameterIncludesDetails() {
        let paramName = "specificParam"
        let reason = "must be positive"
        let error = WorkspaceError.invalidParameter(name: paramName, reason: reason)

        #expect(error.userMessage.contains(paramName))
        #expect(error.userMessage.contains(reason))
    }
}
