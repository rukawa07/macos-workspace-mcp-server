import Foundation
import MCP

/// ディスプレイ一覧取得ツール
public struct ListDisplaysTool: MCPTool {
    public static let name = "list_displays"

    public static let definition = Tool(
        name: name,
        description: """
            接続されているディスプレイの一覧と詳細情報を取得します。
            各ディスプレイの名前、解像度、位置、可視領域、メインディスプレイかどうかを含みます。
            """,
        inputSchema: .object([
            "type": .string("object"),
            "properties": .object([:]),
            "required": .array([]),
        ])
    )

    private let service: DisplayServiceProtocol

    public init(service: DisplayServiceProtocol) {
        self.service = service
    }

    public func execute(arguments: [String: Value]) async -> CallTool.Result {
        let displays = service.listDisplays()
        let response = DisplayListResponse(displays: displays)
        return MCPResultEncoder.encode(response)
    }
}
