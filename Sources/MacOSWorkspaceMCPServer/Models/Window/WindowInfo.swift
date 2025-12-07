import Foundation

// MARK: - Window Info

/// ウィンドウ情報を表現するデータモデル
public struct WindowInfo: Sendable, Codable {
    /// ウィンドウタイトル（空文字列の場合は無題ウィンドウ）
    public let title: String

    /// ウィンドウのX座標（Core Graphics座標系）
    public let x: Double

    /// ウィンドウのY座標（Core Graphics座標系）
    public let y: Double

    /// ウィンドウの幅
    public let width: Double

    /// ウィンドウの高さ
    public let height: Double

    /// 最小化状態
    public let isMinimized: Bool

    /// フルスクリーン状態
    public let isFullscreen: Bool

    /// 所属ディスプレイの名前
    public let displayName: String

    /// 所属アプリケーションのbundle ID
    public let ownerBundleId: String

    /// 所属アプリケーション名
    public let ownerName: String

    public init(
        title: String,
        x: Double,
        y: Double,
        width: Double,
        height: Double,
        isMinimized: Bool,
        isFullscreen: Bool,
        displayName: String,
        ownerBundleId: String,
        ownerName: String
    ) {
        self.title = title
        self.x = x
        self.y = y
        self.width = width
        self.height = height
        self.isMinimized = isMinimized
        self.isFullscreen = isFullscreen
        self.displayName = displayName
        self.ownerBundleId = ownerBundleId
        self.ownerName = ownerName
    }
}
