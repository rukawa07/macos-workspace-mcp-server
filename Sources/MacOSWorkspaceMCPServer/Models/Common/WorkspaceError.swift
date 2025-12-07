import Foundation

// MARK: - Error Types

/// ワークスペース操作で発生するエラー
public enum WorkspaceError: Error, Sendable {
    /// アプリケーションが見つからない
    case applicationNotFound(bundleId: String)

    /// アプリケーションが起動していない
    case applicationNotRunning(bundleId: String)

    /// アプリケーションの起動に失敗
    case launchFailed(bundleId: String, reason: String)

    /// Accessibility権限が付与されていない
    case permissionDenied

    /// パラメーターが不正
    case invalidParameter(name: String, reason: String)

    /// 指定されたウィンドウが見つからない
    case windowNotFound(bundleId: String, title: String?)

    /// ウィンドウが最小化されている
    case windowMinimized(bundleId: String, title: String?)

    /// ウィンドウ配置に失敗
    case positioningFailed(reason: String)

    /// 指定されたディスプレイが見つからない
    case displayNotFound(displayName: String)

    /// ウィンドウの前面表示に失敗
    case focusFailed(reason: String)

    /// ユーザー向けエラーメッセージを生成
    public var userMessage: String {
        switch self {
        case .applicationNotFound(let bundleId):
            return "アプリケーション '\(bundleId)' が見つかりません。bundle IDを確認してください。"

        case .applicationNotRunning(let bundleId):
            return "アプリケーション '\(bundleId)' は起動していません。"

        case .launchFailed(let bundleId, let reason):
            return "アプリケーション '\(bundleId)' の起動に失敗しました: \(reason)"

        case .permissionDenied:
            return """
                アクセシビリティ権限が必要です。
                以下の手順で権限を付与してください:
                1. システム設定を開く
                2. プライバシーとセキュリティ > アクセシビリティ を選択
                3. このアプリケーションを追加して有効化する
                """

        case .invalidParameter(let name, let reason):
            return "パラメーター '\(name)' が不正です: \(reason)"

        case .windowNotFound(let bundleId, let title):
            if let title = title {
                return "ウィンドウ '\(title)' が見つかりません（アプリケーション: \(bundleId)）。ウィンドウタイトルを確認してください。"
            } else {
                return "アプリケーション '\(bundleId)' のウィンドウが見つかりません。アプリケーションが起動していることを確認してください。"
            }

        case .windowMinimized(let bundleId, let title):
            if let title = title {
                return "ウィンドウ '\(title)' は最小化されています（アプリケーション: \(bundleId)）。ウィンドウを復元してから操作してください。"
            } else {
                return "アプリケーション '\(bundleId)' のウィンドウは最小化されています。ウィンドウを復元してから操作してください。"
            }

        case .positioningFailed(let reason):
            return "ウィンドウの配置に失敗しました: \(reason)"

        case .displayNotFound(let displayName):
            return "ディスプレイ '\(displayName)' が見つかりません。接続されているディスプレイ名を確認してください。"

        case .focusFailed(let reason):
            return "ウィンドウの前面表示に失敗しました: \(reason)"
        }
    }
}
