import Foundation

/// ディスプレイ一覧のレスポンスモデル
public struct DisplayListResponse: Sendable, Codable {
    /// ディスプレイ情報の配列
    public let displays: [DisplayInfo]

    public init(displays: [DisplayInfo]) {
        self.displays = displays
    }
}
