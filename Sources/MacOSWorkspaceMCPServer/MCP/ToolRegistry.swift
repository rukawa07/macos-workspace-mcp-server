import Foundation
import MCP

// MARK: - ToolRegistry

/// MCPツールの登録とルーティングを管理
public enum ToolRegistry {

    /// 登録済みツール一覧
    private static let registeredTools: [any MCPTool.Type] = [
        LaunchApplicationTool.self,
        QuitApplicationTool.self,
        ListApplicationsTool.self,
        ListWindowsTool.self,
        PositionWindowTool.self,
        FocusWindowTool.self,
        ListDisplaysTool.self,
    ]

    // MARK: - ListTools Handler

    /// ListToolsハンドラー
    public static func handleListTools(_ params: ListTools.Parameters) -> ListTools.Result {
        let definitions = registeredTools.map { $0.definition }
        return .init(tools: definitions, nextCursor: nil)
    }

    // MARK: - CallTool Handler

    /// CallToolハンドラー
    public static func handleCallTool(_ params: CallTool.Parameters) async -> CallTool.Result {
        let service = DefaultApplicationService()
        let arguments = params.arguments ?? [:]

        switch params.name {
        case LaunchApplicationTool.name:
            let tool = LaunchApplicationTool(service: service)
            return await tool.execute(arguments: arguments)

        case QuitApplicationTool.name:
            let tool = QuitApplicationTool(service: service)
            return await tool.execute(arguments: arguments)

        case ListApplicationsTool.name:
            let tool = ListApplicationsTool(service: service)
            return await tool.execute(arguments: arguments)

        case ListWindowsTool.name:
            let windowService = DefaultWindowService()
            let tool = ListWindowsTool(service: windowService)
            return await tool.execute(arguments: arguments)

        case PositionWindowTool.name:
            let windowService = DefaultWindowService()
            let tool = PositionWindowTool(service: windowService)
            return await tool.execute(arguments: arguments)

        case FocusWindowTool.name:
            let windowService = DefaultWindowService()
            let tool = FocusWindowTool(windowService: windowService)
            return await tool.execute(arguments: arguments)

        case ListDisplaysTool.name:
            let displayService = DefaultDisplayService()
            let tool = ListDisplaysTool(service: displayService)
            return await tool.execute(arguments: arguments)

        default:
            return .init(
                content: [.text("Unknown tool: \(params.name)")],
                isError: true
            )
        }
    }
}
