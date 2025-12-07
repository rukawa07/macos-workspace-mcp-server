import Foundation

// MARK: - Launch Result

/// アプリケーション起動の結果
public struct LaunchResult: Sendable {
    /// プロセスID
    public let processId: Int

    /// アプリケーション名
    public let appName: String

    /// 既に起動していたか（アクティブ化のみ行った場合true）
    public let wasAlreadyRunning: Bool

    public init(processId: Int, appName: String, wasAlreadyRunning: Bool) {
        self.processId = processId
        self.appName = appName
        self.wasAlreadyRunning = wasAlreadyRunning
    }
}
