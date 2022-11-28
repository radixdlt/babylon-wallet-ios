import Foundation

public extension Bundle {
	var appName: String { getInfo("CFBundleName") }
	var displayName: String { getInfo("CFBundleDisplayName") }
	var language: String { getInfo("CFBundleDevelopmentRegion") }
	var identifier: String { getInfo("CFBundleIdentifier") }
	var copyright: String { getInfo("NSHumanReadableCopyright").replacingOccurrences(of: "\\\\n", with: "\n") }

	var appBuild: String { getInfo("CFBundleVersion") }
	var appVersionLong: String { getInfo("CFBundleShortVersionString") }
}

private extension Bundle {
	func getInfo(_ key: String) -> String { infoDictionary?[key] as? String ?? "⚠️" }
}
