import Foundation

// MARK: - Position Result

/// ウィンドウ配置操作の結果を表現するデータモデル
public struct PositionResult: Sendable, Codable {
    /// 配置後のウィンドウ情報
    public let window: WindowInfo

    /// 適用されたプリセット
    public let appliedPreset: WindowPreset

    /// 配置先ディスプレイ名
    public let displayName: String

    public init(
        window: WindowInfo,
        appliedPreset: WindowPreset,
        displayName: String
    ) {
        self.window = window
        self.appliedPreset = appliedPreset
        self.displayName = displayName
    }
}
