import Foundation
import Darwin

// Compare the timer's real lookup with explicit-bundle loading and an in-memory table.
let resourceURL = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
let iterations = Int(CommandLine.arguments[2])!
precondition(iterations > 0)
let key = "screenUsage"

func cpuSeconds() -> Double {
    var usage = rusage()
    getrusage(RUSAGE_SELF, &usage)
    return Double(usage.ru_utime.tv_sec + usage.ru_stime.tv_sec)
        + Double(usage.ru_utime.tv_usec + usage.ru_stime.tv_usec) / 1_000_000
}

func measure(_ label: String, count: Int, lookup: () -> String) {
    let cpuStart = cpuSeconds()
    let wallStart = DispatchTime.now().uptimeNanoseconds
    var checksum = 0
    for _ in 0..<count {
        checksum += lookup().utf8.count
    }
    let wallMS = Double(DispatchTime.now().uptimeNanoseconds - wallStart) / 1_000_000 / Double(count)
    let cpuMS = (cpuSeconds() - cpuStart) * 1_000 / Double(count)
    print(String(format: "%@: n=%d wall_ms_per_call=%.6f cpu_ms_per_call=%.6f checksum=%d",
                 label, count, wallMS, cpuMS, checksum))
}

measure("localized_cold", count: 1) { AppLocalization.localized(key, language: "en") }
measure("localized_warm", count: iterations) { AppLocalization.localized(key, language: "en") }
measure("explicit_bundle", count: iterations) {
    AppLocalization.localizationTable(language: "en", resourceBundleURL: resourceURL)[key] ?? key
}
let table = AppLocalization.localizationTable(language: "en", resourceBundleURL: resourceURL)
precondition(table[key] == AppLocalization.localized(key, language: "en"))
measure("preloaded_table", count: iterations) { table[key] ?? key }
