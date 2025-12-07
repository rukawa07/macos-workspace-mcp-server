import Foundation

// MARK: - Focus Result

/// ウィンドウフォーカス操作の結果を表現するデータモデル
public struct FocusResult: Sendable, Codable {
    /// フォーカスしたウィンドウの情報
    public let window: WindowInfo

    public init(window: WindowInfo) {
        self.window = window
    }
}
