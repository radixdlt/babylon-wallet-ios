#if DEBUG
import Dependencies
import Foundation
import XCTestDynamicOverlay

extension AppSettingsClient: TestDependencyKey {
	public static let previewValue = Self.noop

	public static let testValue = Self(
		saveSettings: XCTUnimplemented("\(Self.self).saveSettings"),
		loadSettings: XCTUnimplemented("\(Self.self).loadSettings")
	)
}

public extension AppSettingsClient {
	static let noop = Self(
		saveSettings: { _ in },
		loadSettings: { .default }
	)
}
#endif
