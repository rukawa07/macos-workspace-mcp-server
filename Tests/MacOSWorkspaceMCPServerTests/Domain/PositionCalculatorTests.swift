import Foundation
import Testing
@testable import MacOSWorkspaceMCPServer

@Suite("PositionCalculator のテスト")
struct PositionCalculatorTests {

    // テスト用の標準visibleFrame（1920x1080、メニューバー25px考慮）
    let standardFrame = CGRect(x: 0, y: 0, width: 1920, height: 1055)

    // MARK: - 2分割プリセット

    @Test("左半分プリセットが正しい座標を計算する")
    func calculateLeftHalf() {
        let result = PositionCalculator.calculateFrame(preset: .left, visibleFrame: standardFrame)

        #expect(result.origin.x == 0)
        #expect(result.origin.y == 0)
        #expect(result.size.width == 960)
        #expect(result.size.height == 1055)
    }

    @Test("右半分プリセットが正しい座標を計算する")
    func calculateRightHalf() {
        let result = PositionCalculator.calculateFrame(preset: .right, visibleFrame: standardFrame)

        #expect(result.origin.x == 960)
        #expect(result.origin.y == 0)
        #expect(result.size.width == 960)
        #expect(result.size.height == 1055)
    }

    @Test("上半分プリセットが正しい座標を計算する")
    func calculateTopHalf() {
        let result = PositionCalculator.calculateFrame(preset: .top, visibleFrame: standardFrame)

        #expect(result.origin.x == 0)
        #expect(result.origin.y == 0)
        #expect(result.size.width == 1920)
        // 高さは半分（小数点以下切り捨て）
        #expect(result.size.height == 527)
    }

    @Test("下半分プリセットが正しい座標を計算する")
    func calculateBottomHalf() {
        let result = PositionCalculator.calculateFrame(preset: .bottom, visibleFrame: standardFrame)

        #expect(result.origin.x == 0)
        #expect(result.origin.y == 527)
        #expect(result.size.width == 1920)
        #expect(result.size.height == 528)  // 残り半分
    }

    // MARK: - 4分割プリセット

    @Test("左上プリセットが正しい座標を計算する")
    func calculateTopLeft() {
        let result = PositionCalculator.calculateFrame(preset: .topLeft, visibleFrame: standardFrame)

        #expect(result.origin.x == 0)
        #expect(result.origin.y == 0)
        #expect(result.size.width == 960)
        #expect(result.size.height == 527)
    }

    @Test("右上プリセットが正しい座標を計算する")
    func calculateTopRight() {
        let result = PositionCalculator.calculateFrame(preset: .topRight, visibleFrame: standardFrame)

        #expect(result.origin.x == 960)
        #expect(result.origin.y == 0)
        #expect(result.size.width == 960)
        #expect(result.size.height == 527)
    }

    @Test("左下プリセットが正しい座標を計算する")
    func calculateBottomLeft() {
        let result = PositionCalculator.calculateFrame(
            preset: .bottomLeft, visibleFrame: standardFrame)

        #expect(result.origin.x == 0)
        #expect(result.origin.y == 527)
        #expect(result.size.width == 960)
        #expect(result.size.height == 528)
    }

    @Test("右下プリセットが正しい座標を計算する")
    func calculateBottomRight() {
        let result = PositionCalculator.calculateFrame(
            preset: .bottomRight, visibleFrame: standardFrame)

        #expect(result.origin.x == 960)
        #expect(result.origin.y == 527)
        #expect(result.size.width == 960)
        #expect(result.size.height == 528)
    }

    // MARK: - 3分割プリセット

    @Test("左1/3プリセットが正しい座標を計算する")
    func calculateLeftThird() {
        let result = PositionCalculator.calculateFrame(
            preset: .leftThird, visibleFrame: standardFrame)

        #expect(result.origin.x == 0)
        #expect(result.origin.y == 0)
        #expect(result.size.width == 640)  // 1920 / 3 = 640
        #expect(result.size.height == 1055)
    }

    @Test("中央1/3プリセットが正しい座標を計算する")
    func calculateCenterThird() {
        let result = PositionCalculator.calculateFrame(
            preset: .centerThird, visibleFrame: standardFrame)

        #expect(result.origin.x == 640)
        #expect(result.origin.y == 0)
        #expect(result.size.width == 640)
        #expect(result.size.height == 1055)
    }

    @Test("右1/3プリセットが正しい座標を計算する")
    func calculateRightThird() {
        let result = PositionCalculator.calculateFrame(
            preset: .rightThird, visibleFrame: standardFrame)

        #expect(result.origin.x == 1280)  // 640 * 2
        #expect(result.origin.y == 0)
        #expect(result.size.width == 640)
        #expect(result.size.height == 1055)
    }

    @Test("左2/3プリセットが正しい座標を計算する")
    func calculateLeftTwoThirds() {
        let result = PositionCalculator.calculateFrame(
            preset: .leftTwoThirds, visibleFrame: standardFrame)

        #expect(result.origin.x == 0)
        #expect(result.origin.y == 0)
        #expect(result.size.width == 1280)  // 640 * 2
        #expect(result.size.height == 1055)
    }

    @Test("右2/3プリセットが正しい座標を計算する")
    func calculateRightTwoThirds() {
        let result = PositionCalculator.calculateFrame(
            preset: .rightTwoThirds, visibleFrame: standardFrame)

        #expect(result.origin.x == 640)
        #expect(result.origin.y == 0)
        #expect(result.size.width == 1280)  // 640 * 2
        #expect(result.size.height == 1055)
    }

    // MARK: - フルスクリーン

    @Test("フルスクリーンプリセットが作業領域全体を返す")
    func calculateFullscreen() {
        let result = PositionCalculator.calculateFrame(
            preset: .fullscreen, visibleFrame: standardFrame)

        #expect(result.origin.x == 0)
        #expect(result.origin.y == 0)
        #expect(result.size.width == 1920)
        #expect(result.size.height == 1055)
    }

    // MARK: - 異なるフレームサイズ

    @Test("異なるvisibleFrameサイズで正しく計算される")
    func calculateWithDifferentFrameSize() {
        let smallFrame = CGRect(x: 100, y: 50, width: 800, height: 600)
        let result = PositionCalculator.calculateFrame(preset: .left, visibleFrame: smallFrame)

        // originはvisibleFrameのoriginを基準にする
        #expect(result.origin.x == 100)
        #expect(result.origin.y == 50)
        #expect(result.size.width == 400)  // 800 / 2
        #expect(result.size.height == 600)
    }

    @Test("負のorigin値を持つフレームで正しく計算される")
    func calculateWithNegativeOrigin() {
        // セカンドディスプレイが左側にある場合など
        let negativeFrame = CGRect(x: -1920, y: 0, width: 1920, height: 1080)
        let result = PositionCalculator.calculateFrame(preset: .right, visibleFrame: negativeFrame)

        #expect(result.origin.x == -960)  // -1920 + 960
        #expect(result.origin.y == 0)
        #expect(result.size.width == 960)
        #expect(result.size.height == 1080)
    }

    // MARK: - 境界値テスト

    @Test("計算結果がvisibleFrame内に収まることを確認する")
    func resultIsWithinVisibleFrame() {
        for preset in WindowPreset.allCases {
            let result = PositionCalculator.calculateFrame(
                preset: preset, visibleFrame: standardFrame)

            // 結果がvisibleFrame内に収まることを確認
            #expect(result.origin.x >= standardFrame.origin.x)
            #expect(result.origin.y >= standardFrame.origin.y)
            #expect(
                result.origin.x + result.size.width
                    <= standardFrame.origin.x + standardFrame.size.width)
            #expect(
                result.origin.y + result.size.height
                    <= standardFrame.origin.y + standardFrame.size.height)
        }
    }

    @Test("全プリセットで幅・高さが正の値であることを確認する")
    func resultHasPositiveDimensions() {
        for preset in WindowPreset.allCases {
            let result = PositionCalculator.calculateFrame(
                preset: preset, visibleFrame: standardFrame)

            #expect(result.size.width > 0)
            #expect(result.size.height > 0)
        }
    }
}
