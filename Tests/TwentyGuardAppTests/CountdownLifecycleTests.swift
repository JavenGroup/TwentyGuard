import AppKit
import XCTest
import TwentyGuardCore
@testable import TwentyGuard

final class CountdownLifecycleTests: XCTestCase {
    func testTemporaryDisableKeepsItsDeadlineAfterActualSleepWakeLifecycle() throws {
        guard let fixtureHome = ProcessInfo.processInfo.environment["TWENTYGUARD_LIFECYCLE_TEST_HOME"] else {
            throw XCTSkip("Run make test-lifecycle to initialize AppDelegate only inside an isolated profile")
        }
        guard NSHomeDirectory() == fixtureHome,
              fixtureHome.hasPrefix(FileManager.default.temporaryDirectory.path),
              UserDefaults.standard.persistentDomain(forName: "com.javengroup.twentyguard") == nil else {
            XCTFail("Refusing to initialize AppDelegate without verified home and preference isolation")
            return
        }

        let defaults = UserDefaults.standard
        let oldArguments = defaults.volatileDomain(forName: UserDefaults.argumentDomain)
        let now = Date()
        let until = now.addingTimeInterval(90)
        defaults.setVolatileDomain([
            "currentLanguage": "en", "showCountdownInStatusBar": true,
            "isCustomMode": true, "customWorkDuration": 1537, "customBreakDuration": 180,
            "nightRestrictionEnabled": false,
            "temporaryDisableStartedAt": now.addingTimeInterval(-10), "temporaryDisableUntil": until
        ], forName: UserDefaults.argumentDomain)
        defer { defaults.setVolatileDomain(oldArguments, forName: UserDefaults.argumentDomain) }

        _ = NSApplication.shared
        let delegate = AppDelegate(checkSingleInstanceOnLaunch: false)
        defer { delegate.stopCountdownForTesting() }
        delegate.applicationDidFinishLaunching(Notification(name: NSApplication.didFinishLaunchingNotification))
        XCTAssertEqual(delegate.countdownScheduleForTesting.deadline, until)
        XCTAssertNotNil(delegate.countdownScheduleForTesting.display)

        delegate.perform(NSSelectorFromString("systemWillSleep"))
        XCTAssertEqual(delegate.countdownScheduleForTesting.deadline, until)
        XCTAssertNil(delegate.countdownScheduleForTesting.display)

        delegate.perform(NSSelectorFromString("systemDidWake"))
        XCTAssertEqual(delegate.countdownScheduleForTesting.deadline, until,
                       "Wake must rebuild temporary-disable expiry after cancelling old timers")
        XCTAssertNotNil(delegate.countdownScheduleForTesting.display)
    }
}
