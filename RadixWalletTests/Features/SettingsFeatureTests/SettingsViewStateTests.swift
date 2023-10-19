import Foundation
@testable import Radix_Wallet_Dev
import XCTest

final class SettingsViewStateTests: TestCase {
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
			let sut = Settings.ViewState(state: .init())
			XCTAssertEqual(sut.appVersion, "Version: 4.2.0 build #42")
		}
	}
}
