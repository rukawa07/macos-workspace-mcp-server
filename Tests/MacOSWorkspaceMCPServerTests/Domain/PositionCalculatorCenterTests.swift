import Foundation
import Testing

@testable import MacOSWorkspaceMCPServer

@Suite("PositionCalculator.center のテスト")
struct PositionCalculatorCenterTests {

    @Test("center プリセットが可視領域の中央にウィンドウを配置することを確認する")
    func centerPlacesWindowInMiddle() {
        let visibleFrame = CGRect(x: 0, y: 25, width: 1920, height: 1025)

        let frame = PositionCalculator.calculateFrame(preset: .center, visibleFrame: visibleFrame)

        // 60%のサイズで計算
        let expectedWidth: CGFloat = floor(1920 * 0.6)
        let expectedHeight: CGFloat = floor(1025 * 0.6)

        // 中央配置の座標計算
        let expectedX: CGFloat = 0 + floor((1920 - expectedWidth) / 2)
        let expectedY: CGFloat = 25 + floor((1025 - expectedHeight) / 2)

        #expect(frame.origin.x == expectedX)
        #expect(frame.origin.y == expectedY)
        #expect(frame.size.width == expectedWidth)
        #expect(frame.size.height == expectedHeight)
    }

    @Test("異なる解像度でも正しく中央配置されることを確認する")
    func centerWorksWithDifferentResolutions() {
        let visibleFrame = CGRect(x: 1920, y: -200, width: 2560, height: 1440)

        let frame = PositionCalculator.calculateFrame(preset: .center, visibleFrame: visibleFrame)

        let expectedWidth: CGFloat = floor(2560 * 0.6)
        let expectedHeight: CGFloat = floor(1440 * 0.6)

        let expectedX: CGFloat = 1920 + floor((2560 - expectedWidth) / 2)
        let expectedY: CGFloat = -200 + floor((1440 - expectedHeight) / 2)

        #expect(frame.origin.x == expectedX)
        #expect(frame.origin.y == expectedY)
        #expect(frame.size.width == expectedWidth)
        #expect(frame.size.height == expectedHeight)
    }

    @Test("小さい画面でも正しく動作することを確認する")
    func centerWorksWithSmallScreen() {
        let visibleFrame = CGRect(x: 0, y: 25, width: 1024, height: 743)

        let frame = PositionCalculator.calculateFrame(preset: .center, visibleFrame: visibleFrame)

        let expectedWidth: CGFloat = floor(1024 * 0.6)
        let expectedHeight: CGFloat = floor(743 * 0.6)

        let expectedX: CGFloat = 0 + floor((1024 - expectedWidth) / 2)
        let expectedY: CGFloat = 25 + floor((743 - expectedHeight) / 2)

        #expect(frame.origin.x == expectedX)
        #expect(frame.origin.y == expectedY)
        #expect(frame.size.width == expectedWidth)
        #expect(frame.size.height == expectedHeight)
    }

    @Test("ウィンドウが可視領域内に収まることを確認する")
    func centerWindowIsWithinVisibleFrame() {
        let visibleFrame = CGRect(x: 100, y: 200, width: 1600, height: 900)

        let frame = PositionCalculator.calculateFrame(preset: .center, visibleFrame: visibleFrame)

        // ウィンドウの右下座標が可視領域内
        #expect(frame.origin.x >= visibleFrame.origin.x)
        #expect(frame.origin.y >= visibleFrame.origin.y)
        #expect(
            frame.origin.x + frame.size.width <= visibleFrame.origin.x + visibleFrame.size.width)
        #expect(
            frame.origin.y + frame.size.height <= visibleFrame.origin.y + visibleFrame.size.height)
    }
}
