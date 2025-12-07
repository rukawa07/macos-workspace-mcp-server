import Foundation
import MCP

/// 起動中アプリケーション一覧取得ツール
public struct ListApplicationsTool: MCPTool {
    public static let name = "list_applications"

    public static let definition = Tool(
        name: name,
        description: """
            現在起動中のアプリケーション一覧を取得します。
            各アプリケーションのbundle ID、名前、プロセスIDを返します。
            システムプロセス（UIを持たないバックグラウンドプロセス）は除外されます。
            """,
        inputSchema: .object([
            "type": .string("object"),
            "properties": .object([:]),
        ])
    )

    private let service: ApplicationServiceProtocol

    public init(service: ApplicationServiceProtocol) {
        self.service = service
    }

    public func execute(arguments: [String: Value]) async -> CallTool.Result {
        // このツールには入力パラメーターがないため、デコード不要

        // サービス呼び出し
        let apps = await service.listRunningApplications()
        let response = ApplicationListResponse(applications: apps)
        return MCPResultEncoder.encode(response)
    }
}
