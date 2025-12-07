import Foundation
import Testing

@testable import MacOSWorkspaceMCPServer

/// ウィンドウ情報モデルをテストするスイート
@Suite("WindowInfoのテスト")
struct WindowInfoTests {

    // MARK: - WindowInfo Properties Tests

    @Test("WindowInfoが全プロパティを正しく保持する")
    func windowInfoProperties() {
        let windowInfo = WindowInfo(
            title: "Document.txt",
            x: 100.0,
            y: 50.0,
            width: 800.0,
            height: 600.0,
            isMinimized: false,
            isFullscreen: false,
            displayName: "Built-in Retina Display",
            ownerBundleId: "com.apple.TextEdit",
            ownerName: "TextEdit"
        )

        #expect(windowInfo.title == "Document.txt")
        #expect(windowInfo.x == 100.0)
        #expect(windowInfo.y == 50.0)
        #expect(windowInfo.width == 800.0)
        #expect(windowInfo.height == 600.0)
        #expect(windowInfo.isMinimized == false)
        #expect(windowInfo.isFullscreen == false)
        #expect(windowInfo.displayName == "Built-in Retina Display")
        #expect(windowInfo.ownerBundleId == "com.apple.TextEdit")
        #expect(windowInfo.ownerName == "TextEdit")
    }

    @Test("WindowInfoが空のタイトルを許容する（無題ウィンドウ）")
    func windowInfoEmptyTitle() {
        let windowInfo = WindowInfo(
            title: "",
            x: 0.0,
            y: 0.0,
            width: 400.0,
            height: 300.0,
            isMinimized: false,
            isFullscreen: false,
            displayName: "Display 1",
            ownerBundleId: "com.example.app",
            ownerName: "Example App"
        )

        #expect(windowInfo.title == "")
    }

    @Test("WindowInfoが最小化状態を正しく保持する")
    func windowInfoMinimized() {
        let windowInfo = WindowInfo(
            title: "Minimized Window",
            x: 0.0,
            y: 0.0,
            width: 800.0,
            height: 600.0,
            isMinimized: true,
            isFullscreen: false,
            displayName: "Display 1",
            ownerBundleId: "com.example.app",
            ownerName: "Example App"
        )

        #expect(windowInfo.isMinimized == true)
        #expect(windowInfo.isFullscreen == false)
    }

    @Test("WindowInfoがフルスクリーン状態を正しく保持する")
    func windowInfoFullscreen() {
        let windowInfo = WindowInfo(
            title: "Fullscreen Window",
            x: 0.0,
            y: 0.0,
            width: 1920.0,
            height: 1080.0,
            isMinimized: false,
            isFullscreen: true,
            displayName: "Built-in Retina Display",
            ownerBundleId: "com.example.app",
            ownerName: "Example App"
        )

        #expect(windowInfo.isMinimized == false)
        #expect(windowInfo.isFullscreen == true)
    }

    // MARK: - displayName Property Tests

    @Test("WindowInfoがdisplayNameプロパティを正しく保持する")
    func windowInfoDisplayName() {
        let windowInfo = WindowInfo(
            title: "Test Window",
            x: 0.0,
            y: 0.0,
            width: 800.0,
            height: 600.0,
            isMinimized: false,
            isFullscreen: false,
            displayName: "External Display",
            ownerBundleId: "com.example.app",
            ownerName: "Example App"
        )

        #expect(windowInfo.displayName == "External Display")
    }

    @Test("WindowInfoがSwift 6並行処理のためSendableに準拠している")
    func windowInfoIsSendable() {
        let windowInfo = WindowInfo(
            title: "Test Window",
            x: 100.0,
            y: 100.0,
            width: 800.0,
            height: 600.0,
            isMinimized: false,
            isFullscreen: false,
            displayName: "Display 1",
            ownerBundleId: "com.example.app",
            ownerName: "Example App"
        )

        Task {
            // Sendable準拠していればコンパイルエラーにならない
            let _ = windowInfo
        }

        #expect(true)  // コンパイルが通ればOK
    }

    @Test("WindowInfoが負の座標値を許容する（マルチディスプレイ環境）")
    func windowInfoNegativeCoordinates() {
        let windowInfo = WindowInfo(
            title: "Secondary Display Window",
            x: -1920.0,
            y: 0.0,
            width: 800.0,
            height: 600.0,
            isMinimized: false,
            isFullscreen: false,
            displayName: "External Display",
            ownerBundleId: "com.example.app",
            ownerName: "Example App"
        )

        #expect(windowInfo.x == -1920.0)
        #expect(windowInfo.y == 0.0)
    }

    @Test("WindowInfoがCodable準拠でJSON形式にエンコード・デコード可能")
    func windowInfoCodable() throws {
        let original = WindowInfo(
            title: "Test Window",
            x: 100.0,
            y: 200.0,
            width: 800.0,
            height: 600.0,
            isMinimized: false,
            isFullscreen: true,
            displayName: "Built-in Retina Display",
            ownerBundleId: "com.apple.Safari",
            ownerName: "Safari"
        )

        // エンコード
        let encoder = JSONEncoder()
        let jsonData = try encoder.encode(original)
        let jsonString = String(data: jsonData, encoding: .utf8)!

        // プロパティがJSONに含まれることを確認
        #expect(jsonString.contains("\"displayName\""))

        // デコード
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(WindowInfo.self, from: jsonData)

        // すべてのプロパティが一致することを確認
        #expect(decoded.title == original.title)
        #expect(decoded.x == original.x)
        #expect(decoded.y == original.y)
        #expect(decoded.width == original.width)
        #expect(decoded.height == original.height)
        #expect(decoded.isMinimized == original.isMinimized)
        #expect(decoded.isFullscreen == original.isFullscreen)
        #expect(decoded.displayName == original.displayName)
        #expect(decoded.ownerBundleId == original.ownerBundleId)
        #expect(decoded.ownerName == original.ownerName)
    }
}
