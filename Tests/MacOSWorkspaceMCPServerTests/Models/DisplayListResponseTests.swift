import Foundation
import Testing

@testable import MacOSWorkspaceMCPServer

@Suite("DisplayListResponse のテスト")
struct DisplayListResponseTests {

    @Test("ディスプレイ情報の配列をラップする構造体であることを確認する")
    func hasDisplaysArray() {
        let displays = [
            DisplayInfo(
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
            ),
            DisplayInfo(
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
            ),
        ]

        let response = DisplayListResponse(displays: displays)

        #expect(response.displays.count == 2)
        #expect(response.displays[0].name == "Built-in Display")
        #expect(response.displays[1].name == "External Display")
    }

    @Test("Codable に準拠していることを確認する")
    func encodableAndDecodable() throws {
        let displays = [
            DisplayInfo(
                name: "Test Display",
                width: 1024,
                height: 768,
                x: 100,
                y: 200,
                visibleX: 100,
                visibleY: 225,
                visibleWidth: 1024,
                visibleHeight: 718,
                isMain: true
            )
        ]

        let response = DisplayListResponse(displays: displays)

        let encoder = JSONEncoder()
        let data = try encoder.encode(response)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(DisplayListResponse.self, from: data)

        #expect(decoded.displays.count == 1)
        #expect(decoded.displays[0].name == "Test Display")
        #expect(decoded.displays[0].width == 1024)
    }

    @Test("空のディスプレイ配列でも正しく動作することを確認する")
    func emptyDisplaysArray() throws {
        let response = DisplayListResponse(displays: [])

        #expect(response.displays.isEmpty)

        let encoder = JSONEncoder()
        let data = try encoder.encode(response)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(DisplayListResponse.self, from: data)

        #expect(decoded.displays.isEmpty)
    }

    @Test("JSON エンコード時に displays キーを持つことを確認する")
    func jsonEncodedKeys() throws {
        let displays = [
            DisplayInfo(
                name: "Test",
                width: 800,
                height: 600,
                x: 0,
                y: 0,
                visibleX: 0,
                visibleY: 25,
                visibleWidth: 800,
                visibleHeight: 575,
                isMain: true
            )
        ]

        let response = DisplayListResponse(displays: displays)

        let encoder = JSONEncoder()
        let data = try encoder.encode(response)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        #expect(json?["displays"] != nil)
        #expect((json?["displays"] as? [[String: Any]])?.count == 1)
    }
}
