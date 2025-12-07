import Foundation
import MCP

/// アプリケーション終了ツール
public struct QuitApplicationTool: MCPTool {
    public static let name = "quit_application"

    public static let definition = Tool(
        name: name,
        description: """
            指定されたbundle IDのアプリケーションを終了します。
            未保存のドキュメントがある場合は保存確認ダイアログが表示されます。
            成功時には終了したアプリケーション名を返します。
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
            let result = try await service.quitApplication(bundleId: bundleId)
            let response = QuitApplicationResponse(from: result)
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
