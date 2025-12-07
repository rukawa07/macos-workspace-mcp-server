import Foundation

// MARK: - Quit Result

/// アプリケーション終了の結果
public struct QuitResult: Sendable {
    /// 終了したアプリケーション名
    public let appName: String

    public init(appName: String) {
        self.appName = appName
    }
}
