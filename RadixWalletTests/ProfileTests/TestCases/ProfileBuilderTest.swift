import Foundation
@testable import Radix_Wallet_Dev
import XCTest

final class ProfileBuilderTest: TestCase {
	// MOVE ME to some appropriate file.
	func test_tx_guarantee_default_preset_is_99() throws {
		try XCTAssertEqual(AppPreferences.Transaction().defaultDepositGuarantee, RETDecimal(value: "0.99"))
	}

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
