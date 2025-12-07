import Foundation
import MCP
import Testing

@testable import MacOSWorkspaceMCPServer

@Suite("ListDisplaysTool のテスト")
struct ListDisplaysToolTests {

    @Test("ツール定義が正しいことを確認する")
    func toolDefinition() {
        let definition = ListDisplaysTool.definition

        #expect(ListDisplaysTool.name == "list_displays")
        #expect(definition.name == "list_displays")
        #expect(definition.description != nil)
        #expect(!(definition.description?.isEmpty ?? true))
    }

    @Test("execute メソッドがディスプレイ一覧を返すことを確認する")
    func executeReturnsDisplayList() async throws {
        let displayService = DefaultDisplayService()
        let tool = ListDisplaysTool(service: displayService)

        let result = await tool.execute(arguments: [:])

        // 結果が成功であることを確認
        #expect(result.isError != true)
        #expect(!result.content.isEmpty)

        // 最初のコンテンツがテキストであることを確認
        guard case .text(let jsonString) = result.content.first else {
            Issue.record("Expected text content")
            return
        }

        // JSONとしてパース可能であることを確認
        let data = Data(jsonString.utf8)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        #expect(json != nil)
        #expect(json?["displays"] != nil)

        // displaysが配列であることを確認
        let displays = json?["displays"] as? [[String: Any]]
        #expect(displays != nil)
        #expect((displays?.count ?? 0) >= 1)
    }

    @Test("返されるディスプレイ情報に必要なフィールドが含まれることを確認する")
    func displayInfoHasRequiredFields() async throws {
        let displayService = DefaultDisplayService()
        let tool = ListDisplaysTool(service: displayService)

        let result = await tool.execute(arguments: [:])

        guard case .text(let jsonString) = result.content.first else {
            Issue.record("Expected text content")
            return
        }

        let data = Data(jsonString.utf8)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let displays = json?["displays"] as? [[String: Any]]

        guard let firstDisplay = displays?.first else {
            Issue.record("No displays found")
            return
        }

        #expect(firstDisplay["name"] != nil)
        #expect(firstDisplay["width"] != nil)
        #expect(firstDisplay["height"] != nil)
        #expect(firstDisplay["x"] != nil)
        #expect(firstDisplay["y"] != nil)
        #expect(firstDisplay["visibleX"] != nil)
        #expect(firstDisplay["visibleY"] != nil)
        #expect(firstDisplay["visibleWidth"] != nil)
        #expect(firstDisplay["visibleHeight"] != nil)
        #expect(firstDisplay["isMain"] != nil)
    }

    @Test("MCPTool プロトコルに準拠していることを確認する")
    func conformsToMCPTool() async {
        let displayService = DefaultDisplayService()
        let tool: any MCPTool = ListDisplaysTool(service: displayService)

        let result = await tool.execute(arguments: [:])

        #expect(result.isError != true)
    }
}
