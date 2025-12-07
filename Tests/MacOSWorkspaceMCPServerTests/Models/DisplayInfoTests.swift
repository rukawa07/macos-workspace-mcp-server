import Foundation
import Testing

@testable import MacOSWorkspaceMCPServer

@Suite("DisplayInfo のテスト")
struct DisplayInfoTests {

    @Test("ディスプレイ名、解像度、位置、可視領域、メインフラグを持つ構造体であることを確認する")
    func hasRequiredProperties() {
        let displayInfo = DisplayInfo(
            name: "Built-in Display",
            width: 1920,
            height: 1080,
            x: 0,
            y: 0,
            visibleX: 0,
            visibleY: 25,
            visibleWidth: 1920,
            visibleHeight: 1025,
            isMain: true
        )

        #expect(displayInfo.name == "Built-in Display")
        #expect(displayInfo.width == 1920)
        #expect(displayInfo.height == 1080)
        #expect(displayInfo.x == 0)
        #expect(displayInfo.y == 0)
        #expect(displayInfo.visibleX == 0)
        #expect(displayInfo.visibleY == 25)
        #expect(displayInfo.visibleWidth == 1920)
        #expect(displayInfo.visibleHeight == 1025)
        #expect(displayInfo.isMain == true)
    }

    @Test("Codable に準拠していることを確認する")
    func encodableAndDecodable() throws {
        let displayInfo = DisplayInfo(
            name: "External Display",
            width: 2560,
            height: 1440,
            x: 1920,
            y: -200,
            visibleX: 1920,
            visibleY: -200,
            visibleWidth: 2560,
            visibleHeight: 1440,
            isMain: false
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(displayInfo)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(DisplayInfo.self, from: data)

        #expect(decoded.name == "External Display")
        #expect(decoded.width == 2560)
        #expect(decoded.height == 1440)
        #expect(decoded.x == 1920)
        #expect(decoded.y == -200)
        #expect(decoded.isMain == false)
    }

    @Test("JSON エンコード時に適切なキーを持つことを確認する")
    func jsonEncodedKeys() throws {
        let displayInfo = DisplayInfo(
            name: "Test Display",
            width: 1024,
            height: 768,
            x: 100,
            y: 200,
            visibleX: 100,
            visibleY: 225,
            visibleWidth: 1024,
            visibleHeight: 718,
            isMain: false
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(displayInfo)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        #expect(json?["name"] as? String == "Test Display")
        #expect(json?["width"] as? Int == 1024)
        #expect(json?["height"] as? Int == 768)
        #expect(json?["x"] as? Int == 100)
        #expect(json?["y"] as? Int == 200)
        #expect(json?["visibleX"] as? Int == 100)
        #expect(json?["visibleY"] as? Int == 225)
        #expect(json?["visibleWidth"] as? Int == 1024)
        #expect(json?["visibleHeight"] as? Int == 718)
        #expect(json?["isMain"] as? Bool == false)
    }
}
