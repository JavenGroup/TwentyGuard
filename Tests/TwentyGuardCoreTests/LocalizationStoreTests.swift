import XCTest
@testable import TwentyGuardCore

final class LocalizationStoreTests: XCTestCase {
    func testRepeatedTimerLookupsResolveAndLoadOnlyOnce() {
        var resolutions = 0
        var loads = 0
        let store = LocalizationStore(resourceBundleResolver: {
            resolutions += 1
            return URL(fileURLWithPath: "/fixture.bundle")
        }, tableLoader: { language, _ in
            loads += 1
            XCTAssertEqual(language, "en")
            return ["screenUsage": "Screen Time"]
        })

        for _ in 0..<100 {
            XCTAssertEqual(store.localized("screenUsage", language: "en"), "Screen Time")
        }
        XCTAssertEqual(resolutions, 1)
        XCTAssertEqual(loads, 1)
    }

    func testMissingResourceLocationIsCached() {
        var resolutions = 0
        let store = LocalizationStore(resourceBundleResolver: {
            resolutions += 1
            return nil
        }, tableLoader: { _, _ in
            XCTFail("No table should load without a resource bundle")
            return [:]
        })
        for _ in 0..<100 {
            XCTAssertEqual(store.localized("missing", language: "es"), "missing")
        }
        XCTAssertEqual(resolutions, 1)
    }

    func testLanguageSwitchingAndMissingTablesPreserveFallbackOrder() {
        var loads: [String: Int] = [:]
        let tables = [
            "es": ["selected": "Español"],
            "zh-Hans": ["selected": "中文", "fallback": "中文回退"],
            "en": ["selected": "English", "fallback": "English fallback", "englishOnly": "English only"]
        ]
        let store = LocalizationStore(resourceBundleResolver: {
            URL(fileURLWithPath: "/fixture.bundle")
        }, tableLoader: { language, _ in
            loads[language, default: 0] += 1
            return tables[language] ?? [:]
        })

        for _ in 0..<10 {
            XCTAssertEqual(store.localized("selected", language: "es"), "Español")
            XCTAssertEqual(store.localized("selected", language: "en"), "English")
            XCTAssertEqual(store.localized("selected", language: "zh-Hans"), "中文")
            XCTAssertEqual(store.localized("fallback", language: "es"), "中文回退")
            XCTAssertEqual(store.localized("englishOnly", language: "es"), "English only")
            XCTAssertEqual(store.localized("missing", language: "unknown"), "missing")
        }
        XCTAssertEqual(loads, ["es": 1, "en": 1, "zh-Hans": 1, "unknown": 1])
    }

    func testConcurrentColdLookupsLoadOneTable() {
        var resolutions = 0
        var loads = 0
        let store = LocalizationStore(resourceBundleResolver: {
            resolutions += 1
            return URL(fileURLWithPath: "/fixture.bundle")
        }, tableLoader: { _, _ in
            loads += 1
            return ["screenUsage": "Screen Time"]
        })

        DispatchQueue.concurrentPerform(iterations: 1_000) { _ in
            XCTAssertEqual(store.localized("screenUsage", language: "en"), "Screen Time")
        }
        XCTAssertEqual(resolutions, 1)
        XCTAssertEqual(loads, 1)
    }

    func testPackagedBundleDoesNotEvaluateDevelopmentSearch() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let resources = root.appendingPathComponent("TwentyGuard.app/Contents/Resources")
        let bundle = resources.appendingPathComponent(AppLocalization.coreResourceBundleName)
        try FileManager.default.createDirectory(at: bundle, withIntermediateDirectories: true)
        var searches = 0
        let result = AppLocalization.resolveCoreResourceBundleURL(
            mainBundleURL: root.appendingPathComponent("TwentyGuard.app"),
            mainResourceURL: resources,
            additionalSearchURLs: {
                searches += 1
                return []
            }
        )
        XCTAssertEqual(result?.path, bundle.path)
        XCTAssertEqual(searches, 0)
    }

    func testDevelopmentSearchStillFindsSwiftPMBundle() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let build = root.appendingPathComponent(".build/arm64-apple-macosx/debug")
        let bundle = build.appendingPathComponent(AppLocalization.coreResourceBundleName)
        try FileManager.default.createDirectory(at: bundle, withIntermediateDirectories: true)
        var searches = 0
        let result = AppLocalization.resolveCoreResourceBundleURL(
            mainBundleURL: root.appendingPathComponent("test-runner"),
            mainResourceURL: nil,
            additionalSearchURLs: {
                searches += 1
                return [build]
            }
        )
        XCTAssertEqual(result?.path, bundle.path)
        XCTAssertEqual(searches, 1)
    }

    func testExplicitBundlesAndDefaultCacheStayIndependent() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let defaultValue = AppLocalization.localized("screenUsage", language: "en")
        let first = root.appendingPathComponent("first/en.lproj/Localizable.strings")
        let second = root.appendingPathComponent("second/en.lproj/Localizable.strings")
        for file in [first, second] {
            try FileManager.default.createDirectory(at: file.deletingLastPathComponent(), withIntermediateDirectories: true)
        }
        try "\"screenUsage\" = \"First\";\n".write(to: first, atomically: true, encoding: .utf8)
        try "\"screenUsage\" = \"Second\";\n".write(to: second, atomically: true, encoding: .utf8)
        let firstBundle = root.appendingPathComponent("first")
        let secondBundle = root.appendingPathComponent("second")
        XCTAssertEqual(AppLocalization.localizationTable(language: "en", resourceBundleURL: firstBundle)["screenUsage"], "First")
        XCTAssertEqual(AppLocalization.localizationTable(language: "en", resourceBundleURL: secondBundle)["screenUsage"], "Second")
        try "\"screenUsage\" = \"Updated\";\n".write(to: first, atomically: true, encoding: .utf8)
        XCTAssertEqual(AppLocalization.localizationTable(language: "en", resourceBundleURL: firstBundle)["screenUsage"], "Updated")
        XCTAssertEqual(AppLocalization.localized("screenUsage", language: "en"), defaultValue)
    }
}
