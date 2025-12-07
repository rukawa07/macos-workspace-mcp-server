import Foundation
import MCP

// MARK: - Position Window Tool

/// ウィンドウ配置ツール
public struct PositionWindowTool: MCPTool {
    public static let name = "position_window"

    public static let definition = Tool(
        name: name,
        description: """
            ウィンドウを指定した位置に配置します。
            bundle IDで対象アプリケーションを指定し、プリセット（left, right, fullscreen等）で配置位置を指定します。
            オプションでウィンドウタイトルや配置先ディスプレイを指定できます。
            成功時には配置後のウィンドウ情報を返します。
            """,
        inputSchema: .object([
            "type": .string("object"),
            "properties": .object([
                "bundleId": .object([
                    "type": .string("string"),
                    "description": .string(
                        "対象アプリケーションのbundle ID（必須、例: com.apple.Safari）"
                    ),
                ]),
                "preset": .object([
                    "type": .string("string"),
                    "description": .string(
                        "配置プリセット（必須）: left, right, top, bottom, topLeft, topRight, bottomLeft, bottomRight, leftThird, centerThird, rightThird, leftTwoThirds, rightTwoThirds, fullscreen, center"
                    ),
                    "enum": .array([
                        .string("left"), .string("right"), .string("top"), .string("bottom"),
                        .string("topLeft"), .string("topRight"), .string("bottomLeft"),
                        .string("bottomRight"),
                        .string("leftThird"), .string("centerThird"), .string("rightThird"),
                        .string("leftTwoThirds"), .string("rightTwoThirds"),
                        .string("fullscreen"),
                        .string("center"),
                    ]),
                ]),
                "title": .object([
                    "type": .string("string"),
                    "description": .string(
                        "ウィンドウタイトル（オプション、部分一致でフィルタリング）"
                    ),
                ]),
                "displayName": .object([
                    "type": .string("string"),
                    "description": .string(
                        "配置先ディスプレイ名（オプション、省略時は現在のディスプレイ）"
                    ),
                ]),
            ]),
            "required": .array([.string("bundleId"), .string("preset")]),
        ])
    )

    // MARK: - Input

    /// ツール入力パラメーター
    struct Input: Decodable {
        let bundleId: String?
        let preset: String?
        let title: String?
        let displayName: String?
    }

    private let service: WindowServiceProtocol

    public init(service: WindowServiceProtocol) {
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
                content: [.text("エラー: パラメーター 'bundleId' は必須です。")],
                isError: true
            )
        }

        // presetパラメーターのバリデーション（必須）
        guard let presetString = input.preset, !presetString.isEmpty else {
            return .init(
                content: [.text("エラー: パラメーター 'preset' は必須です。")],
                isError: true
            )
        }

        guard let preset = WindowPreset(rawValue: presetString) else {
            let validPresets = WindowPreset.allCases.map { $0.rawValue }.joined(separator: ", ")
            return .init(
                content: [
                    .text(
                        "エラー: 不正なプリセット値 '\(presetString)' です。有効な値: \(validPresets)")
                ],
                isError: true
            )
        }

        // オプションパラメーター（空文字列はnilとして扱う）
        let title = input.title.flatMap { $0.isEmpty ? nil : $0 }
        let displayName = input.displayName.flatMap { $0.isEmpty ? nil : $0 }

        // サービス呼び出し
        do {
            let result = try await service.positionWindow(
                bundleId: bundleId,
                title: title,
                preset: preset,
                displayName: displayName
            )
            return MCPResultEncoder.encode(result)
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
