import XCTest
@testable import TwentyGuardCore

final class AppLocalizationTests: XCTestCase {
    func testAllSupportedLanguagesHaveSameLocalizationKeys() {
        let baseKeys = AppLocalization.localizationKeys(language: AppLocalization.defaultLanguageCode)
        XCTAssertFalse(baseKeys.isEmpty)

        for language in AppLocalization.supportedLanguageCodes {
            XCTAssertEqual(
                AppLocalization.localizationKeys(language: language),
                baseKeys,
                "\(language) Localizable.strings keys must match \(AppLocalization.defaultLanguageCode)"
            )
        }
    }

    func testAllTranslationsKeepFormatSpecifiersCompatible() {
        let baseTable = AppLocalization.localizationTable(language: AppLocalization.defaultLanguageCode)

        for language in AppLocalization.supportedLanguageCodes where language != AppLocalization.defaultLanguageCode {
            let table = AppLocalization.localizationTable(language: language)

            for key in baseTable.keys {
                XCTAssertEqual(
                    formatSpecifiers(in: table[key] ?? ""),
                    formatSpecifiers(in: baseTable[key] ?? ""),
                    "\(language) translation for \(key) must preserve printf format specifiers"
                )
            }
        }
    }

    func testLanguageDetectionUsesSupportedCodes() {
        XCTAssertEqual(AppLocalization.languageCode(for: ["zh-Hans-CN"]), "zh-Hans")
        XCTAssertEqual(AppLocalization.languageCode(for: ["es-US"]), "es")
        XCTAssertEqual(AppLocalization.languageCode(for: ["fr-FR"]), "en")
    }

    func testLocalizedLookupReturnsSelectedLanguage() {
        XCTAssertEqual(AppLocalization.localized("nightRestriction", language: "es"), "Bloqueo Nocturno")
        XCTAssertEqual(AppLocalization.localized("nightRestriction", language: "ja"), "夜間画面ロック")
        XCTAssertEqual(AppLocalization.localized("nightRestriction", language: "ko"), "야간 화면 잠금")
    }

    private func formatSpecifiers(in value: String) -> [String] {
        let pattern = "%(?:\\d+\\$)?(?:[0-9.]+)?[@d]"
        let regex = try! NSRegularExpression(pattern: pattern)
        let range = NSRange(value.startIndex..<value.endIndex, in: value)

        return regex.matches(in: value, range: range).map {
            String(value[Range($0.range, in: value)!])
        }
    }
}
