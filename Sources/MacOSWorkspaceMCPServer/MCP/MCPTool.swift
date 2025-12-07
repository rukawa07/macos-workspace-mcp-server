import Foundation
import MCP

// MARK: - MCPTool Protocol

/// MCPツールの共通プロトコル
public protocol MCPTool: Sendable {
    /// ツール名（MCP準拠のスネークケース）
    static var name: String { get }

    /// ツール定義（Tool型）
    static var definition: Tool { get }

    /// ツール実行
    /// - Parameter arguments: ツール引数
    /// - Returns: 実行結果
    func execute(arguments: [String: Value]) async -> CallTool.Result
}
