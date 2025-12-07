import AppKit
import ApplicationServices
import Foundation

// MARK: - Protocol Definition

/// アプリケーション制御サービスのプロトコル
public protocol ApplicationServiceProtocol: Sendable {
    /// アプリケーションを起動する
    /// - Parameter bundleId: アプリケーションのbundle ID
    /// - Returns: 起動結果（プロセスID、アプリ名、アクティブ化フラグ）
    /// - Throws: WorkspaceError.applicationNotFound, WorkspaceError.launchFailed
    func launchApplication(bundleId: String) async throws -> LaunchResult

    /// アプリケーションを終了する
    /// - Parameter bundleId: アプリケーションのbundle ID
    /// - Returns: 終了結果（アプリ名）
    /// - Throws: WorkspaceError.applicationNotRunning
    func quitApplication(bundleId: String) async throws -> QuitResult

    /// 起動中のアプリケーション一覧を取得する
    /// - Returns: アプリケーション情報の配列
    func listRunningApplications() async -> [ApplicationInfo]

    /// Accessibility権限を確認する
    /// - Returns: 権限が付与されているかどうか
    func checkAccessibilityPermission() -> Bool
}

// MARK: - Default Implementation

/// ApplicationServiceProtocolのデフォルト実装
///
/// NSWorkspaceとNSRunningApplicationを使用してmacOSアプリケーションを制御
public final class DefaultApplicationService: ApplicationServiceProtocol, @unchecked Sendable {

    public init() {}

    // MARK: - Launch Application

    /// アプリケーションを起動する
    public func launchApplication(bundleId: String) async throws -> LaunchResult {
        let workspace = NSWorkspace.shared

        // 既に起動しているか確認
        if let runningApp = workspace.runningApplications.first(where: {
            $0.bundleIdentifier == bundleId
        }) {
            // アクティブ化
            runningApp.activate()

            return LaunchResult(
                processId: Int(runningApp.processIdentifier),
                appName: runningApp.localizedName ?? bundleId,
                wasAlreadyRunning: true
            )
        }

        // アプリケーションのURLを取得
        guard let appURL = workspace.urlForApplication(withBundleIdentifier: bundleId) else {
            throw WorkspaceError.applicationNotFound(bundleId: bundleId)
        }

        // 起動
        let configuration = NSWorkspace.OpenConfiguration()

        do {
            let runningApp = try await workspace.openApplication(
                at: appURL, configuration: configuration)

            return LaunchResult(
                processId: Int(runningApp.processIdentifier),
                appName: runningApp.localizedName ?? bundleId,
                wasAlreadyRunning: false
            )
        } catch {
            throw WorkspaceError.launchFailed(
                bundleId: bundleId, reason: error.localizedDescription)
        }
    }

    // MARK: - Quit Application

    /// アプリケーションを終了する
    public func quitApplication(bundleId: String) async throws -> QuitResult {
        let workspace = NSWorkspace.shared

        // 起動中のアプリを検索
        guard
            let runningApp = workspace.runningApplications.first(where: {
                $0.bundleIdentifier == bundleId
            })
        else {
            throw WorkspaceError.applicationNotRunning(bundleId: bundleId)
        }

        let appName = runningApp.localizedName ?? bundleId

        // 通常の終了処理
        runningApp.terminate()

        return QuitResult(appName: appName)
    }

    // MARK: - List Running Applications

    /// 起動中のアプリケーション一覧を取得する
    public func listRunningApplications() async -> [ApplicationInfo] {
        let workspace = NSWorkspace.shared

        return workspace.runningApplications
            .filter { app in
                // ActivationPolicyがRegularのアプリのみ（UIを持つアプリ）
                app.activationPolicy == .regular
            }
            .compactMap { app in
                guard let bundleId = app.bundleIdentifier else {
                    return nil
                }

                return ApplicationInfo(
                    bundleId: bundleId,
                    name: app.localizedName ?? bundleId,
                    processId: Int(app.processIdentifier),
                    isHidden: app.isHidden
                )
            }
    }

    // MARK: - Permission Check

    /// Accessibility権限を確認する
    public func checkAccessibilityPermission() -> Bool {
        return AXIsProcessTrusted()
    }
}
