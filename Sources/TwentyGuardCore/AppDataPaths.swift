import Foundation

public struct AppDataPaths: Equatable, Sendable {
    public static let appSupportFolderName = "com.javengroup.twentyguard"
    public static let databaseFileName = "twentyguard_stats.db"
    public static let logsFolderName = "logs"
    public static let sessionStateFileName = "current_session.json"

    public let appSupportURL: URL
    public let databaseURL: URL
    public let logsDirectoryURL: URL
    public let sessionStateURL: URL

    public init(applicationSupportRoot: URL) {
        self.appSupportURL = applicationSupportRoot.appendingPathComponent(Self.appSupportFolderName)
        self.databaseURL = appSupportURL.appendingPathComponent(Self.databaseFileName)
        self.logsDirectoryURL = appSupportURL.appendingPathComponent(Self.logsFolderName)
        self.sessionStateURL = appSupportURL.appendingPathComponent(Self.sessionStateFileName)
    }

    public static func live(fileManager: FileManager = .default) -> AppDataPaths {
        let root = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return AppDataPaths(applicationSupportRoot: root)
    }
}
