import Foundation
import MCP

/// アプリケーション起動ツール
public struct LaunchApplicationTool: MCPTool {
    public static let name = "launch_application"

    public static let definition = Tool(
        name: name,
        description: """
            指定されたbundle IDのアプリケーションを起動します。
            アプリが既に起動している場合はアクティブ化（最前面化）します。
            成功時にはプロセスIDとアプリケーション名を返します。
            """,
        inputSchema: .object([
            "type": .string("object"),
            "properties": .object([
                "bundleId": .object([
                    "type": .string("string"),
                    "description": .string("アプリケーションのbundle ID（例: com.apple.Safari）"),
                ])
            ]),
            "required": .array([.string("bundleId")]),
        ])
    )

    // MARK: - Input

    /// ツール入力パラメーター
    struct Input: Decodable {
        let bundleId: String?
    }

    private let service: ApplicationServiceProtocol

    public init(service: ApplicationServiceProtocol) {
        self.service = service
    }

    public func execute(arguments: [String: Value]) async -> CallTool.Result {
        // 引数をデコード
        guard let input: Input = MCPArgumentDecoder.decode(from: arguments) else {
            return .init(
                content: [.text("エラー: 引数のデコードに失敗しました。")],
                isError: true
            )
        }

        // bundleIdパラメーターのバリデーション（必須）
        guard let bundleId = input.bundleId, !bundleId.isEmpty else {
            return .init(
                content: [.text("パラメーター 'bundleId' が必要です")],
                isError: true
            )
        }

        // サービス呼び出し
        do {
            let result = try await service.launchApplication(bundleId: bundleId)
            let response = LaunchApplicationResponse(from: result)
            return MCPResultEncoder.encode(response)
        } catch let error as WorkspaceError {
            return .init(
                content: [.text(error.userMessage)],
                isError: true
            )
        } catch {
            return .init(
                content: [.text("予期しないエラー: \(error.localizedDescription)")],
                isError: true
            )
        }
    }
}
