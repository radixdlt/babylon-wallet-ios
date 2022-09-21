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

#if DEBUG
import XCTestDynamicOverlay

public extension AppSettingsClient {
	static let unimplemented = Self(
		saveSettings: XCTUnimplemented("\(Self.self).saveSettings"),
		loadSettings: XCTUnimplemented("\(Self.self).loadSettings")
	)
}
#endif
