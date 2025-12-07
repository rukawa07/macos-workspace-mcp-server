import Foundation

// MARK: - Application List Response

/// アプリケーション一覧レスポンス
public struct ApplicationListResponse: Sendable, Codable {
    public let applications: [ApplicationInfo]

    public init(applications: [ApplicationInfo]) {
        self.applications = applications
    }
}
