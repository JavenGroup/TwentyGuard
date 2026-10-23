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

        // Window creation can straddle unlock. Seed an unshown stale overlay while policy is
        // already normal and temporary disable remains active; cleanup must take priority.
        let screen = try XCTUnwrap(NSScreen.screens.first)
        let overlay = NightRestrictionOverlayWindow(screen: screen)
        XCTAssertFalse(overlay.isVisible)
        delegate.setUnshownNightOverlayForTesting(overlay)
        let cleanup = try XCTUnwrap(delegate.countdownScheduleForTesting.deadline)
        XCTAssertLessThanOrEqual(cleanup, Date().addingTimeInterval(0.1),
                                 "A stale night overlay needs immediate cleanup, not the next night boundary")
        let limit = Date().addingTimeInterval(0.5)
        while delegate.hasNightOverlayForTesting && Date() < limit {
            RunLoop.main.run(mode: .eventTracking, before: limit)
        }
        XCTAssertFalse(delegate.hasNightOverlayForTesting)
        XCTAssertEqual(delegate.countdownScheduleForTesting.deadline, until,
                       "Night cleanup must preserve the temporary-disable expiry")
    }
}
