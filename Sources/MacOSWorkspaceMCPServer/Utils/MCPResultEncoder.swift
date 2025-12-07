import Foundation
import MCP

// MARK: - MCP Result Encoder

/// MCP ツール結果を JSON 形式の CallTool.Result にエンコードするユーティリティ
///
/// ## 使用例
/// ```swift
/// func execute(arguments: [String: Value]) async -> CallTool.Result {
///     let response = WindowListResponse(windows: windows)
///     return MCPResultEncoder.encode(response)
/// }
/// ```
public enum MCPResultEncoder {

    /// Encodable な値を JSON 形式の CallTool.Result にエンコードする
    /// - Parameter value: エンコードする値
    /// - Returns: JSON テキストを含む CallTool.Result（エンコード失敗時は isError: true）
    public static func encode<T: Encodable>(_ value: T) -> CallTool.Result {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let jsonData = try encoder.encode(value)
            let jsonString = String(data: jsonData, encoding: .utf8) ?? "{}"

            return .init(
                content: [.text(jsonString)],
                isError: false
            )
        } catch {
            return .init(
                content: [.text("JSON変換エラー: \(error.localizedDescription)")],
                isError: true
            )
        }
    }
}
