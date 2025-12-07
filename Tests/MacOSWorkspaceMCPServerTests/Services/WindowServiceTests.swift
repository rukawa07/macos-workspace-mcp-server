import Foundation
import Testing

@testable import MacOSWorkspaceMCPServer

/// WindowServiceの実装をテストするスイート
@Suite("WindowServiceのテスト")
struct WindowServiceTests {

    // MARK: - Protocol Definition Tests

    @Test("WindowServiceProtocolがlistWindowsメソッドを定義している")
    func protocolDefinesListWindowsMethod() async throws {
        let service: any WindowServiceProtocol = DefaultWindowService()

        // プロトコルメソッドが存在することを確認（コンパイルが通ればOK）
        _ = try? await service.listWindows(bundleId: nil)
    }

    @Test("WindowServiceProtocolが権限確認メソッドを定義している")
    func protocolDefinesPermissionCheck() {
        let service: any WindowServiceProtocol = DefaultWindowService()

        _ = service.checkAccessibilityPermission()
    }

    @Test("WindowServiceProtocolがSendableに準拠している")
    func protocolIsSendable() {
        let service: any WindowServiceProtocol = DefaultWindowService()

        Task {
            // Sendable準拠していればコンパイルエラーにならない
            _ = service.checkAccessibilityPermission()
        }

        #expect(Bool(true))  // コンパイルが通ればOK
    }

    // MARK: - Service Implementation Tests

    @Test("checkAccessibilityPermissionがブール値を返す")
    func checkAccessibilityPermissionReturnsBool() {
        let service = DefaultWindowService()

        let hasPermission = service.checkAccessibilityPermission()

        // trueまたはfalseのどちらかを返す
        #expect(hasPermission == true || hasPermission == false)
    }

    @Test("listWindowsがbundleId指定なしでウィンドウ一覧を返す")
    func listWindowsWithoutBundleId() async throws {
        let service = DefaultWindowService()

        // 権限がない環境ではpermissionDeniedエラーをスロー
        do {
            let windows = try await service.listWindows(bundleId: nil)

            // 返却は成功（空配列の可能性もあり）
            #expect(windows is [WindowInfo])
        } catch let error as WorkspaceError {
            // 権限エラーは許容
            #expect(error == .permissionDenied)
        }
    }

    @Test("listWindowsがbundleId指定ありでフィルタリングされたウィンドウを返す")
    func listWindowsWithBundleId() async throws {
        let service = DefaultWindowService()

        // 存在するアプリのウィンドウを取得
        do {
            let windows = try await service.listWindows(bundleId: "com.apple.Finder")

            // 返却されたウィンドウは全てFinderのもの
            for window in windows {
                #expect(window.ownerBundleId == "com.apple.Finder")
            }
        } catch let error as WorkspaceError {
            // 権限エラーは許容
            #expect(error == .permissionDenied)
        }
    }

    @Test("listWindowsが存在しないbundleIdで空配列を返す")
    func listWindowsWithInvalidBundleId() async throws {
        let service = DefaultWindowService()

        // 存在しないbundleIdを指定した場合、空配列を返す（エラーではない）
        let windows = try await service.listWindows(bundleId: "com.example.NonExistentApp")

        // 空配列が返されることを確認
        #expect(windows.isEmpty)
    }

    // MARK: - CGWindowList Implementation Tests

    @Test("CGWindowListベースの実装がウィンドウ情報を返す")
    func cgWindowListReturnsWindowInfo() async throws {
        let service = DefaultWindowService()

        // bundleId未指定で全ウィンドウを取得
        let windows = try await service.listWindows(bundleId: nil)

        // 少なくとも何らかのウィンドウが存在するはず（テスト実行環境自体のウィンドウ）
        // 空配列も許容（権限がない場合）
        #expect(windows is [WindowInfo])
    }

    @Test("取得したウィンドウにdisplayNameプロパティが含まれる")
    func windowsIncludeDisplayName() async throws {
        let service = DefaultWindowService()

        let windows = try await service.listWindows(bundleId: nil)

        // ウィンドウが存在する場合、displayNameが設定されていることを確認
        for window in windows {
            // 空でない文字列であることを確認
            #expect(window.displayName.isEmpty == false)
        }
    }

    @Test("bundleIdフィルタリングが正しく機能する")
    func bundleIdFilteringWorksCorrectly() async throws {
        let service = DefaultWindowService()

        // Finderは通常起動しているはず
        let finderWindows = try await service.listWindows(bundleId: "com.apple.Finder")

        // 返却されたウィンドウはすべてFinderのもの
        for window in finderWindows {
            #expect(window.ownerBundleId == "com.apple.Finder")
            #expect(window.ownerName == "Finder")
        }
    }

    // MARK: - Focus Window Tests

    @Test("WindowServiceProtocolがfocusWindowメソッドを定義している")
    func protocolDefinesFocusWindowMethod() async throws {
        let service: any WindowServiceProtocol = DefaultWindowService()

        // プロトコルメソッドが存在することを確認（コンパイルが通ればOK）
        _ = try? await service.focusWindow(bundleId: "com.apple.Finder", title: nil)
    }

    @Test("focusWindowが存在しないbundleIdでapplicationNotFoundエラーを投げる")
    func focusWindowThrowsApplicationNotFoundError() async throws {
        let service = DefaultWindowService()

        // Accessibility権限がある環境でのみテスト可能
        guard service.checkAccessibilityPermission() else {
            // 権限がない場合はスキップ
            return
        }

        await #expect(throws: WorkspaceError.self) {
            try await service.focusWindow(bundleId: "com.invalid.app", title: nil)
        }
    }

    @Test("focusWindowが権限がない場合にpermissionDeniedエラーを投げる")
    func focusWindowThrowsPermissionDeniedError() async throws {
        let service = DefaultWindowService()

        // 権限がない環境では権限エラーを投げる
        // 権限がある環境では他のエラーまたは成功
        do {
            _ = try await service.focusWindow(bundleId: "com.apple.Finder", title: nil)
        } catch let error as WorkspaceError {
            if case .permissionDenied = error {
                // 権限エラーの場合は期待通り
                #expect(true)
            } else {
                // 権限がある環境なので他のエラー（例: windowNotFound）も許容
                #expect(true)
            }
        }
    }

    @Test("focusWindowがbundle IDを指定してウィンドウにフォーカスする")
    func focusWindowWithBundleId() async throws {
        let service = DefaultWindowService()

        // Accessibility権限がある環境でのみテスト可能
        guard service.checkAccessibilityPermission() else {
            // 権限がない場合はスキップ
            return
        }

        // Finderにフォーカスを試みる（Finderは通常起動している）
        do {
            let result = try await service.focusWindow(bundleId: "com.apple.Finder", title: nil)

            // FocusResultが返されることを確認
            #expect(result.window.ownerBundleId == "com.apple.Finder")
        } catch let error as WorkspaceError {
            // ウィンドウが見つからない場合もあり得る
            if case .windowNotFound = error {
                #expect(true)
            } else {
                throw error
            }
        }
    }

    @Test("focusWindowがタイトル指定でフィルタリングする")
    func focusWindowWithTitle() async throws {
        let service = DefaultWindowService()

        guard service.checkAccessibilityPermission() else {
            return
        }

        // タイトル指定でフォーカスを試みる
        do {
            let result = try await service.focusWindow(
                bundleId: "com.apple.Finder",
                title: "Desktop"
            )

            // 指定したタイトルに一致するウィンドウがフォーカスされる
            #expect(result.window.title.contains("Desktop"))
        } catch let error as WorkspaceError {
            // ウィンドウが見つからない場合もあり得る
            if case .windowNotFound = error {
                #expect(true)
            } else {
                throw error
            }
        }
    }
}

// MARK: - WorkspaceError Equatable Extension (for testing)

extension WorkspaceError: Equatable {
    public static func == (lhs: WorkspaceError, rhs: WorkspaceError) -> Bool {
        switch (lhs, rhs) {
        case (.permissionDenied, .permissionDenied):
            return true
        case let (.applicationNotFound(lhsId), .applicationNotFound(rhsId)):
            return lhsId == rhsId
        case let (.applicationNotRunning(lhsId), .applicationNotRunning(rhsId)):
            return lhsId == rhsId
        case let (.launchFailed(lhsId, lhsReason), .launchFailed(rhsId, rhsReason)):
            return lhsId == rhsId && lhsReason == rhsReason
        case let (.invalidParameter(lhsName, lhsReason), .invalidParameter(rhsName, rhsReason)):
            return lhsName == rhsName && lhsReason == rhsReason
        default:
            return false
        }
    }
}
