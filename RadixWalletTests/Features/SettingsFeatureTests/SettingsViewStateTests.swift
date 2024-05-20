import Foundation
@testable import Radix_Wallet_Dev
import Sargon
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
				version: "5"
			)
		} operation: {
			let sut = Settings.ViewState(state: .init())
			XCTAssertEqual(sut.appVersion, "App version: 4.2.0 (5)")
		}
	}
}
