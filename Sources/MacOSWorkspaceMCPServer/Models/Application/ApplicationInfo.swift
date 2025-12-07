import Foundation

// MARK: - Application Information

/// アプリケーション情報を表現するデータモデル
public struct ApplicationInfo: Sendable, Codable {
    /// アプリケーションのbundle ID（例: com.apple.Safari）
    public let bundleId: String

    /// アプリケーション名（例: Safari）
    public let name: String

    /// プロセスID
    public let processId: Int

    /// 非表示状態（hidden）
    public let isHidden: Bool

    public init(bundleId: String, name: String, processId: Int, isHidden: Bool) {
        self.bundleId = bundleId
        self.name = name
        self.processId = processId
        self.isHidden = isHidden
    }
}
