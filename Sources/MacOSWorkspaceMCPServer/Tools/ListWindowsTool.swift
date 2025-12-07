import Foundation
import MCP

/// ウィンドウ一覧取得ツール
public struct ListWindowsTool: MCPTool {
    public static let name = "list_windows"

    public static let definition = Tool(
        name: name,
        description: """
            アプリケーションのウィンドウ情報を取得します。
            注意: 現在アクティブなデスクトップ（Space）に表示されているウィンドウのみが対象です。
            他のデスクトップにあるウィンドウは取得できません。
            bundle IDを指定すると該当アプリのウィンドウのみを返します。
            省略すると全アプリケーションのウィンドウを返します。
            各ウィンドウのタイトル、位置、サイズ、状態、ディスプレイ情報を含みます。
            """,
        inputSchema: .object([
            "type": .string("object"),
            "properties": .object([
                "bundleId": .object([
                    "type": .string("string"),
                    "description": .string(
                        "フィルタリング対象のアプリケーションbundle ID（例: com.apple.Safari）。省略時は全アプリ"
                    ),
                ])
            ]),
        ])
    )

    // MARK: - Input

    /// ツール入力パラメーター
    struct Input: Decodable {
        let bundleId: String?
    }

    private let service: WindowServiceProtocol

    public init(service: WindowServiceProtocol) {
        self.service = service
    }

    public func execute(arguments: [String: Value]) async -> CallTool.Result {
        // 引数をデコード（空辞書の場合もデコード成功するようにInput.bundleIdはOptional）
        let input: Input = MCPArgumentDecoder.decode(from: arguments) ?? Input(bundleId: nil)

        // bundleIdパラメーター（空文字列はnilとして扱う）
        let bundleId = input.bundleId.flatMap { $0.isEmpty ? nil : $0 }

        // サービス呼び出し
        do {
            let windows = try await service.listWindows(bundleId: bundleId)
            let response = WindowListResponse(windows: windows)
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
