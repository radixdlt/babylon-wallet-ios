import FeaturePrelude
import XCTest

final class StringExtraTests: XCTestCase {
	func test_whenAddressIsShorterThanThreshold_thenLeaveAdressAsIs() {
		let address = "account_t"
		XCTAssert(address.count == 9)
		XCTAssertEqual(address.formatted(.default), address)
	}

	func test_whenAddressIsExactLengthAsThreshold_thenLeaveAddressAsIs() {
		let address = "account_td"
		XCTAssert(address.count == 10)
		XCTAssertEqual(address.formatted(.default), address)
	}

	func test_whenAddressIsLongerThanTreshhold_thenReformatAddress() {
		let address1 = "account_tdx"
		let expectedFormat1 = "acco...nt_tdx"
		XCTAssert(address1.count == 11)
		XCTAssertEqual(address1.formatted(.default), expectedFormat1)

		let address2 = "account_tdx_a_1qwv0unmwmxschqj8sntg6n9eejkrr6yr6fa4ekxazdzqhm6wy5"
		let expectedFormat2 = "acco...hm6wy5"
		XCTAssert(address2.count == 65)
		XCTAssertEqual(address2.formatted(.default), expectedFormat2)
	}

	func test_givenNonFungibleGlobalIDAsInput_whenNonFungibleLocalIDIsSelectedAsFormat_thenReformatAddress() {
		let localID = "ticket_19206"
		let resourceAddress = "resource_1qlq38wvrvh5m4kaz6etaac4389qtuycnp89atc8acdfi"
		let globalID = resourceAddress + ":" + localID
		XCTAssertEqual(globalID.formatted(.nonFungibleLocalId), localID)
	}
}
