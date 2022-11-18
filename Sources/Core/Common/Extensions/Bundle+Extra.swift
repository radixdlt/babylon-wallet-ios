import Foundation

public extension Bundle {
	var appBuild: String { getInfo("CFBundleVersion") }
	var appVersionLong: String { getInfo("CFBundleShortVersionString") }
}

private extension Bundle {
	func getInfo(
		_ key: String
	) -> String {
		infoDictionary?[key] as? String ?? "⚠️"
	}
}
