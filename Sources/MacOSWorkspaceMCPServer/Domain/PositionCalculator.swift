import Foundation

// MARK: - Position Calculator

/// プリセットに基づいてウィンドウフレームを計算するユーティリティ
public enum PositionCalculator {

    /// プリセットに基づいてウィンドウフレームを計算
    /// - Parameters:
    ///   - preset: 配置プリセット
    ///   - visibleFrame: ディスプレイの作業領域
    /// - Returns: 計算されたウィンドウフレーム
    public static func calculateFrame(
        preset: WindowPreset,
        visibleFrame: CGRect
    ) -> CGRect {
        let x = visibleFrame.origin.x
        let y = visibleFrame.origin.y
        let width = visibleFrame.size.width
        let height = visibleFrame.size.height

        // 2分割用
        let halfWidth = floor(width / 2)
        let halfHeight = floor(height / 2)

        // 3分割用
        let thirdWidth = floor(width / 3)
        let twoThirdWidth = thirdWidth * 2

        switch preset {
        // 2分割
        case .left:
            return CGRect(x: x, y: y, width: halfWidth, height: height)

        case .right:
            return CGRect(x: x + halfWidth, y: y, width: width - halfWidth, height: height)

        case .top:
            return CGRect(x: x, y: y, width: width, height: halfHeight)

        case .bottom:
            return CGRect(x: x, y: y + halfHeight, width: width, height: height - halfHeight)

        // 4分割
        case .topLeft:
            return CGRect(x: x, y: y, width: halfWidth, height: halfHeight)

        case .topRight:
            return CGRect(x: x + halfWidth, y: y, width: width - halfWidth, height: halfHeight)

        case .bottomLeft:
            return CGRect(
                x: x, y: y + halfHeight, width: halfWidth, height: height - halfHeight)

        case .bottomRight:
            return CGRect(
                x: x + halfWidth, y: y + halfHeight, width: width - halfWidth,
                height: height - halfHeight)

        // 3分割
        case .leftThird:
            return CGRect(x: x, y: y, width: thirdWidth, height: height)

        case .centerThird:
            return CGRect(x: x + thirdWidth, y: y, width: thirdWidth, height: height)

        case .rightThird:
            return CGRect(
                x: x + twoThirdWidth, y: y, width: width - twoThirdWidth, height: height)

        case .leftTwoThirds:
            return CGRect(x: x, y: y, width: twoThirdWidth, height: height)

        case .rightTwoThirds:
            return CGRect(x: x + thirdWidth, y: y, width: width - thirdWidth, height: height)

        // フルスクリーン
        case .fullscreen:
            return visibleFrame

        // 中央配置
        case .center:
            // 可視領域の60%のサイズで中央に配置
            let windowWidth = floor(width * 0.6)
            let windowHeight = floor(height * 0.6)

            let windowX = x + floor((width - windowWidth) / 2)
            let windowY = y + floor((height - windowHeight) / 2)

            return CGRect(x: windowX, y: windowY, width: windowWidth, height: windowHeight)
        }
    }
}
