@testable import SettingsFeature
import TestingPrelude

final class AppSettingsViewStateTests: TestCase {
	func testAppVersion() {
		withDependencies {
			$0.bundleInfo = .init(
				bundleIdentifier: "",
				name: "",
				displayName: "",
				spokenName: "",
				shortVersion: "4.2.0",
				version: "42"
			)
		} operation: {
			let sut = AppSettings.ViewState(state: .init())
			XCTAssertEqual(sut.appVersion, "Version: 4.2.0 build #42")
		}
	}
}
