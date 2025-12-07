import Foundation

// MARK: - Window List Response

/// ウィンドウ一覧のレスポンス用ラッパー
public struct WindowListResponse: Sendable, Codable {
    public let windows: [WindowInfo]

    public init(windows: [WindowInfo]) {
        self.windows = windows
    }
}
