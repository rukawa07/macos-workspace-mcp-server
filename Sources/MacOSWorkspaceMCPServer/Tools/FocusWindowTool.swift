import Foundation
import MCP

// MARK: - Focus Window Tool

/// ウィンドウフォーカスツール
public struct FocusWindowTool: MCPTool {
    public static let name = "focus_window"

    public static let definition = Tool(
        name: name,
        description: """
            指定されたアプリケーションのウィンドウを最前面に表示します。
            アプリケーションをアクティブ化し、ウィンドウにフォーカスを当てます。
            最小化されているウィンドウは自動的に復元されます。
            """,
        inputSchema: .object([
            "type": .string("object"),
            "properties": .object([
                "bundleId": .object([
                    "type": .string("string"),
                    "description": .string("対象アプリケーションのbundle ID（例: com.apple.Safari）"),
                ]),
                "title": .object([
                    "type": .string("string"),
                    "description": .string("ウィンドウタイトル（部分一致、オプション）"),
                ]),
            ]),
            "required": .array([.string("bundleId")]),
        ])
    )

    // MARK: - Input

    /// ツール入力パラメーター
    struct Input: Decodable {
        let bundleId: String?
        let title: String?
    }

    private let service: WindowServiceProtocol

    public init(windowService: WindowServiceProtocol) {
        self.service = windowService
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
                content: [.text("エラー: パラメーター 'bundleId' は必須です。")],
                isError: true
            )
        }

        // WindowServiceを呼び出してウィンドウにフォーカス
        do {
            let result = try await service.focusWindow(
                bundleId: bundleId,
                title: input.title
            )

            // 成功時はFocusResultをJSON形式で返却
            return MCPResultEncoder.encode(result)
        } catch let error as WorkspaceError {
            // WorkspaceErrorの場合は日本語メッセージを返す
            return .init(
                content: [.text(error.userMessage)],
                isError: true
            )
        } catch {
            // その他のエラー
            return .init(
                content: [.text("エラー: \(error.localizedDescription)")],
                isError: true
            )
        }
    }
}
