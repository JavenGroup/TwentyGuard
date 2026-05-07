import Foundation

public enum AppLocalization {
    public static let defaultLanguageCode = "en"
    public static let fallbackLanguageCode = "zh-Hans"

    public static let supportedLanguageCodes = ["zh-Hans", "en", "es", "ja", "ko"]

    public static let languageDisplayNames: [(code: String, name: String)] = [
        ("zh-Hans", "简体中文"),
        ("en", "English"),
        ("es", "Español"),
        ("ja", "日本語"),
        ("ko", "한국어")
    ]

    public static func languageCode(for preferredLanguages: [String]) -> String {
        for language in preferredLanguages {
            if language.hasPrefix("zh") {
                return "zh-Hans"
            }
            if language.hasPrefix("en") {
                return "en"
            }
            if language.hasPrefix("es") {
                return "es"
            }
            if language.hasPrefix("ja") {
                return "ja"
            }
            if language.hasPrefix("ko") {
                return "ko"
            }
        }

        return defaultLanguageCode
    }

    public static func localized(_ key: String, language: String) -> String {
        if let value = localizationTable(language: language)[key] {
            return value
        }

        if let value = localizationTable(language: fallbackLanguageCode)[key] {
            return value
        }

        if let value = localizationTable(language: defaultLanguageCode)[key] {
            return value
        }

        return key
    }

    public static func localizationKeys(language: String) -> Set<String> {
        Set(localizationTable(language: language).keys)
    }

    public static func localizationTable(language: String) -> [String: String] {
        for subdirectory in ["\(language).lproj", "\(language.lowercased()).lproj"] {
            guard let url = Bundle.module.url(
                forResource: "Localizable",
                withExtension: "strings",
                subdirectory: subdirectory
            ) else {
                continue
            }

            return (NSDictionary(contentsOf: url) as? [String: String]) ?? [:]
        }

        return [:]
    }
}
