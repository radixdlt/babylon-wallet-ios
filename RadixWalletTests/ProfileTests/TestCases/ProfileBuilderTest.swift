import Foundation
@testable import Radix_Wallet_Dev
import XCTest

final class ProfileBuilderTest: TestCase {
	// MOVE ME to some appropriate file.
	func test_tx_guarantee_default_preset_is_99() throws {
		let expectedPreset = try RETDecimal(value: "0.99")
		XCTAssertEqual(AppPreferences.Transaction.defaultDepositGuaranteePreset, expectedPreset)
		XCTAssertEqual(AppPreferences.Transaction().defaultDepositGuarantee, expectedPreset)
		XCTAssertEqual(AppPreferences().transaction.defaultDepositGuarantee, expectedPreset)

		// assert the initializer of Transaction still uses the passed in value...
		XCTAssertEqual(AppPreferences.Transaction(defaultDepositGuarantee: 2).defaultDepositGuarantee, 2)
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
