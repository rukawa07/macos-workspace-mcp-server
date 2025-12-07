import Foundation

/// ディスプレイ情報を表現するモデル
public struct DisplayInfo: Sendable, Codable {
    /// ディスプレイ名（識別子）
    public let name: String

    /// 解像度: 幅
    public let width: Int

    /// 解像度: 高さ
    public let height: Int

    /// グローバル座標系での左上X座標（Core Graphics座標系）
    public let x: Int

    /// グローバル座標系での左上Y座標（Core Graphics座標系）
    public let y: Int

    /// 可視領域の左上X座標（メニューバー・Dock除外後）
    public let visibleX: Int

    /// 可視領域の左上Y座標（メニューバー・Dock除外後）
    public let visibleY: Int

    /// 可視領域の幅
    public let visibleWidth: Int

    /// 可視領域の高さ
    public let visibleHeight: Int

    /// メインディスプレイかどうか
    public let isMain: Bool

    public init(
        name: String,
        width: Int,
        height: Int,
        x: Int,
        y: Int,
        visibleX: Int,
        visibleY: Int,
        visibleWidth: Int,
        visibleHeight: Int,
        isMain: Bool
    ) {
        self.name = name
        self.width = width
        self.height = height
        self.x = x
        self.y = y
        self.visibleX = visibleX
        self.visibleY = visibleY
        self.visibleWidth = visibleWidth
        self.visibleHeight = visibleHeight
        self.isMain = isMain
    }
}
