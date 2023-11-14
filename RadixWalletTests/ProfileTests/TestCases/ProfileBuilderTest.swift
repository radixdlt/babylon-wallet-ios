import Foundation
@testable import Radix_Wallet_Dev
import XCTest

final class ProfileBuilderTest: TestCase {
	func test_profile_builder() throws {
		let profile = ProfileBuilder()
			.bdfs()
			.account(name: "Foo")
			.account(name: "Bar")
			.build()

		XCTAssertEqual(
			profile.network?.getAccounts().map(\.displayName),
			["Foo", "Bar"]
		)
	}
}
