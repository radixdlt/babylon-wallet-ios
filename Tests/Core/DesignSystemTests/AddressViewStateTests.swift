import DesignSystem
import TestingPrelude

final class AddressViewStateTests: TestCase {
	func test__GIVEN__addressShorterThan10Characters__WHEN__addressFormatIsShort__THEN__addressIsLeftAsIs() {
		let sut = AddressView.ViewState(address: "account_t", format: .short())
		XCTAssertEqual(sut.formattedAddress, "account_t")
	}

	func test__GIVEN__addressExactly10Characters__WHEN__addressFormatIsShort__THEN__addressIsLeftAsIs() {
		let sut = AddressView.ViewState(address: "account_td", format: .short())
		XCTAssertEqual(sut.formattedAddress, "account_td")
	}

	func test__GIVEN__addressLongerThan10Characters__WHEN__addressFormatIsShort__THEN__addressIsAbbreviated() {
		let sut1 = AddressView.ViewState(address: "account_tdx", format: .short())
		XCTAssertEqual(sut1.formattedAddress, "acco...nt_tdx")

		let sut2 = AddressView.ViewState(address: "account_tdx_a_1qwv0unmwmxschqj8sntg6n9eejkrr6yr6fa4ekxazdzqhm6wy5", format: .short())
		XCTAssertEqual(sut2.formattedAddress, "acco...hm6wy5")
	}
}
