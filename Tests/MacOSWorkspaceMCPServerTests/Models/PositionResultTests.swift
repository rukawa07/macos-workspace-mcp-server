import Foundation
import Testing
@testable import MacOSWorkspaceMCPServer

@Suite("PositionResult のテスト")
struct PositionResultTests {

    // MARK: - 基本プロパティ

    @Test("PositionResultが配置後のウィンドウ情報を保持する")
    func containsWindowInfo() {
        let windowInfo = WindowInfo(
            title: "Safari",
            x: 0,
            y: 25,
            width: 960,
            height: 1055,
            isMinimized: false,
            isFullscreen: false,
            displayName: "Built-in Display",
            ownerBundleId: "com.apple.Safari",
            ownerName: "Safari"
        )

        let result = PositionResult(
            window: windowInfo,
            appliedPreset: .left,
            displayName: "Built-in Display"
        )

        #expect(result.window.title == "Safari")
        #expect(result.window.x == 0)
        #expect(result.window.y == 25)
        #expect(result.window.width == 960)
        #expect(result.window.height == 1055)
    }

    @Test("PositionResultが適用されたプリセットを保持する")
    func containsAppliedPreset() {
        let windowInfo = createTestWindowInfo()
        let result = PositionResult(
            window: windowInfo,
            appliedPreset: .topRight,
            displayName: "Built-in Display"
        )

        #expect(result.appliedPreset == .topRight)
    }

    @Test("PositionResultが配置先ディスプレイ名を保持する")
    func containsDisplayName() {
        let windowInfo = createTestWindowInfo()
        let result = PositionResult(
            window: windowInfo,
            appliedPreset: .fullscreen,
            displayName: "External Display"
        )

        #expect(result.displayName == "External Display")
    }

    // MARK: - Codable準拠

    @Test("PositionResultをJSONにエンコードできる")
    func encodable() throws {
        let windowInfo = WindowInfo(
            title: "Finder",
            x: 0,
            y: 0,
            width: 800,
            height: 600,
            isMinimized: false,
            isFullscreen: false,
            displayName: "Main",
            ownerBundleId: "com.apple.Finder",
            ownerName: "Finder"
        )
        let result = PositionResult(
            window: windowInfo,
            appliedPreset: .left,
            displayName: "Main"
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(result)
        let jsonString = String(data: data, encoding: .utf8)!

        #expect(jsonString.contains("\"appliedPreset\" : \"left\""))
        #expect(jsonString.contains("\"displayName\" : \"Main\""))
        #expect(jsonString.contains("\"title\" : \"Finder\""))
    }

    @Test("JSONからPositionResultをデコードできる")
    func decodable() throws {
        let json = """
        {
          "appliedPreset" : "fullscreen",
          "displayName" : "Test Display",
          "window" : {
            "displayName" : "Test Display",
            "height" : 1080,
            "isFullscreen" : true,
            "isMinimized" : false,
            "ownerBundleId" : "com.apple.Safari",
            "ownerName" : "Safari",
            "title" : "Test Window",
            "width" : 1920,
            "x" : 0,
            "y" : 0
          }
        }
        """
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let result = try decoder.decode(PositionResult.self, from: data)

        #expect(result.appliedPreset == .fullscreen)
        #expect(result.displayName == "Test Display")
        #expect(result.window.title == "Test Window")
        #expect(result.window.width == 1920)
        #expect(result.window.height == 1080)
    }

    // MARK: - Sendable準拠

    @Test("PositionResultがSendableに準拠している")
    func isSendable() async {
        let windowInfo = createTestWindowInfo()
        let result = PositionResult(
            window: windowInfo,
            appliedPreset: .centerThird,
            displayName: "Display"
        )

        // Sendableであればasync文脈で参照可能
        await Task {
            let _ = result.appliedPreset
        }.value

        #expect(Bool(true))  // コンパイルが通ればOK
    }

    // MARK: - Helper

    private func createTestWindowInfo() -> WindowInfo {
        return WindowInfo(
            title: "Test",
            x: 0,
            y: 0,
            width: 100,
            height: 100,
            isMinimized: false,
            isFullscreen: false,
            displayName: "Display",
            ownerBundleId: "com.test.app",
            ownerName: "TestApp"
        )
    }
}
