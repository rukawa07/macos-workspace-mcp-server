import Foundation
import MCP
import Testing

@testable import MacOSWorkspaceMCPServer

/// ToolRegistryの機能をテストするスイート
@Suite("ToolRegistryのテスト")
struct ToolRegistryTests {

    // MARK: - Tool Registration and Routing

    @Test("handleListToolsが登録済みツールを返す")
    func handleListToolsReturnsTools() {
        let params = ListTools.Parameters()
        let result = ToolRegistry.handleListTools(params)

        // 7つのツールが登録されているはず（list_displaysを含む）
        #expect(result.tools.count == 7)
        #expect(result.nextCursor == nil)
    }

    @Test("handleListToolsがlaunch_applicationツールを含む")
    func handleListToolsIncludesLaunchTool() {
        let params = ListTools.Parameters()
        let result = ToolRegistry.handleListTools(params)

        let hasLaunchTool = result.tools.contains { $0.name == "launch_application" }
        #expect(hasLaunchTool == true)
    }

    @Test("handleListToolsがquit_applicationツールを含む")
    func handleListToolsIncludesQuitTool() {
        let params = ListTools.Parameters()
        let result = ToolRegistry.handleListTools(params)

        let hasQuitTool = result.tools.contains { $0.name == "quit_application" }
        #expect(hasQuitTool == true)
    }

    @Test("handleListToolsがlist_applicationsツールを含む")
    func handleListToolsIncludesListTool() {
        let params = ListTools.Parameters()
        let result = ToolRegistry.handleListTools(params)

        let hasListTool = result.tools.contains { $0.name == "list_applications" }
        #expect(hasListTool == true)
    }

    @Test("handleListToolsがlist_windowsツールを含む")
    func handleListToolsIncludesListWindowsTool() {
        let params = ListTools.Parameters()
        let result = ToolRegistry.handleListTools(params)

        let hasListWindowsTool = result.tools.contains { $0.name == "list_windows" }
        #expect(hasListWindowsTool == true)
    }

    @Test("handleListToolsがposition_windowツールを含む")
    func handleListToolsIncludesPositionWindowTool() {
        let params = ListTools.Parameters()
        let result = ToolRegistry.handleListTools(params)

        let hasPositionWindowTool = result.tools.contains { $0.name == "position_window" }
        #expect(hasPositionWindowTool == true)
    }

    @Test("handleListToolsがfocus_windowツールを含む")
    func handleListToolsIncludesFocusWindowTool() {
        let params = ListTools.Parameters()
        let result = ToolRegistry.handleListTools(params)

        let hasFocusWindowTool = result.tools.contains { $0.name == "focus_window" }
        #expect(hasFocusWindowTool == true)
    }

    @Test("handleListToolsがlist_displaysツールを含む")
    func handleListToolsIncludesListDisplaysTool() {
        let params = ListTools.Parameters()
        let result = ToolRegistry.handleListTools(params)

        let hasListDisplaysTool = result.tools.contains { $0.name == "list_displays" }
        #expect(hasListDisplaysTool == true)
    }

    @Test("handleListToolsが説明付きのツールを返す")
    func handleListToolsHasDescriptions() {
        let params = ListTools.Parameters()
        let result = ToolRegistry.handleListTools(params)

        for tool in result.tools {
            #expect(tool.description != nil)
            #expect(tool.description?.isEmpty == false)
        }
    }

    @Test("handleCallToolがlaunch_applicationに正しくルーティングする")
    func handleCallToolRoutesLaunch() async {
        // 注: 実際のアプリ起動を避けるため、不正なbundle IDを使用してエラーを確認
        let params = CallTool.Parameters(
            name: "launch_application",
            arguments: ["bundleId": .string("com.example.InvalidApp")]
        )

        let result = await ToolRegistry.handleCallTool(params)

        // エラーレスポンスが返ることを確認（ツールは正しくルーティングされている）
        #expect(result.isError == true)
    }

    @Test("handleCallToolがquit_applicationに正しくルーティングする")
    func handleCallToolRoutesQuit() async {
        let params = CallTool.Parameters(
            name: "quit_application",
            arguments: ["bundleId": .string("com.example.NotRunning")]
        )

        let result = await ToolRegistry.handleCallTool(params)

        // エラーレスポンスが返ることを確認
        #expect(result.isError == true)
    }

    @Test("handleCallToolがlist_applicationsに正しくルーティングする")
    func handleCallToolRoutesList() async {
        let params = CallTool.Parameters(
            name: "list_applications",
            arguments: nil
        )

        let result = await ToolRegistry.handleCallTool(params)

        // 成功レスポンスが返ることを確認
        #expect(result.isError == false)
        #expect(result.content.isEmpty == false)
    }

    @Test("handleCallToolがlist_windowsに正しくルーティングする")
    func handleCallToolRoutesListWindows() async {
        // 注: Accessibility権限がない環境でもルーティング自体は動作する
        let params = CallTool.Parameters(
            name: "list_windows",
            arguments: nil
        )

        let result = await ToolRegistry.handleCallTool(params)

        // レスポンスが返ることを確認（権限次第で成功/エラーどちらもあり得る）
        #expect(result.content.isEmpty == false)
    }

    @Test("handleCallToolがlist_windowsでbundleIdパラメータを受け付ける")
    func handleCallToolRoutesListWindowsWithBundleId() async {
        let params = CallTool.Parameters(
            name: "list_windows",
            arguments: ["bundleId": .string("com.apple.Safari")]
        )

        let result = await ToolRegistry.handleCallTool(params)

        // レスポンスが返ることを確認
        #expect(result.content.isEmpty == false)
    }

    @Test("handleCallToolがposition_windowに正しくルーティングする")
    func handleCallToolRoutesPositionWindow() async {
        // 注: 存在しないアプリを指定してエラーを確認
        let params = CallTool.Parameters(
            name: "position_window",
            arguments: [
                "bundleId": .string("com.example.NonExistent"),
                "preset": .string("left"),
            ]
        )

        let result = await ToolRegistry.handleCallTool(params)

        // エラーレスポンスが返ることを確認（ツールは正しくルーティングされている）
        #expect(result.isError == true)
    }

    @Test("handleCallToolがposition_windowで必須パラメータ不足時にエラーを返す")
    func handleCallToolRoutesPositionWindowMissingParams() async {
        let params = CallTool.Parameters(
            name: "position_window",
            arguments: ["bundleId": .string("com.apple.Safari")]  // presetが不足
        )

        let result = await ToolRegistry.handleCallTool(params)

        // パラメータ不足エラーが返ることを確認
        #expect(result.isError == true)
    }

    @Test("handleCallToolがfocus_windowに正しくルーティングする")
    func handleCallToolRoutesFocusWindow() async {
        let params = CallTool.Parameters(
            name: "focus_window",
            arguments: ["bundleId": .string("com.example.NonExistent")]
        )

        let result = await ToolRegistry.handleCallTool(params)

        // レスポンスが返ることを確認（権限次第で成功/エラーどちらもあり得る）
        #expect(result.content.isEmpty == false)
    }

    @Test("handleCallToolがlist_displaysに正しくルーティングする")
    func handleCallToolRoutesListDisplays() async {
        let params = CallTool.Parameters(
            name: "list_displays",
            arguments: nil
        )

        let result = await ToolRegistry.handleCallTool(params)

        // 成功レスポンスが返ることを確認
        #expect(result.isError != true)
        #expect(result.content.isEmpty == false)
    }

    @Test("handleCallToolが未知のツールでエラーを返す")
    func handleCallToolUnknownTool() async {
        let params = CallTool.Parameters(
            name: "unknown_tool",
            arguments: nil
        )

        let result = await ToolRegistry.handleCallTool(params)

        #expect(result.isError == true)
        #expect(result.content.count == 1)

        if case .text(let message) = result.content[0] {
            #expect(message.contains("Unknown tool"))
        }
    }
}

/// MCPToolプロトコルの実装をテストするスイート
@Suite("MCPToolプロトコルのテスト")
struct MCPToolProtocolTests {

    // MARK: - Tool Protocol Definition

    @Test("LaunchApplicationToolがMCPToolプロトコルに準拠している")
    func launchToolConformsToProtocol() {
        // コンパイルが通ればプロトコル準拠している
        let tool: any MCPTool = LaunchApplicationTool(
            service: DefaultApplicationService()
        )

        #expect(type(of: tool).name == "launch_application")
    }

    @Test("QuitApplicationToolがMCPToolプロトコルに準拠している")
    func quitToolConformsToProtocol() {
        let tool: any MCPTool = QuitApplicationTool(
            service: DefaultApplicationService()
        )

        #expect(type(of: tool).name == "quit_application")
    }

    @Test("ListApplicationsToolがMCPToolプロトコルに準拠している")
    func listToolConformsToProtocol() {
        let tool: any MCPTool = ListApplicationsTool(
            service: DefaultApplicationService()
        )

        #expect(type(of: tool).name == "list_applications")
    }

    @Test("ListWindowsToolがMCPToolプロトコルに準拠している")
    func listWindowsToolConformsToProtocol() {
        let tool: any MCPTool = ListWindowsTool(
            service: DefaultWindowService()
        )

        #expect(type(of: tool).name == "list_windows")
    }

    @Test("PositionWindowToolがMCPToolプロトコルに準拠している")
    func positionWindowToolConformsToProtocol() {
        let tool: any MCPTool = PositionWindowTool(
            service: DefaultWindowService()
        )

        #expect(type(of: tool).name == "position_window")
    }

    @Test("MCPToolプロトコルが静的nameプロパティを定義している")
    func protocolDefinesName() {
        #expect(LaunchApplicationTool.name == "launch_application")
        #expect(QuitApplicationTool.name == "quit_application")
        #expect(ListApplicationsTool.name == "list_applications")
        #expect(ListWindowsTool.name == "list_windows")
        #expect(PositionWindowTool.name == "position_window")
    }

    @Test("MCPToolプロトコルが静的definitionプロパティを定義している")
    func protocolDefinesDefinition() {
        let launchDef = LaunchApplicationTool.definition
        let quitDef = QuitApplicationTool.definition
        let listDef = ListApplicationsTool.definition
        let listWindowsDef = ListWindowsTool.definition
        let positionWindowDef = PositionWindowTool.definition

        #expect(launchDef.name == "launch_application")
        #expect(quitDef.name == "quit_application")
        #expect(listDef.name == "list_applications")
        #expect(listWindowsDef.name == "list_windows")
        #expect(positionWindowDef.name == "position_window")
    }

    @Test("ツール定義が空でない説明を持っている")
    func toolDefinitionsHaveDescriptions() {
        #expect(LaunchApplicationTool.definition.description != nil)
        #expect(LaunchApplicationTool.definition.description?.isEmpty == false)

        #expect(QuitApplicationTool.definition.description != nil)
        #expect(QuitApplicationTool.definition.description?.isEmpty == false)

        #expect(ListApplicationsTool.definition.description != nil)
        #expect(ListApplicationsTool.definition.description?.isEmpty == false)

        #expect(ListWindowsTool.definition.description != nil)
        #expect(ListWindowsTool.definition.description?.isEmpty == false)

        #expect(PositionWindowTool.definition.description != nil)
        #expect(PositionWindowTool.definition.description?.isEmpty == false)
    }
}
