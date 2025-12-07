import Foundation
import MCP

// MARK: - MCP Argument Decoder

/// MCP ツール引数を Decodable な構造体にデコードするユーティリティ
///
/// ## 使用例
/// ```swift
/// struct Input: Decodable {
///     let bundleId: String
///     let title: String?
/// }
///
/// func execute(arguments: [String: Value]) async -> CallTool.Result {
///     guard let input: Input = MCPArgumentDecoder.decode(from: arguments) else {
///         return .init(content: [.text("Invalid arguments")], isError: true)
///     }
///     // input.bundleId, input.title を使用
/// }
/// ```
public enum MCPArgumentDecoder {

    /// MCP引数辞書を指定した型にデコードする
    /// - Parameters:
    ///   - arguments: MCP ツール引数辞書 `[String: Value]`
    /// - Returns: デコードされた値、失敗時は nil
    public static func decode<T: Decodable>(from arguments: [String: Value]) -> T? {
        do {
            let encoder = JSONEncoder()
            let jsonData = try encoder.encode(arguments)
            let decoder = JSONDecoder()
            return try decoder.decode(T.self, from: jsonData)
        } catch {
            return nil
        }
    }
}
