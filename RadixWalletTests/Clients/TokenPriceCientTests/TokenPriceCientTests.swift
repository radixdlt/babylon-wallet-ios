@testable import Radix_Wallet_Dev
import Sargon
import XCTest

final class TokenPriceCientTests: XCTestCase {
	func test_fetchPricesRequestStillCarriesOnlyTokensAndCurrency() throws {
		let resourceAddress = try ResourceAddress(validatingAddress: "resource_rdx1tknxxxxxxxxxradxrdxxxxxxxxx009923554798xxxxxxxxxradxrd")
		let request = TokenPricesClient.FetchPricesRequest(
			tokens: [resourceAddress],
			currency: .usd
		)

		let encoded = try JSONEncoder().encode(request)
		let json = try XCTUnwrap(JSONSerialization.jsonObject(with: encoded) as? [String: Any])

		XCTAssertEqual(json["currency"] as? String, FiatCurrency.usd.rawValue)
		XCTAssertEqual(json["tokens"] as? [String], [resourceAddress.address])
		XCTAssertNil(json["lsus"])
	}

	func test_tokenPriceServiceURLAddsHTTPSByDefault() {
		XCTAssertEqual(
			AddTokenPriceService.tokenPriceServiceURL(from: "prices.example.com", isDeveloperModeEnabled: false)?.absoluteString,
			"https://prices.example.com"
		)
	}

	func test_tokenPriceServiceURLAllowsHTTPInDeveloperMode() {
		XCTAssertEqual(
			AddTokenPriceService.tokenPriceServiceURL(from: "localhost:8080", isDeveloperModeEnabled: true)?.absoluteString,
			"http://localhost:8080"
		)
	}

	func test_tokenPriceServiceURLRejectsUnsupportedSchemes() {
		XCTAssertNil(AddTokenPriceService.tokenPriceServiceURL(from: "ftp://prices.example.com", isDeveloperModeEnabled: true))
	}
}
