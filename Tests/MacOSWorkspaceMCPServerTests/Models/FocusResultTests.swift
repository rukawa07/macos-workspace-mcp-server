import Foundation
import Testing

@testable import MacOSWorkspaceMCPServer

// MARK: - FocusResult Tests

@Suite("FocusResult のテスト")
struct FocusResultTests {

    @Test("FocusResult が WindowInfo を含むことを確認する")
    func containsWindowInfo() {
        let windowInfo = WindowInfo(
            title: "Test Window",
            x: 100,
            y: 200,
            width: 800,
            height: 600,
            isMinimized: false,
            isFullscreen: false,
            displayName: "Built-in Display",
            ownerBundleId: "com.test.app",
            ownerName: "Test App"
        )

        let result = FocusResult(window: windowInfo)

        #expect(result.window.title == "Test Window")
        #expect(result.window.ownerBundleId == "com.test.app")
        #expect(result.window.x == 100)
        #expect(result.window.y == 200)
    }

    @Test("FocusResult が Codable であることを確認する")
    func isCodable() throws {
        let windowInfo = WindowInfo(
            title: "Safari",
            x: 0,
            y: 0,
            width: 1024,
            height: 768,
            isMinimized: false,
            isFullscreen: false,
            displayName: "Built-in Display",
            ownerBundleId: "com.apple.Safari",
            ownerName: "Safari"
        )

        let original = FocusResult(window: windowInfo)

        // Encode
        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        // Decode
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(FocusResult.self, from: data)

        #expect(decoded.window.title == original.window.title)
        #expect(decoded.window.ownerBundleId == original.window.ownerBundleId)
    }
}
