import Foundation

public extension AppSettingsClient {
	static let mock = Self(
		saveSettings: { _ in
			/* not implemented */
		}, loadSettings: {
			.default
		}
	)
}
