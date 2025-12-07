import Foundation

// MARK: - Launch Application Response

/// アプリケーション起動レスポンス
public struct LaunchApplicationResponse: Sendable, Codable {
    public let success: Bool
    public let processId: Int
    public let appName: String
    public let wasAlreadyRunning: Bool

    public init(success: Bool, processId: Int, appName: String, wasAlreadyRunning: Bool) {
        self.success = success
        self.processId = processId
        self.appName = appName
        self.wasAlreadyRunning = wasAlreadyRunning
    }

    public init(from result: LaunchResult) {
        self.success = true
        self.processId = result.processId
        self.appName = result.appName
        self.wasAlreadyRunning = result.wasAlreadyRunning
    }
}
