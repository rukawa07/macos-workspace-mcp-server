import Foundation
import MCP
import Testing

@testable import MacOSWorkspaceMCPServer

@Suite("PositionWindowTool のテスト")
struct PositionWindowToolTests {

    // MARK: - Tool Definition Tests

    @Test("PositionWindowToolのツール名がposition_windowである")
    func toolNameIsCorrect() {
        #expect(PositionWindowTool.name == "position_window")
    }

    @Test("PositionWindowToolの定義がツール名を含む")
    func definitionContainsName() {
        let definition = PositionWindowTool.definition
        #expect(definition.name == "position_window")
    }

    @Test("PositionWindowToolの定義が説明文を含む")
    func definitionContainsDescription() {
        let definition = PositionWindowTool.definition
        #expect(definition.description != nil)
        #expect(definition.description!.isEmpty == false)
    }

    @Test("PositionWindowToolの定義が必須パラメーターbundleIdを含む")
    func definitionIncludesBundleIdParameter() {
        let definition = PositionWindowTool.definition

        // inputSchemaのpropertiesにbundleIdが含まれることを確認
        guard case let .object(schema) = definition.inputSchema,
            case let .object(properties)? = schema["properties"],
            case .object(_) = properties["bundleId"]
        else {
            #expect(Bool(false), "bundleId parameter not found in schema")
            return
        }

        #expect(Bool(true))
    }

    @Test("PositionWindowToolの定義が必須パラメーターpresetを含む")
    func definitionIncludesPresetParameter() {
        let definition = PositionWindowTool.definition

        guard case let .object(schema) = definition.inputSchema,
            case let .object(properties)? = schema["properties"],
            case .object(_) = properties["preset"]
        else {
            #expect(Bool(false), "preset parameter not found in schema")
            return
        }

        #expect(Bool(true))
    }

    @Test("PositionWindowToolの定義がオプションパラメーターtitleを含む")
    func definitionIncludesTitleParameter() {
        let definition = PositionWindowTool.definition

        guard case let .object(schema) = definition.inputSchema,
            case let .object(properties)? = schema["properties"],
            case .object(_) = properties["title"]
        else {
            #expect(Bool(false), "title parameter not found in schema")
            return
        }

        #expect(Bool(true))
    }

    @Test("PositionWindowToolの定義がオプションパラメーターdisplayNameを含む")
    func definitionIncludesDisplayNameParameter() {
        let definition = PositionWindowTool.definition

        guard case let .object(schema) = definition.inputSchema,
            case let .object(properties)? = schema["properties"],
            case .object(_) = properties["displayName"]
        else {
            #expect(Bool(false), "displayName parameter not found in schema")
            return
        }

        #expect(Bool(true))
    }

    @Test("PositionWindowToolの定義がcenterプリセットを含む")
    func definitionIncludesCenterPreset() {
        let definition = PositionWindowTool.definition

        guard case let .object(schema) = definition.inputSchema,
            case let .object(properties)? = schema["properties"],
            case let .object(presetDef)? = properties["preset"],
            case let .array(enumValues)? = presetDef["enum"]
        else {
            #expect(Bool(false), "preset enum not found in schema")
            return
        }

        let hasCenterPreset = enumValues.contains { value in
            if case .string(let str) = value, str == "center" {
                return true
            }
            return false
        }

        #expect(hasCenterPreset)
    }

    @Test("PositionWindowToolがMCPToolプロトコルに準拠している")
    func conformsToMCPToolProtocol() {
        let mock = MockWindowServiceForPositionTool()
        let tool: any MCPTool = PositionWindowTool(service: mock)

        #expect(type(of: tool).name == "position_window")
    }

    // MARK: - Parameter Validation Tests

    @Test("bundleIdが未指定の場合にエラーを返す")
    func returnErrorWhenBundleIdMissing() async {
        let mock = MockWindowServiceForPositionTool()
        let tool = PositionWindowTool(service: mock)

        let result = await tool.execute(arguments: [
            "preset": Value.string("left")
        ])

        #expect(result.isError == true)
    }

    @Test("presetが未指定の場合にエラーを返す")
    func returnErrorWhenPresetMissing() async {
        let mock = MockWindowServiceForPositionTool()
        let tool = PositionWindowTool(service: mock)

        let result = await tool.execute(arguments: [
            "bundleId": Value.string("com.apple.Safari")
        ])

        #expect(result.isError == true)
    }

    @Test("不正なpreset値の場合にエラーを返す")
    func returnErrorWhenPresetInvalid() async {
        let mock = MockWindowServiceForPositionTool()
        let tool = PositionWindowTool(service: mock)

        let result = await tool.execute(arguments: [
            "bundleId": Value.string("com.apple.Safari"),
            "preset": Value.string("invalid_preset"),
        ])

        #expect(result.isError == true)
    }

    // MARK: - Success Response Tests

    @Test("正常系で配置結果をJSON形式で返す")
    func returnJsonResponseOnSuccess() async {
        let mock = MockWindowServiceForPositionTool()
        let tool = PositionWindowTool(service: mock)

        let result = await tool.execute(arguments: [
            "bundleId": Value.string("com.apple.Safari"),
            "preset": Value.string("left"),
        ])

        #expect(result.isError == false)

        // レスポンスがJSON文字列であることを確認
        guard case let .text(jsonString) = result.content.first else {
            #expect(Bool(false), "Response should be text")
            return
        }

        #expect(jsonString.contains("appliedPreset"))
        #expect(jsonString.contains("displayName"))
        #expect(jsonString.contains("window"))
    }

    @Test("タイトル指定時にサービスに正しく渡される")
    func passesArgumentsToService() async {
        let mock = MockWindowServiceForPositionTool()
        let tool = PositionWindowTool(service: mock)

        _ = await tool.execute(arguments: [
            "bundleId": Value.string("com.apple.Safari"),
            "preset": Value.string("topRight"),
            "title": Value.string("Test Window"),
            "displayName": Value.string("Built-in Display"),
        ])

        #expect(mock.lastRequest?.bundleId == "com.apple.Safari")
        #expect(mock.lastRequest?.title == "Test Window")
        #expect(mock.lastRequest?.preset == .topRight)
        #expect(mock.lastRequest?.displayName == "Built-in Display")
    }

    // MARK: - Error Response Tests

    @Test("サービスエラー時にisErrorがtrueになる")
    func returnErrorOnServiceError() async {
        let mock = MockWindowServiceForPositionTool()
        mock.errorToThrow = .windowNotFound(bundleId: "test", title: nil)
        let tool = PositionWindowTool(service: mock)

        let result = await tool.execute(arguments: [
            "bundleId": Value.string("test"),
            "preset": Value.string("left"),
        ])

        #expect(result.isError == true)
    }

    @Test("権限エラー時に適切なメッセージを返す")
    func returnPermissionDeniedMessage() async {
        let mock = MockWindowServiceForPositionTool()
        mock.errorToThrow = .permissionDenied
        let tool = PositionWindowTool(service: mock)

        let result = await tool.execute(arguments: [
            "bundleId": Value.string("test"),
            "preset": Value.string("left"),
        ])

        #expect(result.isError == true)

        guard case let .text(message) = result.content.first else {
            #expect(Bool(false), "Response should be text")
            return
        }

        #expect(message.contains("アクセシビリティ") || message.contains("Accessibility"))
    }

    // MARK: - All Presets Tests

    @Test("全14種類のプリセットが正常に処理される", arguments: WindowPreset.allCases)
    func allPresetsWork(preset: WindowPreset) async {
        let mock = MockWindowServiceForPositionTool()
        let tool = PositionWindowTool(service: mock)

        let result = await tool.execute(arguments: [
            "bundleId": Value.string("com.apple.Safari"),
            "preset": Value.string(preset.rawValue),
        ])

        #expect(result.isError == false)
        #expect(mock.lastRequest?.preset == preset)
    }
}

// MARK: - Mock Service for Position Tool Tests

final class MockWindowServiceForPositionTool: WindowServiceProtocol, @unchecked Sendable {
    var lastRequest: (bundleId: String, title: String?, preset: WindowPreset, displayName: String?)?
    var errorToThrow: WorkspaceError?

    func listWindows(bundleId: String?) async throws -> [WindowInfo] {
        return []
    }

    func checkAccessibilityPermission() -> Bool {
        return errorToThrow != .permissionDenied
    }

    func positionWindow(
        bundleId: String,
        title: String?,
        preset: WindowPreset,
        displayName: String?
    ) async throws -> PositionResult {
        lastRequest = (bundleId, title, preset, displayName)

        if let error = errorToThrow {
            throw error
        }

        let windowInfo = WindowInfo(
            title: "Test Window",
            x: 0,
            y: 25,
            width: 960,
            height: 1055,
            isMinimized: false,
            isFullscreen: false,
            displayName: displayName ?? "Built-in Display",
            ownerBundleId: bundleId,
            ownerName: "TestApp"
        )

        return PositionResult(
            window: windowInfo,
            appliedPreset: preset,
            displayName: displayName ?? "Built-in Display"
        )
    }

    func focusWindow(
        bundleId: String,
        title: String?
    ) async throws -> FocusResult {
        if let error = errorToThrow {
            throw error
        }

        let windowInfo = WindowInfo(
            title: "Test Window",
            x: 0,
            y: 25,
            width: 960,
            height: 1055,
            isMinimized: false,
            isFullscreen: false,
            displayName: "Built-in Display",
            ownerBundleId: bundleId,
            ownerName: "TestApp"
        )

        return FocusResult(window: windowInfo)
    }
}
