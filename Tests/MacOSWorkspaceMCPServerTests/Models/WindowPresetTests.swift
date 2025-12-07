import Foundation
import Testing

@testable import MacOSWorkspaceMCPServer

@Suite("WindowPreset のテスト")
struct WindowPresetTests {

    // MARK: - 全ケースの存在確認

    @Test("15種類のプリセットが定義されている")
    func allPresetsExist() {
        let allCases = WindowPreset.allCases
        #expect(allCases.count == 15)
    }

    // MARK: - 2分割プリセット

    @Test("2分割プリセット（左半分）が存在する")
    func leftPresetExists() {
        let preset = WindowPreset.left
        #expect(preset.rawValue == "left")
    }

    @Test("2分割プリセット（右半分）が存在する")
    func rightPresetExists() {
        let preset = WindowPreset.right
        #expect(preset.rawValue == "right")
    }

    @Test("2分割プリセット（上半分）が存在する")
    func topPresetExists() {
        let preset = WindowPreset.top
        #expect(preset.rawValue == "top")
    }

    @Test("2分割プリセット（下半分）が存在する")
    func bottomPresetExists() {
        let preset = WindowPreset.bottom
        #expect(preset.rawValue == "bottom")
    }

    // MARK: - 4分割プリセット

    @Test("4分割プリセット（左上）が存在する")
    func topLeftPresetExists() {
        let preset = WindowPreset.topLeft
        #expect(preset.rawValue == "topLeft")
    }

    @Test("4分割プリセット（右上）が存在する")
    func topRightPresetExists() {
        let preset = WindowPreset.topRight
        #expect(preset.rawValue == "topRight")
    }

    @Test("4分割プリセット（左下）が存在する")
    func bottomLeftPresetExists() {
        let preset = WindowPreset.bottomLeft
        #expect(preset.rawValue == "bottomLeft")
    }

    @Test("4分割プリセット（右下）が存在する")
    func bottomRightPresetExists() {
        let preset = WindowPreset.bottomRight
        #expect(preset.rawValue == "bottomRight")
    }

    // MARK: - 3分割プリセット

    @Test("3分割プリセット（左1/3）が存在する")
    func leftThirdPresetExists() {
        let preset = WindowPreset.leftThird
        #expect(preset.rawValue == "leftThird")
    }

    @Test("3分割プリセット（中央1/3）が存在する")
    func centerThirdPresetExists() {
        let preset = WindowPreset.centerThird
        #expect(preset.rawValue == "centerThird")
    }

    @Test("3分割プリセット（右1/3）が存在する")
    func rightThirdPresetExists() {
        let preset = WindowPreset.rightThird
        #expect(preset.rawValue == "rightThird")
    }

    @Test("3分割プリセット（左2/3）が存在する")
    func leftTwoThirdsPresetExists() {
        let preset = WindowPreset.leftTwoThirds
        #expect(preset.rawValue == "leftTwoThirds")
    }

    @Test("3分割プリセット（右2/3）が存在する")
    func rightTwoThirdsPresetExists() {
        let preset = WindowPreset.rightTwoThirds
        #expect(preset.rawValue == "rightTwoThirds")
    }

    // MARK: - フルスクリーン

    @Test("フルスクリーンプリセットが存在する")
    func fullscreenPresetExists() {
        let preset = WindowPreset.fullscreen
        #expect(preset.rawValue == "fullscreen")
    }

    // MARK: - rawValueからの初期化

    @Test("rawValueから左半分プリセットを初期化できる")
    func initFromRawValueLeft() {
        let preset = WindowPreset(rawValue: "left")
        #expect(preset == .left)
    }

    @Test("rawValueから右半分プリセットを初期化できる")
    func initFromRawValueRight() {
        let preset = WindowPreset(rawValue: "right")
        #expect(preset == .right)
    }

    @Test("rawValueから上半分プリセットを初期化できる")
    func initFromRawValueTop() {
        let preset = WindowPreset(rawValue: "top")
        #expect(preset == .top)
    }

    @Test("rawValueから下半分プリセットを初期化できる")
    func initFromRawValueBottom() {
        let preset = WindowPreset(rawValue: "bottom")
        #expect(preset == .bottom)
    }

    @Test("rawValueから4分割プリセットを初期化できる")
    func initFromRawValueQuarters() {
        #expect(WindowPreset(rawValue: "topLeft") == .topLeft)
        #expect(WindowPreset(rawValue: "topRight") == .topRight)
        #expect(WindowPreset(rawValue: "bottomLeft") == .bottomLeft)
        #expect(WindowPreset(rawValue: "bottomRight") == .bottomRight)
    }

    @Test("rawValueから3分割プリセットを初期化できる")
    func initFromRawValueThirds() {
        #expect(WindowPreset(rawValue: "leftThird") == .leftThird)
        #expect(WindowPreset(rawValue: "centerThird") == .centerThird)
        #expect(WindowPreset(rawValue: "rightThird") == .rightThird)
        #expect(WindowPreset(rawValue: "leftTwoThirds") == .leftTwoThirds)
        #expect(WindowPreset(rawValue: "rightTwoThirds") == .rightTwoThirds)
    }

    @Test("rawValueからフルスクリーンを初期化できる")
    func initFromRawValueFullscreen() {
        let preset = WindowPreset(rawValue: "fullscreen")
        #expect(preset == .fullscreen)
    }

    @Test("無効なrawValueの場合はnilを返す")
    func initFromInvalidRawValue() {
        let preset = WindowPreset(rawValue: "invalid")
        #expect(preset == nil)
    }

    // MARK: - Codable準拠

    @Test("WindowPresetをJSONにエンコードできる")
    func encodable() throws {
        let preset = WindowPreset.left
        let encoder = JSONEncoder()
        let data = try encoder.encode(preset)
        let jsonString = String(data: data, encoding: .utf8)
        #expect(jsonString == "\"left\"")
    }

    @Test("JSONからWindowPresetをデコードできる")
    func decodable() throws {
        let json = "\"fullscreen\""
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let preset = try decoder.decode(WindowPreset.self, from: data)
        #expect(preset == .fullscreen)
    }

    // MARK: - 中央配置プリセット

    @Test("center ケースが存在することを確認する")
    func centerCaseExists() {
        let preset = WindowPreset.center
        #expect(preset.rawValue == "center")
    }

    @Test("center が CaseIterable に含まれることを確認する")
    func centerInAllCases() {
        let allCases = WindowPreset.allCases
        #expect(allCases.contains(.center))
    }

    @Test("center が Codable であることを確認する")
    func centerCodable() throws {
        let preset = WindowPreset.center

        let encoder = JSONEncoder()
        let data = try encoder.encode(preset)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(WindowPreset.self, from: data)

        #expect(decoded == .center)
    }

    @Test("center のrawValueから初期化できることを確認する")
    func centerInitFromRawValue() {
        let preset = WindowPreset(rawValue: "center")
        #expect(preset == .center)
    }
}
