import Foundation

public enum AppLocalization {
    public static let defaultLanguageCode = "en"
    public static let fallbackLanguageCode = "zh-Hans"
    public static let coreResourceBundleName = "TwentyGuard_TwentyGuardCore.bundle"

    public static let supportedLanguageCodes = ["zh-Hans", "en", "es", "ja", "ko"]

    private static let defaultStore = LocalizationStore(
        resourceBundleResolver: { resolveCoreResourceBundleURL() },
        tableLoader: loadLocalizationTable
    )

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
        defaultStore.localized(key, language: language)
    }

    public static func localizationKeys(language: String) -> Set<String> {
        Set(localizationTable(language: language).keys)
    }

    public static func localizationTable(language: String, resourceBundleURL: URL? = nil) -> [String: String] {
        if let resourceBundleURL {
            // Explicit resources are caller-owned fixtures/tools, not the process-wide app cache.
            return loadLocalizationTable(language: language, resourceBundleURL: resourceBundleURL)
        }
        return defaultStore.localizationTable(language: language)
    }

    static func loadLocalizationTable(language: String, resourceBundleURL: URL) -> [String: String] {
        for subdirectory in ["\(language).lproj", "\(language.lowercased()).lproj"] {
            let url = resourceBundleURL
                .appendingPathComponent(subdirectory, isDirectory: true)
                .appendingPathComponent("Localizable.strings")

            guard FileManager.default.fileExists(atPath: url.path) else {
                continue
            }

            return (NSDictionary(contentsOf: url) as? [String: String]) ?? [:]
        }

        return [:]
    }

    public static func resolveCoreResourceBundleURL(
        mainBundleURL: URL = Bundle.main.bundleURL,
        mainResourceURL: URL? = Bundle.main.resourceURL,
        additionalSearchURLs: [URL]? = nil,
        fileManager: FileManager = .default
    ) -> URL? {
        resolveCoreResourceBundleURL(
            mainBundleURL: mainBundleURL,
            mainResourceURL: mainResourceURL,
            additionalSearchURLs: { additionalSearchURLs ?? defaultAdditionalSearchURLs() },
            fileManager: fileManager
        )
    }

    static func resolveCoreResourceBundleURL(
        mainBundleURL: URL,
        mainResourceURL: URL?,
        additionalSearchURLs: () -> [URL],
        fileManager: FileManager = .default
    ) -> URL? {
        let packagedCandidates = resourceBundleCandidates(
            mainBundleURL: mainBundleURL,
            mainResourceURL: mainResourceURL
        )

        func firstExistingBundle(in candidates: [URL]) -> URL? {
            candidates.first { url in
                var isDirectory: ObjCBool = false
                return fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory) && isDirectory.boolValue
            }
        }

        if let packagedBundle = firstExistingBundle(in: packagedCandidates) {
            return packagedBundle
        }

        // Development discovery can enumerate .build; only evaluate it after packaged paths miss.
        let candidates = resourceBundleCandidates(
            mainBundleURL: mainBundleURL,
            mainResourceURL: mainResourceURL,
            additionalSearchURLs: additionalSearchURLs()
        )
        return firstExistingBundle(in: candidates)
    }

    public static func resourceBundleCandidates(
        mainBundleURL: URL,
        mainResourceURL: URL?,
        additionalSearchURLs: [URL] = []
    ) -> [URL] {
        var candidates: [URL] = []

        if let mainResourceURL {
            candidates.append(mainResourceURL.appendingPathComponent(coreResourceBundleName, isDirectory: true))
        }

        candidates.append(
            mainBundleURL
                .appendingPathComponent("Contents", isDirectory: true)
                .appendingPathComponent("Resources", isDirectory: true)
                .appendingPathComponent(coreResourceBundleName, isDirectory: true)
        )

        for searchURL in additionalSearchURLs {
            candidates.append(searchURL.appendingPathComponent(coreResourceBundleName, isDirectory: true))
            if searchURL.lastPathComponent == coreResourceBundleName {
                candidates.append(searchURL)
            }
        }

        var seen = Set<String>()
        return candidates.filter { url in
            let path = url.standardizedFileURL.path
            return seen.insert(path).inserted
        }
    }

    private static func defaultAdditionalSearchURLs() -> [URL] {
        var urls = ([Bundle.main] + Bundle.allBundles + Bundle.allFrameworks).flatMap { bundle -> [URL] in
            [bundle.bundleURL, bundle.resourceURL].compactMap { $0 }
        }

        urls.append(contentsOf: localSwiftPMBuildResourceBundleURLs())
        return urls
    }

    private static func localSwiftPMBuildResourceBundleURLs(fileManager: FileManager = .default) -> [URL] {
        var sourceURL = URL(fileURLWithPath: #filePath)
        sourceURL.deleteLastPathComponent() // TwentyGuardCore
        sourceURL.deleteLastPathComponent() // Sources
        sourceURL.deleteLastPathComponent() // repository root

        let buildURL = sourceURL.appendingPathComponent(".build", isDirectory: true)
        guard let enumerator = fileManager.enumerator(
            at: buildURL,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }

        let matches = enumerator.compactMap { item -> URL? in
            guard let url = item as? URL, url.lastPathComponent == coreResourceBundleName else {
                return nil
            }

            let values = try? url.resourceValues(forKeys: [.isDirectoryKey])
            return values?.isDirectory == true ? url : nil
        }

        return matches.sorted { lhs, rhs in
            let lhsIsDebug = lhs.path.contains("/debug/")
            let rhsIsDebug = rhs.path.contains("/debug/")
            if lhsIsDebug != rhsIsDebug {
                return lhsIsDebug
            }

            let lhsDate = (try? lhs.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
            let rhsDate = (try? rhs.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
            return lhsDate > rhsDate
        }
    }
}

// One store owns one immutable resource location; tests can create isolated stores.
final class LocalizationStore {
    private let lock = NSLock()
    private let resourceBundleResolver: () -> URL?
    private let tableLoader: (String, URL) -> [String: String]
    private var didResolveResourceBundle = false
    private var resourceBundleURL: URL?
    private var tables: [String: [String: String]] = [:]

    init(resourceBundleResolver: @escaping () -> URL?,
         tableLoader: @escaping (String, URL) -> [String: String]) {
        self.resourceBundleResolver = resourceBundleResolver
        self.tableLoader = tableLoader
    }

    func localized(_ key: String, language: String) -> String {
        for code in [language, AppLocalization.fallbackLanguageCode, AppLocalization.defaultLanguageCode] {
            if let value = localizationTable(language: code)[key] {
                return value
            }
        }
        return key
    }

    func localizationTable(language: String) -> [String: String] {
        lock.lock()
        defer { lock.unlock() }
        if let table = tables[language] {
            return table
        }
        if !didResolveResourceBundle {
            resourceBundleURL = resourceBundleResolver()
            didResolveResourceBundle = true
        }
        // Cache misses and empty tables too. Resource files are immutable during an app run.
        let table = resourceBundleURL.map { tableLoader(language, $0) } ?? [:]
        tables[language] = table
        return table
    }
}
