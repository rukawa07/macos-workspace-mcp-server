import Foundation
import MCP

@main
struct MacOSWorkspaceMCPServer {
    static func main() async {
        do {
            // サーバー初期化（capabilities定義）
            let server = await Server(
                name: "MacOSWorkspaceMCPServer",
                version: "0.1.0",
                capabilities: .init(
                    tools: .init(listChanged: false)
                )
            )
            // ListToolsハンドラーの登録
            .withMethodHandler(ListTools.self) { params in
                ToolRegistry.handleListTools(params)
            }
            // CallToolハンドラーの登録
            .withMethodHandler(CallTool.self) { params in
                await ToolRegistry.handleCallTool(params)
            }

            // StdioTransportで起動
            let transport = StdioTransport()
            try await server.start(transport: transport)

            // サーバー実行継続
            while true {
                try await Task.sleep(for: .seconds(1))
            }
        } catch {
            // 標準エラー出力にエラーメッセージを記録
            let errorMessage = "Error: \(error)\n"
            if let data = errorMessage.data(using: .utf8) {
                FileHandle.standardError.write(data)
            }
            exit(1)
        }
    }
}
