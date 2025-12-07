import AppKit
import Foundation

/// ディスプレイ操作サービスのプロトコル
public protocol DisplayServiceProtocol: Sendable {
    /// 接続されている全ディスプレイの一覧を取得
    /// - Returns: ディスプレイ情報の配列
    func listDisplays() -> [DisplayInfo]
}

/// ディスプレイ操作サービスのデフォルト実装
public struct DefaultDisplayService: DisplayServiceProtocol, Sendable {

    public init() {}

    public func listDisplays() -> [DisplayInfo] {
        let screens = NSScreen.screens

        return screens.map { screen in
            convertToDisplayInfo(screen: screen)
        }
    }

    private func convertToDisplayInfo(screen: NSScreen) -> DisplayInfo {
        // NSScreen座標系（左下原点、Y軸上向き）からCore Graphics座標系（左上原点、Y軸下向き）に変換
        let frame = screen.frame
        let visibleFrame = screen.visibleFrame

        // メインスクリーンを基準に座標変換
        guard let mainScreen = NSScreen.main else {
            fatalError("Main screen not found")
        }

        let mainScreenHeight = mainScreen.frame.height

        // Core Graphics座標系でのY座標（上下反転）
        let cgY = mainScreenHeight - frame.origin.y - frame.height
        let cgVisibleY = mainScreenHeight - visibleFrame.origin.y - visibleFrame.height

        // ディスプレイ名を取得（一意の識別子として）
        let name = screen.localizedName

        return DisplayInfo(
            name: name,
            width: Int(frame.width),
            height: Int(frame.height),
            x: Int(frame.origin.x),
            y: Int(cgY),
            visibleX: Int(visibleFrame.origin.x),
            visibleY: Int(cgVisibleY),
            visibleWidth: Int(visibleFrame.width),
            visibleHeight: Int(visibleFrame.height),
            isMain: screen == NSScreen.main
        )
    }
}
