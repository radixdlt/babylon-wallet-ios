import Foundation
import UserDefaultsClient

public extension AppSettingsClient {
	static let mock = Self(
		saveSettings: { _ in
			/* not implemented */
		}, loadSettings: {
			.defaults
		}
	)
}
