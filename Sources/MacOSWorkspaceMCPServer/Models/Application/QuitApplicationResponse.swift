import Foundation

// MARK: - Quit Application Response

/// アプリケーション終了レスポンス
public struct QuitApplicationResponse: Sendable, Codable {
    public let success: Bool
    public let appName: String

    public init(success: Bool, appName: String) {
        self.success = success
        self.appName = appName
    }

    public init(from result: QuitResult) {
        self.success = true
        self.appName = result.appName
    }
}
