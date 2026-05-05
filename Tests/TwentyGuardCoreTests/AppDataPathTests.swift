import XCTest
@testable import TwentyGuardCore

final class AppDataPathTests: XCTestCase {
    func testTwentyGuardDataPathsUseNewAppIdentity() {
        let root = URL(fileURLWithPath: "/tmp/Application Support")
        let paths = AppDataPaths(applicationSupportRoot: root)

        XCTAssertEqual(paths.appSupportURL.path, "/tmp/Application Support/com.javengroup.twentyguard")
        XCTAssertEqual(paths.databaseURL.lastPathComponent, "twentyguard_stats.db")
        XCTAssertEqual(paths.logsDirectoryURL.lastPathComponent, "logs")
        XCTAssertEqual(paths.sessionStateURL.lastPathComponent, "current_session.json")
    }
}
