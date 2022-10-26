/*
 import Foundation
 import XCTestDynamicOverlay

 public extension AppSettingsClient {
 	static let mock = Self(
 		saveSettings: { _ in
 			/* not implemented */
 		}, loadSettings: {
 			.default
 		}
 	)
 }
 */

#if DEBUG
import ComposableArchitecture
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
