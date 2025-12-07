import AppKit
import Foundation
import Testing

@testable import MacOSWorkspaceMCPServer

@Suite("DisplayService のテスト")
struct DisplayServiceTests {

    @Test("少なくとも1つのディスプレイを返すことを確認する")
    func returnsAtLeastOneDisplay() {
        let service = DefaultDisplayService()

        let displays = service.listDisplays()

        #expect(displays.count >= 1)
    }

    @Test("メインディスプレイが含まれることを確認する")
    func includesMainDisplay() {
        let service = DefaultDisplayService()

        let displays = service.listDisplays()

        let mainDisplays = displays.filter { $0.isMain }
        #expect(mainDisplays.count == 1)
    }

    @Test("各ディスプレイに必要な情報が含まれることを確認する")
    func displaysHaveRequiredInformation() {
        let service = DefaultDisplayService()

        let displays = service.listDisplays()

        for display in displays {
            #expect(!display.name.isEmpty)
            #expect(display.width > 0)
            #expect(display.height > 0)
            #expect(display.visibleWidth > 0)
            #expect(display.visibleHeight > 0)
            #expect(display.visibleWidth <= display.width)
            #expect(display.visibleHeight <= display.height)
        }
    }

    @Test("可視領域がフレーム内に収まることを確認する")
    func visibleFrameIsWithinFrame() {
        let service = DefaultDisplayService()

        let displays = service.listDisplays()

        for display in displays {
            // 可視領域の右下座標がフレーム内に収まる
            let visibleRight = display.visibleX + display.visibleWidth
            let visibleBottom = display.visibleY + display.visibleHeight
            let frameRight = display.x + display.width
            let frameBottom = display.y + display.height

            #expect(display.visibleX >= display.x)
            #expect(display.visibleY >= display.y)
            #expect(visibleRight <= frameRight)
            #expect(visibleBottom <= frameBottom)
        }
    }

    @Test("DisplayServiceProtocol に準拠していることを確認する")
    func conformsToProtocol() {
        let service: any DisplayServiceProtocol = DefaultDisplayService()

        let displays = service.listDisplays()

        #expect(displays.count >= 1)
    }
}
