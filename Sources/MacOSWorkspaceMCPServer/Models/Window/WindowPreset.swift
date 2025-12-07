import Foundation

// MARK: - Window Preset

/// ウィンドウ配置プリセットを表現する列挙型
public enum WindowPreset: String, Codable, CaseIterable, Sendable {
    // 2分割
    /// 左半分 (50%)
    case left
    /// 右半分 (50%)
    case right
    /// 上半分 (50%)
    case top
    /// 下半分 (50%)
    case bottom

    // 4分割
    /// 左上 (25%)
    case topLeft
    /// 右上 (25%)
    case topRight
    /// 左下 (25%)
    case bottomLeft
    /// 右下 (25%)
    case bottomRight

    // 3分割
    /// 左1/3 (33.3%)
    case leftThird
    /// 中央1/3 (33.3%)
    case centerThird
    /// 右1/3 (33.3%)
    case rightThird
    /// 左2/3 (66.7%)
    case leftTwoThirds
    /// 右2/3 (66.7%)
    case rightTwoThirds

    // フルスクリーン
    /// 全画面 (100%)
    case fullscreen

    // 中央配置
    /// 中央配置
    case center
}
