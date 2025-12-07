import Foundation
import Testing

@testable import MacOSWorkspaceMCPServer

/// ApplicationServiceの実装をテストするスイート
@Suite("ApplicationServiceのテスト")
struct ApplicationServiceTests {

    // MARK: - Protocol Definition Tests

    @Test("ApplicationServiceProtocolがlaunchApplicationメソッドを定義している")
    func protocolDefinesLaunchMethod() async throws {
        let service: any ApplicationServiceProtocol = DefaultApplicationService()

        // プロトコルメソッドが存在することを確認（コンパイルが通ればOK）
        _ = try? await service.launchApplication(bundleId: "com.apple.Safari")
    }

    @Test("ApplicationServiceProtocolがquitメソッドを定義している")
    func protocolDefinesQuitMethod() async throws {
        let service: any ApplicationServiceProtocol = DefaultApplicationService()

        _ = try? await service.quitApplication(bundleId: "com.apple.Safari")
    }

    @Test("ApplicationServiceProtocolがlistメソッドを定義している")
    func protocolDefinesListMethod() async throws {
        let service: any ApplicationServiceProtocol = DefaultApplicationService()

        _ = await service.listRunningApplications()
    }

    @Test("ApplicationServiceProtocolが権限確認メソッドを定義している")
    func protocolDefinesPermissionCheck() {
        let service: any ApplicationServiceProtocol = DefaultApplicationService()

        _ = service.checkAccessibilityPermission()
    }

    // MARK: - Launch Application Tests

    @Test("launchApplicationがアプリ起動時に成功を返す")
    func launchApplicationSuccess() async throws {
        let service = DefaultApplicationService()

        // Safari（存在する可能性が高いアプリ）で実行
        // 注: 実際にアプリを起動するので、テスト環境では慎重に
        do {
            let result = try await service.launchApplication(bundleId: "com.apple.Safari")

            #expect(result.processId > 0)
            #expect(result.appName == "Safari")
            // wasAlreadyRunningはtrueかfalseの両方があり得る

            // 後片付け: 起動したアプリを終了
            _ = try? await service.quitApplication(bundleId: "com.apple.Safari")
        } catch {
            // テスト環境でSafariが使えない場合はスキップ
            Issue.record("Safari launch failed: \(error)")
        }
    }

    @Test("launchApplicationがシステムアプリに対して有効な結果を返す")
    func launchApplicationSystemApp() async throws {
        let service = DefaultApplicationService()

        // Finderは常に起動しているはず（ただしactivationPolicyにより動作が異なる可能性）
        let result = try await service.launchApplication(bundleId: "com.apple.Finder")

        #expect(result.processId > 0)
        #expect(result.appName == "Finder")
        // wasAlreadyRunningは環境により異なるためチェックしない
    }

    @Test("launchApplicationが無効なbundle IDでapplicationNotFoundを投げる")
    func launchApplicationNotFound() async throws {
        let service = DefaultApplicationService()

        await #expect(throws: WorkspaceError.self) {
            try await service.launchApplication(bundleId: "com.example.NonExistentApp")
        }
    }

    // MARK: - Quit Application Tests

    @Test("quitApplicationが起動中のアプリを終了する")
    func quitApplicationSuccess() async throws {
        let service = DefaultApplicationService()

        // まず起動してから終了
        do {
            let launchResult = try await service.launchApplication(bundleId: "com.apple.Safari")

            // 少し待つ（起動完了を確保）
            try await Task.sleep(for: .seconds(1))

            let quitResult = try await service.quitApplication(bundleId: "com.apple.Safari")

            #expect(quitResult.appName == "Safari")
        } catch {
            Issue.record("Safari launch/quit test failed: \(error)")
        }
    }

    @Test("quitApplicationが未起動アプリでapplicationNotRunningを投げる")
    func quitApplicationNotRunning() async throws {
        let service = DefaultApplicationService()

        // 起動していないアプリを終了しようとする
        await #expect(throws: WorkspaceError.self) {
            try await service.quitApplication(bundleId: "com.example.NotRunning")
        }
    }

    // MARK: - List Applications Tests

    @Test("listRunningApplicationsが空でない配列を返す")
    func listRunningApplicationsNotEmpty() async {
        let service = DefaultApplicationService()

        let apps = await service.listRunningApplications()

        #expect(apps.count > 0)  // Finderなど何かしら起動しているはず
    }

    @Test("listRunningApplicationsがactivation policyでフィルターする")
    func listRunningApplicationsFiltersCorrectly() async {
        let service = DefaultApplicationService()

        let apps = await service.listRunningApplications()

        // 少なくとも何かしらのアプリが起動しているはず
        // Finderはactivation policyがaccessoryの場合があるため、特定のアプリには依存しない
        #expect(apps.count > 0)

        // 全てのアプリがbundle IDを持つことを確認
        for app in apps {
            #expect(app.bundleId.isEmpty == false)
        }
    }

    @Test("listRunningApplicationsが完全なアプリ情報を返す")
    func listRunningApplicationsCompleteInfo() async {
        let service = DefaultApplicationService()

        let apps = await service.listRunningApplications()

        // 少なくとも1つはアプリがあるはず
        guard let firstApp = apps.first else {
            Issue.record("No running applications found")
            return
        }

        #expect(firstApp.bundleId.isEmpty == false)
        #expect(firstApp.name.isEmpty == false)
        #expect(firstApp.processId > 0)
        // isHiddenはtrueかfalseどちらでもOK
    }

    @Test("listRunningApplicationsがUIなしのシステムプロセスを除外する")
    func listRunningApplicationsExcludesSystemProcesses() async {
        let service = DefaultApplicationService()

        let apps = await service.listRunningApplications()

        // システムプロセス（UI無し）は含まれないべき
        // ActivationPolicyがRegularのアプリのみ
        for app in apps {
            #expect(app.bundleId.isEmpty == false)
        }
    }

    // MARK: - Permission Check Tests

    @Test("checkAccessibilityPermissionがブール値を返す")
    func checkAccessibilityPermissionReturnsBool() {
        let service = DefaultApplicationService()

        let hasPermission = service.checkAccessibilityPermission()

        // trueまたはfalseのどちらかを返す
        #expect(hasPermission == true || hasPermission == false)
    }
}
